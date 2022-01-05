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

# -- start() --
start(){
  unset -f start

  if [ -z "$1" ]; then
      show_version
      exit
  fi

  route="$FRAMEWORK_ROUTE/$1/index.sh"

  [ -e $route ] || {
      error_msg="Command $(bold_yellow $1) not found! See $FRAMEWORK_NAME help for usage"
      error "$error_msg" $ERROR_ILLEGAL_OP
  }

  log "Executing module [ ${1} ]"

  [ -z "$1" ] || shift
  . $route
}

remove_flags(){
  unset -f remove_flags
  log "checking flags"

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
  log "START"
  trap 'log "EXIT"' EXIT
  remove_flags $@
  start $FRAMEWORK_ARGUMENTS
}

init "$@"
