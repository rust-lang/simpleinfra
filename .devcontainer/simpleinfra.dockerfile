# syntax=docker/dockerfile:1

# Downloader for Terraform
ARG TERRAFORM_VERSION=1.17.1
FROM hashicorp/terraform:${TERRAFORM_VERSION} AS terraform-downloader

# Downloader for binaries distributed through Github releases and
# not available as Wolfi packages
FROM cgr.dev/chainguard/wolfi-base:latest AS github-releases-downloader
USER root
RUN apk add --no-cache ca-certificates curl

ARG TARGETARCH

# note: we don't pin release digests nor check any attestations for now.
ARG AWS_SSO_CLI_VERSION=v2.3.4
ARG AWS_SSO_CLI_DOWNLOAD_URL="https://github.com/synfinatic/aws-sso-cli/releases/download/${AWS_SSO_CLI_VERSION}/aws-sso-${AWS_SSO_CLI_VERSION#v}-linux-${TARGETARCH}"

ARG FASTLY_CLI_VERSION=v17.0.0
ARG FASTLY_CLI_DOWNLOAD_URL="https://github.com/fastly/cli/releases/download/${FASTLY_CLI_VERSION}/fastly_${FASTLY_CLI_VERSION}_linux-${TARGETARCH}.tar.gz"

# wolfi's terragrunt is enterprise-only
ARG TERRAGRUNT_VERSION=v1.2.1
ARG TERRAGRUNT_DOWNLOAD_URL="https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_${TARGETARCH}"

USER root
RUN mkdir -p /out/bin && \
    curl --fail --location --retry 2 $TERRAGRUNT_DOWNLOAD_URL --output /out/bin/terragrunt && \
    curl --fail --location --retry 2 $AWS_SSO_CLI_DOWNLOAD_URL --output /out/bin/aws-sso && \
    curl --fail --location --retry 2 $FASTLY_CLI_DOWNLOAD_URL --output /tmp/fastly.tar.gz && \
    tar -xzf /tmp/fastly.tar.gz -C /out/bin fastly

RUN chmod 0755 /out/bin/*

# Final image built from Chainguard Wolfi
# https://images.chainguard.dev/directory/image/wolfi-base/overview
FROM cgr.dev/chainguard/wolfi-base:latest
USER root

# Wolfi packages releases might be ahead of Alpine ones
# https://wolfi.pkgs.org

RUN apk add --no-cache \
        libgcc libstdc++ posix-libc-utils gcc glibc-dev \
        bash ca-certificates coreutils curl git gzip age jq \
        openssh-client procps shadow

ARG PYTHON_VERSION=3.13
ARG RUSTUP_PACKAGE_VERSION=1.29.2-r0
ARG AWS_CLI_PACKAGE_VERSION=2.39.3-r0
ARG UV_PACKAGE_VERSION=0.13.6-r1
ARG FISH_PACKAGE_VERSION=4.9.3-r4
ARG GCLOUD_PACKAGE_VERSION=591.0.0-r1

RUN apk add --no-cache \
        "rustup=${RUSTUP_PACKAGE_VERSION}" \
        "python-${PYTHON_VERSION}" "py${PYTHON_VERSION}-pip" \
        "aws-cli-2=${AWS_CLI_PACKAGE_VERSION}" \
        "uv=${UV_PACKAGE_VERSION}" "fish=${FISH_PACKAGE_VERSION}" \
        "google-cloud-sdk=${GCLOUD_PACKAGE_VERSION}"

COPY --from=terraform-downloader /bin/terraform /usr/local/bin/terraform
COPY --from=github-releases-downloader /out/bin/ /usr/local/bin/

RUN groupadd --gid 1000 dev && \
    useradd --uid 1000 --gid 1000 --create-home --shell /usr/bin/fish dev && \
    mkdir -p \
       /home/dev/workspace \
       /home/dev/.cargo \
       /home/dev/.config \
       /home/dev/.aws \
       /home/dev/.local/bin \
       /home/dev/.local/share \
       /home/dev/.local/state \
       /home/dev/.docker/sandbox/locks \
       /usr/local/share/ca-certificates && \
    ln -s /usr/bin/rustup "/usr/local/bin/cargo" && \
    ln -s /usr/bin/rustup "/usr/local/bin/rustc" && \
    chown -R dev:dev /home/dev

RUN install -d -m 0700 -o dev -g dev \
    /home/dev/.cargo \
    /home/dev/.config \
    /home/dev/.config/fish \
    /home/dev/.config/aws-sso \
    /home/dev/.local/share/fish \
    /home/dev/.aws

ENV CLOUDSDK_CORE_DISABLE_USAGE_REPORTING=true \
    AWS_PAGER="" \
    PYTHONUNBUFFERED=1 \
    HOME=/home/dev \
    SHELL=/usr/bin/fish \
    RUSTUP_HOME=/home/dev/.rustup \
    CARGO_HOME=/home/dev/.cargo \
    PATH="/home/dev/.cargo/bin:/home/dev/.local/bin:${PATH}"

USER dev

ARG RUST_TOOLCHAIN=1.92

# required for fastly compute functions, additional components not needed
# when applying changes with terragrunt
RUN rustup toolchain install "${RUST_TOOLCHAIN}" --profile minimal --target wasm32-wasip1 && \
    rustup default "${RUST_TOOLCHAIN}" && \
    mkdir -p /home/dev/.cargo/registry

WORKDIR /home/dev/workspace
ENTRYPOINT []
CMD ["/usr/bin/fish", "--login"]
