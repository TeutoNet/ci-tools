FROM golang:alpine AS builder

RUN apk update && apk add --no-cache git build-base gcc 

#run export GOPATH=/go && \
#    echo $GOPATH && \



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

COPY --from=builder /go/bin/kustomize /usr/local/bin/

COPY --from=builder /go/bin/sops  /usr/local/bin

ARG XDG_CONFIG_HOME="/home/user/.config/kustomize/plugin/viaduct.ai/v1/ksops/"
RUN mkdir -p ${XDG_CONFIG_HOME}
# "Copying executable plugin to the kustomize plugin path..."
COPY --from=builder /kustomize-sops/ksops.so ${XDG_CONFIG_HOME}

RUN chown -R user:user /home/user


RUN cd /usr/local/bin \
  && curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl \
  && chmod +x kubectl \
  && curl -LO https://github.com/instrumenta/kubeval/releases/download/0.15.0/kubeval-linux-amd64.tar.gz \
  && tar -zxf kubeval-linux-amd64.tar.gz \
  && rm  kubeval-linux-amd64.tar.gz \
  && chmod +x kubeval
  && curl -sSL https://get.helm.sh/helm-v3.2.0-linux-amd64.tar.gz | \
     tar xz && mv linux-amd64/helm /usr/local/bin/helmv3 
  && rm -rf linux-amd64
  && curl -sL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq \
  && chmod +x /usr/local/bin/yq
  && curl -sL https://github.com/stedolan/jq/releases/latest/download/jq-linux64 -o /usr/local/bin/jq 
  && chmod +x /usr/local/bin/jq

RUN printf "\nfetch kubeval kubernetes json schemas for v1.$(kubectl version --client=true --short=true | awk '{print $3}' | awk -F'.' '{print $2}').0\n"
  && mkdir -p /usr/local/kubeval/schemas  \
  && curl https://codeload.github.com/instrumenta/kubernetes-json-schema/tar.gz/master | \
       tar -C /usr/local/kubeval/schemas --strip-components=1 -xzf - \
  && kubernetes-json-schema-master/v1.$(kubectl version --client=true --short=true | awk '{print $3}' | awk -F'.' '{print $2}').0-standalone-strict

  

#loginshell für alle benutzer auf bash setzen, damit es in der CI auf jeden Fall bash benutzt wird
RUN sed -e 's;/bin/ash$;/bin/bash;g' -i /etc/passwd


CMD /bin/bash

