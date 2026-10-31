#!/usr/bin/env sh
set -eu

HOME=${HOME:-/data}
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
GH_CONFIG_DIR=${GH_CONFIG_DIR:-$XDG_CONFIG_HOME/gh}
MISE_DATA_DIR=${MISE_DATA_DIR:-$XDG_DATA_HOME/mise}
MISE_CONFIG_DIR=${MISE_CONFIG_DIR:-$XDG_CONFIG_HOME/mise}
PI_INSTALL_DIR=${PI_INSTALL_DIR:-/usr/local/bin}

export HOME XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME GH_CONFIG_DIR
export MISE_DATA_DIR MISE_CONFIG_DIR PI_INSTALL_DIR

mkdir -p \
  "$HOME" \
  "$HOME/.cache" \
  "$XDG_CONFIG_HOME" \
  "$XDG_DATA_HOME" \
  "$XDG_STATE_HOME" \
  "$GH_CONFIG_DIR"

mkdir -p "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"

# Apply shell, agent, and tool configuration from the persistent dotfiles repo.
# A transient GitHub or package outage must not prevent the Rex server starting.
mise bootstrap \
  --from https://github.com/btkostner/dotfiles.git \
  --from-dir "$MISE_DATA_DIR/dotfiles" \
  --config-dir .config/mise \
  --only dotfiles \
  --yes \
  --update || printf '%s\n' 'warning: dotfiles bootstrap failed; starting Rex with the existing configuration' >&2

exec rex server run \
  --listen "$XDG_STATE_HOME/rex/server.sock" \
  --extra-listen 0.0.0.0:7297 \
  --state-dir "$XDG_STATE_HOME/rex" \
  --allow-anonymous \
  --log-format text
