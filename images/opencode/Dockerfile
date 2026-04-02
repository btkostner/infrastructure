FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG OPENCODE_VERSION=latest
ARG KUBECTL_VERSION=v1.34.2

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HOME=/home/opencode \
    XDG_CONFIG_HOME=/data/.config \
    XDG_DATA_HOME=/data/.local/share \
    XDG_STATE_HOME=/data/.local/state \
    GH_CONFIG_DIR=/data/.config/gh \
    MISE_CONFIG_DIR=/usr/local/etc/mise \
    MISE_DATA_DIR=/usr/local/share/mise \
    MISE_SYSTEM_DATA_DIR=/usr/local/share/mise \
    MISE_CACHE_DIR=/var/cache/mise \
    MISE_STATE_DIR=/var/lib/mise \
    MISE_NODE_COMPILE=0 \
    PATH=/usr/local/share/mise/shims:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        bison \
        build-essential \
        ca-certificates \
        curl \
        dirmngr \
        flex \
        g++ \
        gcc \
        gh \
        git \
        gnupg \
        gpg-agent \
        icu-devtools \
        libcurl4-openssl-dev \
        libffi-dev \
        libgdbm-dev \
        libgl1-mesa-dev \
        libglu1-mesa-dev \
        libgmp-dev \
        libicu-dev \
        libncurses-dev \
        libncurses5-dev \
        libpng-dev \
        libreadline-dev \
        libssh-dev \
        libssl-dev \
        libuuid1 \
        libwxgtk-webview3.2-dev \
        libwxgtk3.2-dev \
        libxml2-utils \
        make \
        openjdk-21-jdk \
        procps \
        python3 \
        python3-pip \
        python3-venv \
        unixodbc-dev \
        unzip \
        uuid-dev \
        wget \
        xsltproc \
        xz-utils \
        zip \
        zlib1g-dev \
        zsh \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl \
    && curl -fsSL "https://dl.k8s.io/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256" -o /tmp/kubectl.sha256 \
    && echo "$(cat /tmp/kubectl.sha256)  /usr/local/bin/kubectl" | sha256sum -c - \
    && chmod 0755 /usr/local/bin/kubectl \
    && rm -f /tmp/kubectl.sha256

RUN curl -fsSL https://mise.run | env MISE_INSTALL_PATH=/usr/local/bin/mise sh \
    && chmod 0755 /usr/local/bin/mise \
    && mkdir -p "$MISE_CONFIG_DIR" "$MISE_DATA_DIR" "$MISE_CACHE_DIR" "$MISE_STATE_DIR"

COPY config.toml /usr/local/etc/mise/config.toml

RUN mkdir -p /tmp/mise-home/.gnupg \
    && chmod 0700 /tmp/mise-home/.gnupg \
    && HOME=/tmp/mise-home mise install --yes \
    && HOME=/tmp/mise-home mise reshim \
    && rm -rf /tmp/mise-home

RUN useradd --create-home --home-dir /home/opencode --shell /usr/bin/zsh --uid 1000 opencode \
    && mkdir -p /data /workspace \
    && chown -R opencode:opencode /home/opencode /data /workspace "$MISE_CACHE_DIR" "$MISE_STATE_DIR"

RUN if [ "$OPENCODE_VERSION" = "latest" ]; then \
        export HOME=/tmp/opencode-install; \
        mkdir -p "$HOME"; \
        curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path; \
    else \
        export HOME=/tmp/opencode-install; \
        mkdir -p "$HOME"; \
        curl -fsSL https://opencode.ai/install | bash -s -- --version "$OPENCODE_VERSION" --no-modify-path; \
    fi \
    && install -m 0755 /tmp/opencode-install/.opencode/bin/opencode /usr/local/bin/opencode \
    && rm -rf /tmp/opencode-install

COPY startup.sh /usr/local/bin/startup.sh

RUN chmod 0755 /usr/local/bin/startup.sh

USER opencode
WORKDIR /data

EXPOSE 4096

ENTRYPOINT ["/usr/local/bin/startup.sh"]
