#!/bin/sh
# src/env.sh - framework environment
#
# Order matters: error codes -> identity -> install paths -> user config
# location -> defaults -> load user config -> derived paths.
#
# Anything a user may override in ~/.config/pj/env.sh is a plain variable set
# here with a default. Everything derived FROM those variables is computed
# AFTER the user config is loaded, so derived paths always reflect overrides.

# -- error codes --
export ERROR=1
export ERROR_INVALID_OPTIONS=2
export ERROR_PROJECT_EXISTS=3
export ERROR_PROJECT_NOT_EXISTS=4
export ERROR_UNKNOWN_PLUGIN=5
export ERROR_UNKNOWN_FLAG=6
export ERROR_ILLEGAL_OP=7
export ERROR_UNKNOWN_PROJECT=8
export ERROR_MISSING_COMMAND=9

# -- identity --
export FRAMEWORK_NAME="${FRAMEWORK_NAME:-pj}"
export FRAMEWORK_VERSION="${FRAMEWORK_VERSION:-0.0.0-dev}"

# -- install paths --
export FRAMEWORK_PATH="${FRAMEWORK_PATH:?FRAMEWORK_PATH must be set}"
export FRAMEWORK_SOURCE_PATH="$FRAMEWORK_PATH/src"
export FRAMEWORK_ROUTE="$FRAMEWORK_SOURCE_PATH/module"
export UTILITIES_PATH="$FRAMEWORK_SOURCE_PATH/utils"
export ASSET_PATH="$FRAMEWORK_PATH/assets"
export RECIPES_PATH="$FRAMEWORK_PATH/plugins/recipes"
export PROJECTS_LIST_GENERATOR="$FRAMEWORK_PATH/plugins/generator"

# -- user config location --
export FRAMEWORK_CONFIG_DIR="${FRAMEWORK_CONFIG_DIR:-$HOME/.config/$FRAMEWORK_NAME}"
export FRAMEWORK_CONFIG="$FRAMEWORK_CONFIG_DIR/env.sh"

# -- defaults (override in $FRAMEWORK_CONFIG) --
export PROJECTS_PATH="${PROJECTS_PATH:-$HOME/projects}"
export CUSTOM_PLUGINS_PATH="${CUSTOM_PLUGINS_PATH:-$FRAMEWORK_CONFIG_DIR/plugins}"
export CUSTOM_RECIPES_PATH="${CUSTOM_RECIPES_PATH:-$CUSTOM_PLUGINS_PATH/recipes}"

# -- load user config --
[ -f "$FRAMEWORK_CONFIG" ] && . "$FRAMEWORK_CONFIG"

# -- derived paths (computed after user config) --
export PROJECTS_DATA="$PROJECTS_PATH/.$FRAMEWORK_NAME"
export ARCHIVE_PATH="$PROJECTS_DATA/archives"
export FRAMEWORK_DATA="$FRAMEWORK_CONFIG_DIR/data"
export PROJECTS_LIST="$FRAMEWORK_DATA/projects"

# a user-provided generator overrides the bundled one
if [ -e "$CUSTOM_PLUGINS_PATH/generator" ]; then
  export PROJECTS_LIST_GENERATOR="$CUSTOM_PLUGINS_PATH/generator"
fi

# -- runtime --
export FRAMEWORK_TMP="/tmp/${USER:-$(id -un)}/$FRAMEWORK_NAME"
export FRAMEWORK_LOGS="$FRAMEWORK_TMP/$FRAMEWORK_NAME.log"

# -- shell options --
export LC_ALL=C
