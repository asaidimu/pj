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
  [ "$1" = "." -o "$1" = ".." ] && {
    panic "action cannot be perfomed" "$ERROR_ILLEGAL_OP"
  }

  setup "$1"

  [ -d "$PROJECT_PATH" ] || {
    panic "project $1 not found under $PROJECTS_PATH" "$ERROR_UNKNOWN_PROJECT"
  }
}

init() {
  unset -f init

  if [ -z "$1" ]; then
    ls "$PROJECTS_PATH" | cat
    return 0
  fi

  if [ "$1" = "help" ]; then
    help
    return 0
  fi

  parse_args "$@"
}

init "$@"
