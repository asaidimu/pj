#!/bin/sh
# src/bootstrap.sh - framework entry point

# -- set framework path --
export FRAMEWORK_PATH="${FRAMEWORK_PATH:?FRAMEWORK_PATH must be set}"

# zsh runs in its native mode by default; enable POSIX-style word splitting
# so unquoted "$FRAMEWORK_ARGUMENTS" expands into separate arguments.
if [ -n "${ZSH_VERSION:-}" ]; then
  setopt shwordsplit 2>/dev/null
fi

# -- set up framework env --
. "$FRAMEWORK_PATH/src/env.sh"

# -- load utilities --
. "$UTILITIES_PATH/index.sh"

# -- validate the environment --
. "$UTILITIES_PATH/env_check.sh"

# -- start --
. "$FRAMEWORK_PATH/src/index.sh"
