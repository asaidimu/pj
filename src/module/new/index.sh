# --------
# summary: creates a project from a recipe
# --------

list(){
  path="$1"
  for recipe in `ls $path`; do
    sum=$(cat $path/$recipe | grep "DESCRIPTION" | sed -E "s/^.*:\s//g")
   echo "$recipe:$sum" | awk -F':' '{printf "    %-10s --   %s\n", $1, $2}'
  done
}


help(){
cat <<EOF
$(bold ABOUT)
    $(bold "$FRAMEWORK_NAME $FRAMEWORK_VERSION")

$(bold "COMMAND"): $(blue new)
    creates a project folder in $(grey \$PROJECTS_PATH)

$(bold USAGE)
    $FRAMEWORK_NAME new <recipe> <project-name> [flag]

$(bold "AVAILABE FLAGS")
    -o  --overwrite      overwrite project

$(bold EXAMPLE)
    $(prompt "pj new base my-project")

$(bold "AVAILABLE RECIPES")

  $(bold "INBUILT")
$(list "$RECIPES_PATH")

  $(bold "CUSTOM")
$(list "$CUSTOM_RECIPES_PATH")

EOF
}

parse_args(){
  plugin="$1"
  project="$2"

  [ -z "$plugin" ] && {
    help
    error "no input provided!" $ERROR_INVALID_OPTIONS
  }

  [ "$plugin" = "help" ] && { help; return 2; }

  [ -e "$CUSTOM_RECIPES_PATH/$1" ] && plugin="$CUSTOM_RECIPES_PATH/$1" || plugin="$RECIPES_PATH/$1";

  if [ -x $plugin ]; then
    export PROJECT_PLUGIN="$plugin"
  elif [ -z "${project}" ]; then
    export PROJECT_PLUGIN="$RECIPES_PATH/base"
    project="$1"
    inform "Using base recipe"
  else
    error "Recipe $1 not found!" $ERR0R_UNKNOWN_PLUGIN
    help
  fi

  [ -z "$project" ] && {
    help
    error "project name not provided!" $ERROR_UNKNOWN_PROJECT
  } || {
    setup "$project"
  }

  [ $FLAG_OVERWRITE -eq 1 ] && return 0

  [ -d $PROJECT_PATH ] && {
    error "project $project found under $PROJECTS_PATH" $ERR0R_PROJECT_EXISTS
  }

  return 0
}

init(){
  unset -f init

  parse_args $@ && . $PROJECT_PLUGIN || exit 0

}

init "$@"
