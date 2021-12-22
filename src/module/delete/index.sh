# --------
# command: delete
# summary: deletes a project, use with caution !
# --------

help(){
cat <<EOF
$(bold ABOUT)
    $(bold "$FRAMEWORK_NAME $FRAMEWORK_VERSION")

$(bold "COMMAND"): $(blue delete)
    delete a project folder from $(grey \$PROJECTS_PATH)

$(bold USAGE)
    $FRAMEWORK_NAME delete <project-name>

$(bold EXAMPLE)
    $(prompt "pj delete my-project")

EOF
}

parse_args(){
  [ -z "$1" ] && {
    help
    error "no input provided!" $ERROR_INVALID_OPTIONS
  }

  [ "$1" = "help" ] && { help; return 0; }

  [ "$1" = "." -o "$1" = ".." ] && {
    error "action cannot be perfomed" $ERROR_ILLEGAL_OP
  }

  setup "$1"

  [ -d $PROJECT_PATH ] || {
    error "project $1 not found under $PROJECTS_PATH" $ERR0R_UNKNOWN_PROJECT
  }
}

rm_project(){
  project="$PROJECT_PATH"

  warn "this action cannot be undone!"

  randint=$(($(date +%s) % 124))
  keyword="$PROJECT_NAME"; keyword="$keyword-$randint"
  answer=$(question "type in $(bold $keyword) to continue")

  if [ "$answer" = "$keyword" ]; then
    rm -rf $PROJECT_PATH
    success "removed $PROJECT_NAME"
  else
    inform "incorrect input! Aborted"
  fi
}

init(){
  export FRAMEWORK_MODULE_NAME="delete"
  parse_args $@
  rm_project
}

init "$@"
