# --------
# summary: example module
# --------

help() {
cat <<EOF
$(bold ABOUT)
    $(bold "$FRAMEWORK_NAME $FRAMEWORK_VERSION")

$(bold "COMMAND"): $(blue example)
    says hello world

$(bold USAGE)
    $FRAMEWORK_NAME example

$(bold EXAMPLE)
    $(prompt "pj example")
EOF
}

parse_args() {
  [ "$1" = "help" ] && { help; return 0; }
}

init() {
  unset -f init
  parse_args "$@"
  printf "Hello, World!\n"
}

init "$@"
