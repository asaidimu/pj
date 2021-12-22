#!/usr/bin/env sh

# -- about --- --------------------------------------------------------------- #
ABOUT=$(cat <<EOF_ABOUT
    NAME        : $FRAMEWORK_NAME
    VERSION     : $FRAMEWORK_VERSION
    DESCRIPTION : Terminal Project Manager
    REQUIRES    : python3 smug jinja2 tmux dash

    AUTHOR      : Lolokile Saidimu
    LICENSE     : MIT
EOF_ABOUT
)
# -----------------------------------------------------------------------------

# -- get_route() --
get_route(){
  unset -f get_route

  route_path=""
  [ -z "$1" ] &&  {
    route_path="$DEFAULT_FRAMEWORK_ROUTE"
  } || {
    route_path="$FRAMEWORK_ROUTE/$1"
  }

  echo "$route_path/index.sh"
}

# -- start() --
start(){
  unset -f start

  route=$(get_route "$1")

  [ -e $route ] || {
      error_msg="command $1 not found! see $FRAMEWORK_NAME help for usage"
      error $error_msg $ERROR_ILLEGAL_OP
  }

  [ -z "$1" ] || shift

  . $route
}

remove_flags(){
  unset -f remove_flags

  arguments=""
  for arg in $@; do
    is_flag "$arg" && {
      set_flag "$arg" && continue
    }
    arguments="$arguments $arg"
  done

  export FRAMEWORK_ARGUMENTS=$arguments
}

# -- init --
init(){
  unset -f init

  remove_flags $@
  start $FRAMEWORK_ARGUMENTS

  #DEBUG: Apr 11, 2021
  #[ $DEBUG -eq 1 ] && {
    #export DEBUG_MODULE_NAME="init"
  #}
}

init "$@"
