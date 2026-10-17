#!/bin/sh

# Run hooks for a command: core hook first, then user hook (if they exist).
# Core hooks live next to the module; user hooks override/extend them.
_run_hook() {
  hook_cmd="$1"
  hook_name="$2"
  shift 2

  core_hook="$module_dir/$hook_name"
  user_hook="$CUSTOM_PLUGINS_PATH/$hook_cmd/$hook_name"

  if [ -f "$core_hook" ]; then
    . "$core_hook" "$@"
  fi
  if [ -f "$user_hook" ]; then
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

  warn_missing_deps "$cmd" "$route"

  (
    # pre_hook sees the original argv (command word included)
    _run_hook "$cmd" pre_hook.sh "$@"

    # post_hook replays the same argv on exit, preserving the module's
    # exit status. The shift happens inside _run_module, so this
    # subshell's positional parameters stay intact for the trap. The
    # hook runs in its own subshell so a hook that calls `exit` cannot
    # swallow the module's status.
    trap '_status=$?; ( _run_hook "$cmd" post_hook.sh "$@" ); exit "$_status"' EXIT

    _run_module() {
      # Drop the command name from the arguments before sourcing the module
      shift

      # Point the pragma app layer at the module being sourced
      export APP_SOURCE="$route"
      export APP_MODULE=1

      . "$route"
    }

    _run_module "$@"
  )
}

# -- run_command --
run_command() {
  log "START"

  # Global flags come before the command word; after it they belong to
  # the module (e.g. `pj commit -s` is the module's --staged, not the
  # global --silent). Arguments are never rebuilt, so quoting survives.
  while [ $# -gt 0 ]; do
    case "$1" in
      -s|--silent)      export FLAG_SILENT=1; shift;;
      -o|--overwrite)   export FLAG_OVERWRITE=1; shift;;
      --color)          export FLAG_COLORED_OUTPUT=1; shift;;
      --no-color)       export FLAG_COLORED_OUTPUT=0; shift;;
      -h|--help)        global_help; exit 0;;
      -v|--version)     show_version; exit 0;;
      -*)               panic "unknown flag: $1 (see: pj help)" "$ERROR_UNKNOWN_FLAG";;
      *)                break;;
    esac
  done

  _module_start "$@"
}

run_command "$@"
