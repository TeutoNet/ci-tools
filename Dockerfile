FROM golang:alpine AS builder

RUN apk update && apk add --no-cache git build-base gcc 


RUN cd / \
 && apk --no-cache add bash \ 
 && git clone  https://github.com/viaduct-ai/kustomize-sops.git \
 && cd kustomize-sops/ \
 && make sops \
 && make kustomize \
 && make build-plugin \
 && ls -al /kustomize-sops/ksops.so 


# final stage
FROM alpine as final

LABEL maintainer="ftb@teuto.net"
LABEL tools="kubectl,kustomize,ksops,envsubst,docker,helmv3,yq,jq,kubeval"

ENV KUBEVER="v1.18.1"

RUN apk update && \
  apk  add  --no-cache \
  bash \
  ca-certificates \
  curl \
  docker \
  gettext \
  git \
  jq \
  gnupg \
  multipath-tools

ARG USER_ID=1000
ARG GROUP_ID=1000

RUN addgroup -g ${GROUP_ID} user \
   && adduser -h /home/user -s /bin/bash -G user -D -u ${USER_ID} user 

WORKDIR /home/user

COPY --from=builder /go/bin/kustomize /go/bin/sops /usr/local/bin/

ARG XDG_CONFIG_HOME="/home/user/.config/kustomize/plugin/viaduct.ai/v1/ksops/"


RUN chown -R user:user /home/user \
  && mkdir -p ${XDG_CONFIG_HOME} \
  &&  sed -e 's;/bin/ash$;/bin/bash;g' -i /etc/passwd # shell für den benutzer root auf bash umstellenm

# "Copying executable plugin to the kustomize plugin path..."
COPY --from=builder /kustomize-sops/ksops.so ${XDG_CONFIG_HOME}

# schema dateien für kubecval cachen
# siehe https://itnext.io/increasing-kubeval-linting-speeds-9607d1141c6a
# ENV wird zur laufzeit von kubeval benutzt
ENV KUBEVAL_SCHEMA_LOCATION="file:///usr/local/kubeval/schemas" 
RUN mkdir -p /usr/local/kubeval/schemas  \
  && curl https://codeload.github.com/instrumenta/kubernetes-json-schema/tar.gz/master | \
       tar -C /usr/local/kubeval/schemas --strip-components=1 -xzf - kubernetes-json-schema-master/${KUBEVER}-standalone-strict

RUN cd /usr/local/bin \
  && curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBEVER}/bin/linux/amd64/kubectl \
  && chmod +x kubectl \
  && curl -LO https://github.com/instrumenta/kubeval/releases/download/0.15.0/kubeval-linux-amd64.tar.gz \
  && tar -zxf kubeval-linux-amd64.tar.gz \
  && rm  kubeval-linux-amd64.tar.gz \
  && chmod +x kubeval \
  && curl -sSL https://get.helm.sh/helm-v3.2.0-linux-amd64.tar.gz | tar xz \
  && mv linux-amd64/helm /usr/local/bin/helmv3 \
  && rm -rf linux-amd64 \
  && curl -sL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq \
  && chmod +x /usr/local/bin/yq \
  && curl -sL https://github.com/stedolan/jq/releases/latest/download/jq-linux64 -o /usr/local/bin/jq \ 
  && chmod +x /usr/local/bin/jq
  
# der cp befehl in alpine kennt den parameter -n clobber nicht  
RUN apk add --no-cache  coreutils

RUN curl -fSL -o "/usr/local/bin/tk" "https://github.com/grafana/tanka/releases/download/v0.9.2/tk-linux-amd64" \
  && chmod a+x "/usr/local/bin/tk"
  
# HELMFILE
ENV HELMFILE_VERSION v0.114.0
RUN wget -q https://github.com/roboll/helmfile/releases/download/${HELMFILE_VERSION}/helmfile_linux_amd64 -O /usr/bin/helmfile; \
    chmod +x /usr/bin/helmfile

RUN ln -sf  /usr/local/bin/helmv3 /usr/local/bin/helm
# HELM PLUGINS werden von helmfile bnötigt
RUN helm plugin install https://github.com/aslafy-z/helm-git
RUN helm plugin install https://github.com/databus23/helm-diff
RUN helm plugin install https://github.com/futuresimple/helm-secrets
RUN helm plugin install https://github.com/chartmuseum/helm-push.git

RUN cd /usr/local/bin \
  &&   curl -L https://github.com/controlplaneio/kubesec/releases/download/v2.4.0/kubesec_linux_amd64.tar.gz | tar -xz kubesec

#ENTRYPOINT entfernt un ddurch CMD ersetzt, damit man mit docker run das binary angeben kann und nicht automatisch der entrypoint gestartet wird
CMD /bin/bash

