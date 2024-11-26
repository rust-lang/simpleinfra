FROM ubuntu:24.04

RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        git \
        curl \
        unzip \
        ; \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-$(arch).zip" -o "awscliv2.zip"; \
    unzip awscliv2.zip; \
    rm awscliv2.zip; \
    ./aws/install

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
