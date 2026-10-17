#!/bin/sh
# src/env.sh - framework environment
#
# Order matters: error codes -> identity -> install paths -> user config
# location -> defaults -> load user config -> derived paths.
#
# Anything a user may override in ~/.config/pj/env.sh is declared with
# scope "override". Everything derived FROM those variables is computed
# AFTER the user config is loaded (scope "derived"), so derived paths
# always reflect overrides.
#
# Every variable is declared once with env_set, which records it in
# $FRAMEWORK_ENV_TABLE (name|kind|scope|description). "pj env" lists the
# table and "pj env check" verifies it — new variables declared with
# env_set are listed and verified automatically.

FRAMEWORK_ENV_TABLE=""
export FRAMEWORK_ENV_TABLE

# env_set NAME KIND SCOPE DESCRIPTION VALUE...
#   kind:   str | num | dir | file
#   scope:  override | derived | fixed
env_set() {
  _env_name="$1"; _env_kind="$2"; _env_scope="$3"; _env_desc="$4"
  shift 4
  export "$_env_name=$*"
  FRAMEWORK_ENV_TABLE="${FRAMEWORK_ENV_TABLE}${_env_name}|${_env_kind}|${_env_scope}|${_env_desc}
"
}

# -- error codes --
env_set ERROR                 num  fixed    "generic failure code" 1
env_set ERROR_INVALID_OPTIONS num  fixed    "invalid options or arguments" 2
env_set ERROR_PROJECT_EXISTS  num  fixed    "project already exists" 3
env_set ERROR_PROJECT_NOT_EXISTS num fixed  "project does not exist" 4
env_set ERROR_UNKNOWN_PLUGIN  num  fixed    "unknown recipe or plugin" 5
env_set ERROR_UNKNOWN_FLAG    num  fixed    "unknown flag" 6
env_set ERROR_ILLEGAL_OP      num  fixed    "illegal operation" 7
env_set ERROR_UNKNOWN_PROJECT num  fixed    "unknown project" 8
env_set ERROR_MISSING_COMMAND num  fixed    "missing required tool or file" 9

# -- identity --
env_set FRAMEWORK_NAME    str override "framework name (used for config dir)" "${FRAMEWORK_NAME:-pj}"
env_set FRAMEWORK_VERSION str fixed    "framework version" "${FRAMEWORK_VERSION:-0.0.0-dev}"

# -- install paths --
env_set FRAMEWORK_PATH          str fixed "framework install location" "${FRAMEWORK_PATH:?FRAMEWORK_PATH must be set}"
env_set FRAMEWORK_SOURCE_PATH   str derived "framework source tree" "$FRAMEWORK_PATH/src"
env_set FRAMEWORK_ROUTE         str derived "module (command) directory" "$FRAMEWORK_SOURCE_PATH/module"
env_set UTILITIES_PATH          str derived "utility scripts directory" "$FRAMEWORK_SOURCE_PATH/utils"
env_set ASSET_PATH              str derived "bundled assets directory" "$FRAMEWORK_PATH/assets"
env_set RECIPES_PATH            str derived "built-in recipes directory" "$FRAMEWORK_PATH/plugins/recipes"
env_set PROJECTS_LIST_GENERATOR file derived "generates the project list shown by pj open" "$FRAMEWORK_PATH/plugins/generator"

# -- user config location --
env_set FRAMEWORK_CONFIG_DIR str override "user configuration directory" "${FRAMEWORK_CONFIG_DIR:-$HOME/.config/$FRAMEWORK_NAME}"
env_set FRAMEWORK_CONFIG     str derived  "user configuration file" "$FRAMEWORK_CONFIG_DIR/env.sh"

# -- defaults (override in $FRAMEWORK_CONFIG) --
env_set PROJECTS_PATH         str override "where projects live" "${PROJECTS_PATH:-$HOME/projects}"
env_set CUSTOM_PLUGINS_PATH   str override "user plugins directory" "${CUSTOM_PLUGINS_PATH:-$FRAMEWORK_CONFIG_DIR/plugins}"
env_set CUSTOM_RECIPES_PATH   str override "user recipes directory" "${CUSTOM_RECIPES_PATH:-$CUSTOM_PLUGINS_PATH/recipes}"

# -- load user config --
[ -f "$FRAMEWORK_CONFIG" ] && . "$FRAMEWORK_CONFIG"

# -- derived paths (computed after user config) --
env_set PROJECTS_DATA  str derived "per-projects hidden state" "$PROJECTS_PATH/.$FRAMEWORK_NAME"
env_set ARCHIVE_PATH   dir  derived "archived projects" "$PROJECTS_DATA/archives"
env_set FRAMEWORK_DATA str derived "framework data directory" "$FRAMEWORK_CONFIG_DIR/data"
env_set PROJECTS_LIST  str derived "cached project list" "$FRAMEWORK_DATA/projects"

# a user-provided generator overrides the bundled one
if [ -e "$CUSTOM_PLUGINS_PATH/generator" ]; then
  env_set PROJECTS_LIST_GENERATOR file derived "generates the project list shown by pj open" "$CUSTOM_PLUGINS_PATH/generator"
fi

# -- runtime --
env_set FRAMEWORK_TMP  str derived "scratch directory" "/tmp/${USER:-$(id -un)}/$FRAMEWORK_NAME"
env_set FRAMEWORK_LOGS str derived "log file" "$FRAMEWORK_TMP/$FRAMEWORK_NAME.log"

# -- shell options --
env_set LC_ALL str fixed "stable sorting and character classes" "C"
