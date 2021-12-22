# --------
# summary: releases a new version of the project
# --------

help(){
cat <<EOF
$(bold ABOUT)
    $(bold "$FRAMEWORK_NAME $FRAMEWORK_VERSION")

$(bold "COMMAND"): $(blue "release")
    releases a new version of the project

$(bold USAGE)
    $FRAMEWORK_NAME release <version> <project-name>

$(bold EXAMPLE)
    $(prompt "pj release patch todo-app")

$(bold VERSION)
      $(tabular "major" "release major version")
      $(tabular "minor" "release minor version")
      $(tabular "patch" "release a patch")

EOF
}


get_filter(){
  unset -f get_filter
  case $TO_VERSION in
    major)
      echo "{ major: (.major + 1), minor: 0, patch: 0}"
    return
      ;;
    minor)
      echo "{ major: .major, minor: (.minor + 1), patch: .patch}"
    return
      ;;
    patch)
      echo "{ major: .major, minor: .minor, patch: (.patch + 1)}"
    return
      ;;
  esac
}

release(){
  release_file="$PROJECT_DATA/release.json"
  release_cmd="$PROJECT_DIR/bin/release"

  [ -e $release_file -o [ "$(du $release_file | sed "s/\s+.*//g")" -eq 0 ] || {
    cat <<EOF | jq > $release_file
{
  "major": 0,
  "minor": 0,
  "patch": 1
}
EOF
  notify "created new version file for $PROJECT_NAME"
  return
  }

  tmp=$(mktemp XXX.json)
  cat $release_file | jq "$(get_filter)" >$tmp
  cat $tmp > $release_file
  rm $tmp
  [ -e "release_cmd" ] && $release_cmd
  notify "released $TO_VERSION of $PROJECT_NAME"
}

parse_args(){
  [ -z "$1" ] && {
    help
    error "no input provided!" $ERROR_INVALID_OPTIONS
  }

  case "$1" in
    major | minor | patch)
      export TO_VERSION="$1"
      ;;
    help)
      help
      return 0
      ;;
    *)
      help
      error "unknown version $1!" $ERR0R_INVALID_OPTIONS
      ;;
  esac

  [ -z "$2" ] && {
    help
    error "project name not provided!" $ERROR_INVALID_OPTIONS
  } || {
    project="$2"
    setup "$project"
  }

  [ -d $PROJECT_PATH ] || {
    error "project $2 not found under $PROJECTS_PATH" $ERR0R_PROJECT_EXISTS
  }

}

init(){
  unset -f init

  parse_args $@
  release

  [ $DEBUG -eq 1 ] && {
    export DEBUG_MODULE_NAME="new"
  }
}

init "$@"
