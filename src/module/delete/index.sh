# @about        delete a project folder, use with caution !
# @usage        pj delete <project-name>
# @completion   projects
# @arg          <project-name>  project to delete

rm_project() {
  project="$PROJECT_PATH"

  warn "this action cannot be undone!"

  randint=$(($(date +%s) % 124))
  keyword="$PROJECT_NAME"; keyword="$keyword-$randint"
  answer=$(question "type in $(bold "$keyword") to continue")

  if [ "$answer" = "$keyword" ]; then
    rm -rf "$PROJECT_PATH"
    success "removed $PROJECT_NAME"
  else
    inform "incorrect input! Aborted"
  fi
}

main() {
  [ "$1" = "." -o "$1" = ".." ] && {
    panic "action cannot be perfomed" "$ERROR_ILLEGAL_OP"
  }

  setup "$1"

  [ -d "$PROJECT_PATH" ] || {
    panic "project $1 not found under $PROJECTS_PATH" "$ERROR_UNKNOWN_PROJECT"
  }

  rm_project
}

init() {
  app_start "$@"
}

init "$@"
