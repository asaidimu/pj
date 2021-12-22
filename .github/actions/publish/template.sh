#!/usr/bin/env sh

FRAMEWORK_VERSION="{{ version }}"
FRAMEWORK_URL="{{ url }}"
FRAMEWORK_NAME="pj"
FRAMEWORK_BRANCH="main"

FRAMEWORK_PATH="$HOME/.local/share/$FRAMEWORK_NAME/$FRAMEWORK_VERSION"
FRAMEWORK_BINARY="$HOME/.local/bin/$FRAMEWORK_NAME"

_dir() {
    if [ -d $FRAMEWORK_PATH ]; then
        rm -rf $FRAMEWORK_PATH
    fi
    mkdir -p $FRAMEWORK_PATH

    git clone $FRAMEWORK_URL --branch=$FRAMEWORK_BRANCH $FRAMEWORK_PATH

    if [ $? -ne 0 ]; then
        error "could not clone framework!" $ERROR
    fi
}

_binary() {
    if [ -e $FRAMEWORK_BINARY ]; then
        rm -rf $FRAMEWORK_BINARY
    fi

    cat > $FRAMEWORK_BINARY << EOF
#!/usr/bin/env sh

# -- set framework path --
export FRAMEWORK_NAME="$FRAMEWORK_NAME"
export FRAMEWORK_PATH="$FRAMEWORK_PATH"
export FRAMEWORK_RELEASE="$FRAMEWORK_BRANCH"
export FRAMEWORK_URL="$FRAMEWORK_URL"
export FRAMEWORK_VERSION="$FRAMEWORK_VERSION"

# -- bootstrap --
. "$FRAMEWORK_PATH/src/bootstrap.sh"
EOF
    [ -e $FRAMEWORK_BINARY ] && chmod +x $FRAMEWORK_BINARY || error "could not install!"
}

bold(){
  echo "\033[1;37;48m${@}\033[0m";
}
bold_blue(){
  echo "\033[1;34;48m${@}\033[0m";
}
bold_cyan(){
  echo "\033[1;36;48m${@}\033[0m";
}
bold_green(){
  echo "\033[1;32;48m${@}\033[0m";
}
bold_grey(){
  echo "\033[1;30;48m${@}\033[0m";
}
bold_red(){
  echo "\033[1;31;48m${@}\033[0m";
}
bold_yellow(){
  echo "\033[1;33;48m${@}\033[0m";
}
blue(){
  echo "\033[0;34;48m${@}\033[0m";
}
cyan(){
  echo "\033[0;36;48m${@}\033[0m";
}
green(){
  echo "\033[0;32;48m${@}\033[0m";
}
grey(){
  echo "\033[0;37;48m${@}\033[0m";
}
red(){
  echo "\033[0;31;48m${@}\033[0m";
}
yellow(){
  echo "\033[0;33;48m${@}\033[0m";
}
header(){
  echo "\033[35m${@}\033[0m";
}
underline(){
  echo "\033[4m${@}\033[0m";
}
time_stamp(){
  echo "$(bold_grey `date +%H:%M:%S`)"
}

log(){
  [ $FLAG_SILENT -eq 0 ] || return

  title=$(bold "$FRAMEWORK_NAME @ $FRAMEWORK_MODULE_NAME")
  stamp=$(time_stamp)

  out="$(bold '[')$title $stamp$(bold ']') $@"

  echo "$out"
}

inform(){  echo "$(bold_blue  info)" "${@}"; }
success(){ echo "$(bold_green  success)" "${@}";}
warn(){    echo "$(bold_yellow  warning)" "${@}";}

debug(){
  silent=$FLAG_SILENT
  export FLAG_SILENT=0
  log "$(bold_blue   debug)" "${@}";
  export FLAG_SILENT=$silent;
}

error(){
  export FLAG_SILENT=0
  [ -n "$1" ] && message=$1 || message="an unexpected error occured !"
  [ -n "$2" ] && error=$2 || error=$ERROR

  echo "$(bold_red error)" "${message}";
  exit $error
}

notify(){
  [ $FLAG_SILENT -eq 0 ] || return

  status=$?; success_msg="$1"; failure_msg="$2";

  [ $status -eq 0 ] && {
    success "$success_msg" && return
  } || {
    error "$failure_msg" "$status"
  }
}

_dir && _binary && inform "installation complete"
