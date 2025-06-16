#!/bin/sh

# -- about --- --------------------------------------------------------------- #
ABOUT=$(cat <<EOF_ABOUT
    NAME        : $FRAMEWORK_NAME
    VERSION     : $FRAMEWORK_VERSION
    DESCRIPTION : Terminal Project Manager
    REQUIRES    : sh, tmux, fzf, tree, awk, sed, grep, curl, tar, mkdir, ls, cat, date, read, printf, echo, jq

    AUTHOR      : Lolokile Saidimu
    LICENSE     : MIT
EOF_ABOUT
)

# Helper to run hooks: run core first, then user (if both exist)
# TODO: Make this function work
_run_hook() {
  cmd="$1"
  hook_name="$2"
  shift 2

  user_hook="$CUSTOM_PLUGINS_PATH/$cmd/$hook_name"
  core_hook="$module_dir/$cmd/$hook_name"

  # Run core hook first, then user hook (if they exist and are executable)
  if [ -x "$core_hook" ]; then
    . "$core_hook" "$@"
  fi
  if [ -x "$user_hook" ]; then
    . "$user_hook" "$@"
  fi
}

# -- module_start --
_module_start() {
  cmd="$1"

  if [ -z "$cmd" ]; then
    cmd="open"
  fi

  module_dir="$FRAMEWORK_ROUTE/${cmd}"
  # User route should take precedence
  user_route="$CUSTOM_PLUGINS_PATH/${cmd}/index.sh"
  route="$module_dir/index.sh"

  # Check user_route first, then fall back to default route
  if [ -e "$user_route" ]; then
    route="$user_route"
  elif [ ! -e "$route" ]; then
    error_msg="Command $(bold_yellow "$cmd") not found! See $FRAMEWORK_NAME help for usage"
    panic "$error_msg" "$ERROR_ILLEGAL_OP"
  fi

  log "Executing module [ $cmd ]"

  # Save original arguments for hooks and trap
  export MODULE_ORIG_ARGS="$*"
  export MODULE_ORIG_ARGC=$#

  # Run pre_hook with original args
  _run_hook "$cmd" pre_hook.sh "$@"

  # Trap EXIT to run post_hook with original args
  trap '_run_hook "$cmd" post_hook.sh "$MODULE_ORIG_ARGS"' EXIT

  # Shift arguments if any exist
  shift 2>/dev/null || true

  # Source the module script with error handling
  if ! . "$route"; then
    error_msg="Failed to execute module $(bold_yellow "$cmd")"
    panic "$error_msg" "$ERROR_ILLEGAL_OP"
  fi
}

# -- remove_flags --
_remove_flags() {
  log "checking flags"

  arguments=""
  for arg in "$@"; do
    parse_flag "$arg"
    if [ "$?" -gt "0" ]; then
        arguments="$arguments $arg"
    fi
  done

  export FRAMEWORK_ARGUMENTS="${arguments}"
}

# -- run_command --
run_command() {
  log "START"
  trap 'log "EXIT"' EXIT
  _remove_flags "$@"
  # Pass FRAMEWORK_ARGUMENTS as individual arguments
  _module_start $FRAMEWORK_ARGUMENTS
}

run_command "$@"
