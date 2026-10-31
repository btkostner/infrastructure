#!/usr/bin/env sh
set -eu

HOME=${HOME:-/data}
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
GH_CONFIG_DIR=${GH_CONFIG_DIR:-$XDG_CONFIG_HOME/gh}

export HOME XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME GH_CONFIG_DIR

mkdir -p \
  "$HOME" \
  "$HOME/.cache" \
  "$XDG_CONFIG_HOME" \
  "$XDG_DATA_HOME" \
  "$XDG_STATE_HOME" \
  "$GH_CONFIG_DIR"

mkdir -p "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"

exec rex server run \
  --listen "$XDG_STATE_HOME/rex/server.sock" \
  --extra-listen 0.0.0.0:7297 \
  --state-dir "$XDG_STATE_HOME/rex" \
  --allow-anonymous \
  --log-format text
