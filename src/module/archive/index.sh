# --------
# summary: archives a project
# completion: projects
# requires: tar
# --------
# @about   compress a project folder and save it to the archive directory
# @usage   pj archive <project-name>
# @arg     <project-name>  project to archive

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

main() {
  [ "$1" = "." -o "$1" = ".." ] && {
    panic "action cannot be perfomed" "$ERROR_ILLEGAL_OP"
  }

  setup "$1"

  [ -d "$PROJECT_PATH" ] || {
    panic "project $1 not found under $PROJECTS_PATH" "$ERROR_UNKNOWN_PROJECT"
  }

  archive_project
}

init() {
  app_start "$@"
}

init "$@"
