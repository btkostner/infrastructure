#!/usr/bin/env sh
# [MISE] description="Lint shell scripts with ShellCheck"

set -eu

git ls-files -- '*.sh' | xargs -r shellcheck
