FROM ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HOME=/data \
    GH_CONFIG_DIR=/data/.config/gh \
    PATH=/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        gh \
        gnupg \
        zoxide \
        zsh \
    && install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://apt.fury.io/nushell/gpg.key | gpg --dearmor --yes --output /etc/apt/keyrings/fury-nushell.gpg \
    && chmod 0644 /etc/apt/keyrings/fury-nushell.gpg \
    && printf '%s\n' 'deb [signed-by=/etc/apt/keyrings/fury-nushell.gpg] https://apt.fury.io/nushell/ /' > /etc/apt/sources.list.d/nushell.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nushell \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://pkgs.superlogical.com/rex/install.sh | sh -s -- --tarball \
    && curl -fsSL https://omp.sh/install | PI_INSTALL_DIR=/usr/local/bin sh -s -- --binary \
    && curl -fsSL https://mise.run | env MISE_INSTALL_PATH=/usr/local/bin sh \
    && curl -fsSL https://starship.rs/install.sh | sh -s -- -y

RUN useradd --create-home --home-dir /home/rex --shell /usr/bin/nu --uid 1001 rex \
    && mkdir -p /data \
    && chown -R rex:rex /home/rex /data

COPY startup.sh /usr/local/bin/startup.sh

RUN chmod 0755 /usr/local/bin/startup.sh

USER rex
WORKDIR /data

EXPOSE 7297

ENTRYPOINT ["/usr/local/bin/startup.sh"]
