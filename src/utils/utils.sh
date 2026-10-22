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

  # sed -i is not portable: edit a copy, then move it into place.
  _ut_tmp=$(mktemp) || return 1
  cp "$template_file" "$_ut_tmp" || { rm -f "$_ut_tmp"; return 1; }
  for opt in "$@"; do
    key=$(printf '%s' "$opt" | sed -e 's/\([[:alnum:]_][[:alnum:]_]*\):.*/{{\1}}/g')
    val=$(printf '%s' "$opt" | sed -e 's/^[[:alnum:]_][[:alnum:]_]*://' -e 's/[\\&|]/\\&/g')
    sed -e "s|${key}|${val}|g" "$_ut_tmp" > "${_ut_tmp}.n" || { rm -f "$_ut_tmp" "${_ut_tmp}.n"; return 1; }
    mv "${_ut_tmp}.n" "$_ut_tmp"
  done
  mv "$_ut_tmp" "$template_file"
}

fill_template() {
  [ -z "$1" ] && { error "no template specified!" "$ERROR_INVALID_OPTIONS"; }
  template_file="$1"

  keys=$(grep "{{.*}}" "$template_file" | sed -e "s/.*{{\(.*\)}}.*/\1/g")

  for key in $keys; do
    val=$(question "$key")
    val=$(printf '%s' "$val" | sed -e 's/[\\&|]/\\&/g')
    _ft_tmp=$(mktemp) || return 1
    sed -e "s|{{${key}}}|${val}|g" "$template_file" > "$_ft_tmp" || { rm -f "$_ft_tmp"; return 1; }
    mv "$_ft_tmp" "$template_file"
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
   printf '%s\n' "$1:$2" | awk -F':' '{printf "    %-10s --   %s\n", $1, $2}'
}

module_list() {
  for module in $(ls "$FRAMEWORK_ROUTE"); do
    module_init="$FRAMEWORK_ROUTE/$module/index.sh"
    [ -e "$module_init" ] || continue
    summary=$(sed -n 's/^# *@ *about  *//p' "$module_init" | head -1)
    [ -z "$summary" ] && summary="see $(bold "$FRAMEWORK_NAME $module help")"
    printf '    %-10s --   %s\n' "$module" "$summary"
  done

  for module in $(ls "$CUSTOM_PLUGINS_PATH"); do
    module_init="$CUSTOM_PLUGINS_PATH/$module/index.sh"
    [ -e "$module_init" ] || continue
    summary=$(sed -n 's/^# *@ *about  *//p' "$module_init" | head -1)
    [ -z "$summary" ] && summary="see $(bold "$FRAMEWORK_NAME $module help")"
    printf '    %-10s --   %s\n' "$module" "$summary"
  done

}

global_help() {
  help_module="$FRAMEWORK_ROUTE/help/index.sh"
  (
    export APP_SOURCE="$help_module"
    export APP_MODULE=1
    . "$help_module"
  )
}

# target list generator
_generate_list() {
  # implement your own algorithm in the PROJECT_LIST_GENERATOR file
  if [ -e "$PROJECTS_LIST_GENERATOR" ]; then
    # if the PROJECTS_LIST_GENERATOR file exists, source it
    . "$PROJECTS_LIST_GENERATOR"
  else
    printf '%s\n' "$HOME" > "$PROJECTS_LIST"
  fi
}
