FROM debian:stable-slim
LABEL maintainer="jdiala@keymind.com"

RUN apt update -y \
  && apt install -y awscli jq curl \
  && apt clean all

COPY ./update-hosted-zone-by-hostname.sh .

ENTRYPOINT [ "/bin/bash", "./update-hosted-zone-by-hostname.sh"]

