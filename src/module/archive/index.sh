# --------
# summary: archives a project
# completion: projects
# --------

help() {
cat <<EOF
$(bold ABOUT)
    $(bold "$FRAMEWORK_NAME $FRAMEWORK_VERSION")

$(bold "COMMAND"): $(blue archive)
    compress a project folder and save it to $(grey "$PROJECTS_PATH/.${FRAMEWORK_NAME}")

$(bold USAGE)
    $FRAMEWORK_NAME archive <project-name>

$(bold EXAMPLE)
    $(prompt "pj archive my-project")

EOF
}

archive_project() {
  [ -d "$ARCHIVE_PATH" ] || mkdir -p "$ARCHIVE_PATH"

  archive_name="${PROJECT_NAME}_$(date +"%d%m%y%H%M%S").tar.xz"
  archive="$ARCHIVE_PATH/$archive_name"

  cd "$PROJECTS_PATH"
  if [ -d "$PROJECT_NAME" ]; then
    tar -Jcvf "$archive" "$PROJECT_NAME" 2>&1 >> /dev/null
    notify "archived project to $archive_name" "could not archive project"
  fi
}

parse_args() {
  [ -z "$1" ] && {
    help
    panic "no input provided!" "$ERROR_INVALID_OPTIONS"
  }

  [ "$1" = "." -o "$1" = ".." ] && {
    panic "action cannot be perfomed" "$ERROR_ILLEGAL_OP"
  }

  setup "$1"

  [ -d "$PROJECT_PATH" ] || {
    panic "project $1 not found under $PROJECTS_PATH" "$ERROR_UNKNOWN_PROJECT"
  }
}

init() {
  if [ "$1" = "help" ]; then
    help
    return 0
  fi
  parse_args "$@" && archive_project
}

init "$@"
