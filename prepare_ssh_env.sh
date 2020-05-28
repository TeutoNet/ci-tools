#!/bin/bash

if [ -z "$CI_API_TOKEN" ]; then
  echo "No CI_API_TOKEN found in ENV"
  exit 1
fi

which ssh || exit 1
eval $(ssh-agent -s)

set +x

[ -z "$SSH_KEY" ] && export SSH_KEY=$(openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096)
echo "$SSH_KEY" | tr -d '\r' | ssh-add - > /dev/null

[ -z "$SSH_PUBKEY" ] && export SSH_PUBKEY=$(echo "$SSH_KEY" | tr -d '\r' | ssh-keygen -f /dev/stdin -y)

mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "$SSH_PUBKEY" | tr -d '\r' > ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/id_rsa.pub

curl --request POST --header "PRIVATE-TOKEN: $CI_API_TOKEN" "https://gitlab.teuto.net/api/v4/projects/$CI_PROJECT_ID/variables" --form "key=SSH_PUBKEY" --form "value=$SSH_PUBKEY"
curl --request POST --header "PRIVATE-TOKEN: $CI_API_TOKEN" "https://gitlab.teuto.net/api/v4/projects/$CI_PROJECT_ID/variables" --form "key=SSH_KEY" --form "value=$SSH_KEY"
