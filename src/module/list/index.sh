# --------
# summary: list active projects
# --------
# @about   list active projects
# @usage   pj list [<project-name>]
# @arg     [<project-name>]  validate a single project directory

parse_args() {
  [ "$1" = "." -o "$1" = ".." ] && {
    panic "action cannot be perfomed" "$ERROR_ILLEGAL_OP"
  }

  setup "$1"

  [ -d "$PROJECT_PATH" ] || {
    panic "project $1 not found under $PROJECTS_PATH" "$ERROR_UNKNOWN_PROJECT"
  }
}

main() {
  if [ $# -eq 0 ]; then
    ls "$PROJECTS_PATH" | cat
    return 0
  fi

  parse_args "$@"
}

init() {
  app_start "$@"
}

init "$@"
