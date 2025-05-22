# summary: show help message

_help() {
  unset -f init
cat <<EOF
$(bold "$FRAMEWORK_NAME $FRAMEWORK_VERSION")

$(bold USAGE)
    pj help
    pj help <command>
    pj <command> help
    pj <command> <command options> [flags]

$(bold "AVAILABE FLAGS")
    -v  --version      show command version

$(bold "AVAILABE COMMANDS")
$(module_list)

EOF
}

_module() {
    route="$1"
    shift
    . "$route"
}

init() {
    unset -f init
    module="$1"
    user_route="$CUSTOM_PLUGINS_PATH/${cmd}/index.sh"
    route="$FRAMEWORK_ROUTE/$module/index.sh"

    if [ -e "$user_route" ]; then
      route="$user_route"
    fi

    if [ -e "$route" ]; then
        _module "$route" "help"
    else
      banner
      _help
    fi
}

init "$@"
