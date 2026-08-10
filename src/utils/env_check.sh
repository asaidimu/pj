#!/bin/sh
# src/utils/env_check.sh - validate the environment after the user config loads

# -- create runtime directories --
mkdir -p "$PROJECTS_PATH" \
  "$FRAMEWORK_CONFIG_DIR" \
  "$FRAMEWORK_TMP" \
  "$FRAMEWORK_DATA" \
  "$ARCHIVE_PATH" \
  || panic "cannot create runtime directories" "$ERROR_MISSING_COMMAND"

# -- the project list generator must be available --
[ -e "$PROJECTS_LIST_GENERATOR" ] || {
  panic "project list generator not found: $PROJECTS_LIST_GENERATOR" "$ERROR_MISSING_COMMAND"
}

# -- required commands --
for cmd in sh tmux fzf tree awk sed grep curl tar mkdir ls cat date read printf echo jq; do
  check_command "$cmd" || {
    panic "$cmd is required but not installed!" "$ERROR_MISSING_COMMAND"
  }
done
