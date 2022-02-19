FROM amazon/aws-cli:latest
LABEL maintainer="jdiala@keymind.com"

RUN yum update -y \
  && yum install -y jq \
  && yum clean all

COPY ./update-hosted-zone-by-hostname.sh .

ENTRYPOINT [ "/bin/bash", "./update-hosted-zone-by-hostname.sh"]

