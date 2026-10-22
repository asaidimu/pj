#!/bin/sh
# @about   show help message
# @usage   pj help [command]
# @flag    -x, --extended  show extended framework info (authorship, license, paths)

_help_body() {
  if [ -n "${OPT_EXTENDED:-}" ]; then
    about_full
  else
    about_short
  fi
cat <<EOF

$(bold USAGE)
    pj help
    pj help <command>
    pj <command> help
    pj <command> <command options> [flags]

$(bold "AVAILABLE FLAGS")
    -v  --version      show command version

$(bold "AVAILABLE COMMANDS")
$(module_list)

EOF
}

_module() {
  route="$1"
  shift
  export APP_SOURCE="$route"
  export APP_MODULE=1
  . "$route"
}

main() {
  module="${1:-}"
  if [ -n "$module" ] && [ "$module" != "help" ]; then
    user_route="$CUSTOM_PLUGINS_PATH/${module}/index.sh"
    route="$FRAMEWORK_ROUTE/$module/index.sh"

    if [ -e "$user_route" ]; then
      route="$user_route"
    fi

    if [ -e "$route" ]; then
      _module "$route" help
      return 0
    fi
  fi

  # No banner here: help is a reference lookup, not a splash screen.
  # The animated banner still plays on `pj -v` and `pj update`.
  _help_body
}

init() {
  app_start "$@"
}

init "$@"
