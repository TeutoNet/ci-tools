#!/bin/bash

# required for output matching
# e.g. (revoked) vs. (wiederrufen)
export LC_ALL=C

if [[ -z "$GPG_PRIV_KEY" && -z "$CI_API_TOKEN" ]]; then
  echo "!! No CI_API_TOKEN found in ENV. Maybe encrypt things unrecoverable !!"
fi

# Disable strict error-handling and pipefail after key-import
set +eo pipefail

export IDENTITY="${CI_PROJECT_NAME}"

GPG_PRIV_KEY=${GPG_PRIV_KEY:-$(gpg --export-secret-keys --batch --armor $IDENTITY 2>/dev/null)}

if [ -z "$GPG_PRIV_KEY" ]; then

  gpg --batch --gen-key <(cat /usr/local/bin/genkey-batch|envsubst)

  export GPG_PRIV_KEY=$(gpg --export-secret-key --armor)
  
  if [ ! -z "$CI_API_TOKEN" ]; then
    ESCAPED_GPG_PRIV_KEY=$GPG_PRIV_KEY
    curl --request POST --header "PRIVATE-TOKEN: $CI_API_TOKEN" "https://gitlab.teuto.net/api/v4/projects/$CI_PROJECT_ID/variables" --form "key=GPG_PRIV_KEY" --form "value=$ESCAPED_GPG_PRIV_KEY"
  fi

else

  gpg --import <(echo "$GPG_PRIV_KEY" | tr -d '\r')

fi

eval $(gpg-agent --daemon -s)

# Push pubkey at all
MY_FP=$(gpg --list-secret-keys|grep "^sec" -A1|tail -1|awk '{print $1}')
gpg --keyserver keys.teuto.net --send-keys $MY_FP
export GPG_PUBKEY=$(gpg --armor --export $MY_FP)

gpg --list-secret-keys|grep "^sec" -A1|tail -1|awk '{print $1":6:"}'|gpg --import-ownertrust

export RECIPIENTS="--recipient $(gpg --list-secret-keys|grep "^sec" -A1|tail -1|awk '{print $1}')"

RCPTS=$(curl 'https://keys.teuto.net/ldapsearch/?raw=1'|grep '\@'|awk '{print $NF}'|sed 's/[<>]//g'|sort|uniq)
for rcpt in $RCPTS; do
  gpg --keyserver keys.teuto.net --batch --search-keys $rcpt | grep -v revoked | grep -o 'RSA key [^,]\+'|sed 's/RSA key //';
done | xargs -n 1 gpg --keyserver keys.teuto.net --recv-keys

echo "Running encryption"
GPG_RECIPIENTS=$(for rcpt in $RCPTS; do
    gpg --keyserver keys.teuto.net --batch --search-keys $rcpt | grep -v revoked |grep -o 'RSA key [^,]\+'|sed 's/RSA key //'|while read KEY; do
      echo -n " --recipient $KEY";
    done
done);

if [ "x${FP}x" != "xx" ]; then
  export RECIPIENTS="$RECIPIENTS $FP"
fi

if [ "x${GPG_RECIPIENTS}x" != "xx" ]; then
  export RECIPIENTS="$RECIPIENTS $GPG_RECIPIENTS"
fi

# Enable strict error-handling and pipefail after key-import
set -eo pipefail