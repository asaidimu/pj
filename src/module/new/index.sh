# --------
# summary: creates a project from a recipe
# --------

help(){
cat <<EOF
$(bold ABOUT)
    $(bold "$FRAMEWORK_NAME $FRAMEWORK_VERSION")

$(bold "COMMAND"): $(blue new)
    creates a project folder in $(grey \$PROJECTS_PATH)

$(bold USAGE)
    $FRAMEWORK_NAME new <recipe> <project-name>

$(bold EXAMPLE)
    $(prompt "pj new base my-project")

$(bold AVAILABLE RECIPES)

  $(bold "INBUILT RECIPES")
$(plug_list "$PLUGINS_PATH")

  $(bold "CUSTOM RECIPES")
$(plug_list "$CUSTOM_PLUGINS_PATH")

EOF
}

parse_args(){
  [ -z "$1" ] && {
    help
    error "no input provided!" $ERROR_INVALID_OPTIONS
  }

  [ "$1" = "help" ] && { help; return 0; }

  [ -e "$CUSTOM_PLUGINS_PATH/$1" ] && plugin="$CUSTOM_PLUGINS_PATH/$1" || plugin="$PLUGINS_PATH/$1";

  [ -x $plugin ] && {
    export PROJECT_PLUGIN="$plugin"
  } || {
    help
    error "plugin $1 not found!" $ERR0R_UNKNOWN_PLUGIN
  }

  [ -z "$2" ] && {
    help
    error "project name not provided!" $ERROR_UNKNOWN_PROJECT
  } || {
    project="$2"
    setup "$project"
  }

  [ $FLAG_OVERWRITE -eq 1 ] && return

  [ -d $PROJECT_PATH ] && {
    error "project $2 found under $PROJECTS_PATH" $ERR0R_PROJECT_EXISTS
  }
}

init(){
  unset -f init

  parse_args $@
  . $PROJECT_PLUGIN

  [ $DEBUG -eq 1 ] && {
    export DEBUG_MODULE_NAME="new"
  }
}

init "$@"
