# --------
# summary: list active projects
# --------

help() {
sum="list active projects"
cmd="list"
usage="$FRAMEWORK_NAME $cmd"

cat <<EOF
$(bold ABOUT)
    $(bold "$FRAMEWORK_NAME $FRAMEWORK_VERSION")

$(bold "COMMAND"): $(blue $cmd)
    $sum

$(bold USAGE)
    $usage <project-name>

$(bold EXAMPLE)
    $(prompt "$usage")

EOF
}

parse_args() {
  [ "$1" = "help" ] && { help; return 0; }

  [ "$1" = "." -o "$1" = ".." ] && {
    error "action cannot be perfomed" "$ERROR_ILLEGAL_OP"
  }

  setup "$1"

  [ -d "$PROJECT_PATH" ] || {
    error "project $1 not found under $PROJECTS_PATH" "$ERR0R_UNKNOWN_PROJECT"
  }
}

init() {
  unset -f init

  [ -z "$1" ] && {
    ls "$PROJECTS_PATH" | cat
    return
  }

  help
  return 0

  export FRAMEWORK_MODULE_NAME="open"
}

init "$@"
