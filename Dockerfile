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
LABEL tools="kubectl,kustomize,envsubst,docker"


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

#loginshell für alle benutzer auf bash setzen, damit es in der CI auf jeden Fall bash benutzt wird
RUN sudo sed -e 's;/bin/ash$;/bin/bash;g' -i /etc/passwd


CMD /bin/bash

