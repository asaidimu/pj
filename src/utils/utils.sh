setup(){
  export PROJECT_NAME="$1"
  export PROJECT_FILE_PATH=""
  export PROJECT_PATH="$PROJECTS_PATH/$PROJECT_NAME"
  export PROJECT_DATA="$PROJECT_PATH/.$FRAMEWORK_NAME"
}

update_template(){
  [ -z "$1" ] && { error "no template specified!" $ERROR_INVALID_OPTIONS; }
  template_file="$1"; shift;

  for opt in $@; do
    key=$(echo $opt | sed -E "s/(\w+*):.*$/\\\{\\\{\1\\\}\\\}/g");
    val=$(echo $opt | sed -E "s/\w+*:(.*$)/\1/g");
    sed -E "s|${key}|${val}|g" -i $template_file
  done
}

fill_template(){
  [ -z "$1" ] && { error "no template specified!" $ERROR_INVALID_OPTIONS; }
  template_file="$1";

  keys=$(cat $template_file | grep "{{.*}}" | sed -E "s/.*\{\{(.*)\}\}.*/\1/g")

  for key in $keys; do
    val=$(question $key)
    key="\\{\\{$key\\}\\}"
    sed -E "s|${key}|${val}|g" -i $template_file
  done
}

extract_file(){
  [ -z "$1" ] && { error "no template specified!" $ERROR_INVALID_OPTIONS; }
  [ -z "$2" ] && { error "template output not specified!" $ERROR_INVALID_OPTIONS; }

  template="$ASSET_PATH/$1"
  output="$2"
  [ -e "$template" ] && cp "$template" "$output"
}

question(){
  property=$1
  default=$2

  prompt="$(echo `bold_grey  'question'`): $property"

  [ -n "$default" ] && prompt="$prompt ($(blue "$default"))"

  prompt="$prompt: "

  read -p "$prompt" input

  [ -z "$input" ] && input=$default

  echo $input
}

prompt(){
  echo "$(red "user@host:")$(blue "~")$ $@"
}

is_flag(){
  echo "$1" | grep -E "(^-\w$)|(^--(\w){2,}(\w|-)*$)" 2>&1 > /dev/null
  [  $? -eq 0 ] && return 0 || return 1
}


tabular(){
   echo "$1:$2" | awk -F':' '{printf "    %-10s --   %s\n", $1, $2}'
}

module_list(){
  for module in `ls $FRAMEWORK_ROUTE`; do

    module_init="$FRAMEWORK_ROUTE/$module/index.sh"
    [ -e "$module_init" ] || continue

    summary="$(cat $module_init | grep "summary" | sed -E "s/^.*:\s//g")"
    [ -z "$summary" ] && summary="see $(bold "$FRAMEWORK_NAME $module help")"

    echo "$module:$summary" | awk -F':' '{printf "    %-10s --   %s\n", $1, $2}'
  done
}

global_help(){
  help_module="$FRAMEWORK_ROUTE/help/index.sh"
  . $help_module
}

# target list generator
_generate_list(){
  # implement your own algorithm in the PROJECT_LIST_GENERATOR file
  if [ -e "$PROJECTS_LIST_GENERATOR" ]; then
    # if the PROJECT_LIST_GENERATOR file exists, source it
    . "$PROJECTS_LIST_GENERATOR"
  else
    echo "$HOME" > "$PROJECTS_LIST"
  fi
}
