setup() {
  export PROJECT_NAME="$1"
  export PROJECT_FILE_PATH=""
  export PROJECT_PATH="$PROJECTS_PATH/$PROJECT_NAME"
  export PROJECT_DATA="$PROJECT_PATH/.$FRAMEWORK_NAME"
}

check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        panic "Command $1 not found!" "$ERROR_MISSING_COMMAND"
    fi
}

update_template() {
  [ -z "$1" ] && { error "no template specified!" "$ERROR_INVALID_OPTIONS"; }
  template_file="$1"; shift

  for opt in "$@"; do
    key=$(echo "$opt" | sed -e "s/\(\w\+\):.*/\\{\\{\1\\}\}/g")
    val=$(echo "$opt" | sed -e "s/\w\+:\(.*\)$/\1/g")
    sed -e "s|${key}|${val}|g" -i "$template_file"
  done
}

fill_template() {
  [ -z "$1" ] && { error "no template specified!" "$ERROR_INVALID_OPTIONS"; }
  template_file="$1"

  keys=$(grep "{{.*}}" "$template_file" | sed -e "s/.*{{\(.*\)}}.*/\1/g")

  for key in $keys; do
    val=$(question "$key")
    key="\\{\\{$key\\}\}"
    sed -e "s|${key}|${val}|g" -i "$template_file"
  done
}

extract_file() {
  [ -z "$1" ] && { error "no template specified!" "$ERROR_INVALID_OPTIONS"; }
  [ -z "$2" ] && { error "template output not specified!" "$ERROR_INVALID_OPTIONS"; }

  template="$ASSET_PATH/$1"
  output="$2"
  [ -e "$template" ] && cp -r "$template" "$output"
}

tabular() {
   echo "$1:$2" | awk -F':' '{printf "    %-10s --   %s\n", $1, $2}'
}

module_list() {
  for module in $(ls "$FRAMEWORK_ROUTE"); do
    module_init="$FRAMEWORK_ROUTE/$module/index.sh"
    [ -e "$module_init" ] || continue
    summary=$(grep "# summary" "$module_init" | sed -e "s/^.*:[[:space:]]//g")
    [ -z "$summary" ] && summary="see $(bold "$FRAMEWORK_NAME $module help")"
    echo "$module:$summary" | awk -F':' '{printf "    %-10s --   %s\n", $1, $2}'
  done

  for module in $(ls "$CUSTOM_PLUGINS_PATH"); do
    module_init="$CUSTOM_PLUGINS_PATH/$module/index.sh"
    [ -e "$module_init" ] || continue
    summary=$(grep "# summary" "$module_init" | sed -e "s/^.*:[[:space:]]//g")
    [ -z "$summary" ] && summary="see $(bold "$FRAMEWORK_NAME $module help")"
    echo "$module:$summary" | awk -F':' '{printf "    %-10s --   %s\n", $1, $2}'
  done

}

global_help() {
  help_module="$FRAMEWORK_ROUTE/help/index.sh"
  . "$help_module"
}

# target list generator
_generate_list() {
  # implement your own algorithm in the PROJECT_LIST_GENERATOR file
  if [ -e "$PROJECTS_LIST_GENERATOR" ]; then
    # if the PROJECTS_LIST_GENERATOR file exists, source it
    . "$PROJECTS_LIST_GENERATOR"
  else
    echo "$HOME" > "$PROJECTS_LIST"
  fi
}
