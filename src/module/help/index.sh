# summary: show help message

init(){
  unset -f init
cat <<EOF
$(bold ABOUT)
    $(bold "$FRAMEWORK_NAME $FRAMEWORK_VERSION")

$(bold USAGE)
    pj help
    pj <command> help
    pj <command> <command options> [flags]

$(bold AVAILABE FLAGS)
    --no-color disable color output
    --silent  disable output to stdout
    --log     show log

$(bold AVAILABE COMMANDS)
$(module_list)

EOF
}

init "$@"
