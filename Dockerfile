FROM alpine:3.10

LABEL maintainer="ftb@teuto.net"
LABEL tools="kubectl,kustomize,envsubst,docker,podman"

ARG KUBECTL_BIN_VERSION=v1.16.0
ARG KUSTOMIZE_BIN_VERSION=v3.5.4

RUN apk  add  --no-cache \
  bash \
  ca-certificates \
  curl \
  docker \
  gettext \
  git \
  jq \
  multipath-tools

# Install kubectl
RUN cd /usr/local/bin \
    && curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_BIN_VERSION}/bin/linux/amd64/kubectl \
    && chmod +x kubectl

# Install kustomize
RUN cd /usr/local/bin && \
  curl -LO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.5.4/kustomize_${KUSTOMIZE_BIN_VERSION}_linux_amd64.tar.gz && \
  tar -zxf kustomize_${KUSTOMIZE_BIN_VERSION}_linux_amd64.tar.gz && \
  rm kustomize_${KUSTOMIZE_BIN_VERSION}_linux_amd64.tar.gz && \
  chmod +x kustomize

CMD ["bash"]