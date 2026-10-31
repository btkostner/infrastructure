# Rex Image

This directory contains the Ubuntu-based Rex image used by
`cluster/developer/rex`.

The image installs Rex with its supported tarball installer and installs
oh-my-pi as `omp`. Rex runs as the unprivileged `rex` user and stores its
state under `/data`.

Build locally with:

```sh
docker build -t ghcr.io/btkostner/rex:ubuntu ./images/rex
```

Pushes to `main` automatically publish the image through GitHub Actions when
files in this directory or its workflow change.
