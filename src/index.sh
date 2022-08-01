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
  cmd="$1"

  if [ -z "$cmd" ]; then
      cmd="open"
  fi

  route="$FRAMEWORK_ROUTE/${cmd}/index.sh"

  [ -e $route ] || {
      error_msg="Command $(bold_yellow ${cmd}) not found! See $FRAMEWORK_NAME help for usage"
      error "$error_msg" $ERROR_ILLEGAL_OP
  }

  log "Executing module [ ${cmd} ]"

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
