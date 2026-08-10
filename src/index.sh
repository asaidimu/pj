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

# Run hooks for a command: core hook first, then user hook (if they exist).
# Core hooks live next to the module; user hooks override/extend them.
_run_hook() {
  hook_cmd="$1"
  hook_name="$2"
  shift 2

  core_hook="$module_dir/$hook_name"
  user_hook="$CUSTOM_PLUGINS_PATH/$hook_cmd/$hook_name"

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
  # User route takes precedence
  user_route="$CUSTOM_PLUGINS_PATH/${cmd}/index.sh"
  route="$module_dir/index.sh"

  if [ -e "$user_route" ]; then
    route="$user_route"
  elif [ ! -e "$route" ]; then
    error_msg="Command $(bold_yellow "$cmd") not found! See $FRAMEWORK_NAME help for usage"
    panic "$error_msg" "$ERROR_ILLEGAL_OP"
  fi

  log "Executing module [ $cmd ]"

  # Save original arguments for hooks
  export MODULE_ORIG_ARGS="$*"
  export MODULE_ORIG_ARGC=$#

  # Run pre_hook with original args
  _run_hook "$cmd" pre_hook.sh "$@"

  # Run post_hook on exit, preserving the module's exit status
  trap '_status=$?; _run_hook "$cmd" post_hook.sh $MODULE_ORIG_ARGS; exit "$_status"' EXIT

  # Drop the command name from the arguments before sourcing the module
  [ "$#" -gt 0 ] && shift

  . "$route"
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
