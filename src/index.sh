#!/bin/sh

# -- about --- --------------------------------------------------------------- #
ABOUT=$(cat <<EOF_ABOUT
    NAME        : $FRAMEWORK_NAME
    VERSION     : $FRAMEWORK_VERSION
    DESCRIPTION : Terminal Project Manager
    REQUIRES    : sh, tmux, fzf, tree, awk, sed, grep, curl, tar, mkdir, ls, cat, date, read, printf, echo

    AUTHOR      : Lolokile Saidimu
    LICENSE     : MIT
EOF_ABOUT
)
# -----------------------------------------------------------------------------

# Helper to run hooks: run core first, then user (if both exist)
_run_hook() {
  local module_dir="$1"
  local hook_name="$2"
  shift 2

  local user_hook="$CUSTOM_PLUGINS_PATH/$(basename "$module_dir")/$hook_name"
  local core_hook="$module_dir/$hook_name"

  # Run core hook first, then user hook (if they exist)
  if [ -x "$core_hook" ]; then
    . "$core_hook" "$@"
  fi
  if [ -x "$user_hook" ]; then
    . "$user_hook" "$@"
  fi
}

# -- module_start() --
_module_start() {
  cmd="$1"

  if [ -z "$cmd" ]; then
      cmd="open"
  fi

  module_dir="$FRAMEWORK_ROUTE/${cmd}"
  route="$module_dir/index.sh"

  [ -e "$route" ] || {
      error_msg="Command $(bold_yellow "$cmd") not found! See $FRAMEWORK_NAME help for usage"
      panic "$error_msg" "$ERROR_ILLEGAL_OP"
  }

  log "Executing module [ $cmd ]"

  # Save original arguments for hooks and trap
  export MODULE_ORIG_ARGS="$*"
  export MODULE_ORIG_ARGC=$#

  # Run pre_hook with original args
  eval _run_hook "$module_dir" pre_hook.sh $MODULE_ORIG_ARGS

  # Trap EXIT to always run post_hook with original args
  trap 'eval _run_hook "$module_dir" post_hook.sh $MODULE_ORIG_ARGS' EXIT

  [ -z "$1" ] || shift
  . "$route"

  # No need to call post_hook here; trap will handle it
}

_remove_flags() {
  log "checking flags"

  arguments=""
  for arg in "$@"; do
    is_flag "$arg" && {
      set_flag "$arg" && continue
    }
    arguments="$arguments $arg"
  done

  export FRAMEWORK_ARGUMENTS="$arguments"
}

# -- run_command --
run_command() {
  log "START"
  trap 'log "EXIT"' EXIT
  _remove_flags "$@"
  _module_start $FRAMEWORK_ARGUMENTS
}

run_command "$@"
