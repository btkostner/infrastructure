# OpenCode Image

This directory contains the custom Ubuntu-based `opencode` image used by `cluster/apps/developer/opencode`.

## What Is Baked Into The Image

- Ubuntu 24.04 base image
- `opencode` installed into `/usr/local/bin/opencode`
- A baked-in `/usr/local/bin/startup.sh`
- Global `mise` installation rooted outside `/data`
- Global `mise` runtimes for `node`, `postgres`, `erlang`, and `elixir`
- `git`, `gh`, `gpg`, `kubectl`, and `zsh`

Exact runtime versions baked into the image:

- `erlang` `28.4.1`
- `elixir` `1.19.5-otp-28`
- `node` `25.9.0`
- `postgres` `18.3`

`/data` is reserved for the mounted project volume. The image-owned `mise` paths live under `/usr/local`, `/var/cache`, and `/var/lib`, so mounting `/data` does not replace the runtime/tool installations.

## Build

Build from this directory so the Docker context only includes the image assets:

```sh
docker build -t ghcr.io/btkostner/opencode:ubuntu ./images/opencode
```

Optional build arguments:

```sh
docker build \
  --build-arg OPENCODE_VERSION=latest \
  --build-arg KUBECTL_VERSION=v1.34.2 \
  -t ghcr.io/btkostner/opencode:ubuntu \
  ./images/opencode
```

## Publish

Pushes to `main` automatically build and publish `ghcr.io/btkostner/opencode:ubuntu` with GitHub Actions when files relevant to the image change.

For manual publishing:

```sh
docker push ghcr.io/btkostner/opencode:ubuntu
```

If the image is published somewhere else, update `cluster/apps/developer/opencode/resources/deployment.yaml` to match.

## Runtime Notes

- `HOME` is expected to be `/data` in Kubernetes.
- `startup.sh` only prepares writable directories under `/data` and starts `opencode`.
- The startup script does not install packages, rewrite shell config, or modify `/etc/passwd` at runtime.
