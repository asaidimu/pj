# --------
# summary: initialises the environment for a project
# --------

help(){
cat <<EOF
$(bold ABOUT)
    $(bold "$FRAMEWORK_NAME $FRAMEWORK_VERSION")

$(bold "COMMAND"): $(blue open)
    initialises the environment for a project

$(bold USAGE)
    $FRAMEWORK_NAME open <project-name>

$(bold EXAMPLE)
    $(prompt "pj open my-project")

EOF
}

parse_args(){
  [ -z "$1" ] && {
    help
    error "no input provided!" $ERROR_INVALID_OPTIONS
  }

  [ "$1" = "help" ] && { help; return 2; }

  [ "$1" = "." -o "$1" = ".." ] && {
    error "action cannot be perfomed" $ERROR_ILLEGAL_OP
  }

  setup "$1"

  [ -d $PROJECT_PATH ] || {
    error "project $1 not found under $PROJECTS_PATH" $ERR0R_UNKNOWN_PROJECT
  }
}

open_project(){
  [ -n "$TMUX" ] && error "$(bold "access denied!")"

  env_file="$PROJECT_PATH/.$FRAMEWORK_NAME/env.sh"
  smug_file="$PROJECT_PATH/.$FRAMEWORK_NAME/project.yml"

  [ -f "$smug_file" ] || error "$(bold $PROJECT_NAME) name has no configuration."
  [ -f "$env_file" ] &&  . $env_file

  smug start -f $smug_file
}

init(){
  unset -f init
  export  FRAMEWORK_MODULE_NAME="open"

  parse_args $@ && open_project
}

init "$@"
