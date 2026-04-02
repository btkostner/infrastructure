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
  "$HOME/.config" \
  "$HOME/.local/bin" \
  "$XDG_CONFIG_HOME" \
  "$XDG_DATA_HOME" \
  "$XDG_STATE_HOME" \
  "$GH_CONFIG_DIR"

mkdir -p "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"

exec opencode serve --hostname 0.0.0.0 --port 4096
