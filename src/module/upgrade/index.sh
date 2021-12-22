# --------
# summary: upgrades the framework
# --------

help(){
  _command="upgrade"
  _params=""
  _PARAMS=""

cat <<EOF
$(bold ABOUT)
    $(bold "$FRAMEWORK_NAME $FRAMEWORK_VERSION")

$(bold "COMMAND"): $(blue $_command)
    upgrades the framework

$(bold USAGE)
    $FRAMEWORK_NAME $command $PARAMS

$(bold EXAMPLE)
    $(prompt "pj $command $_params")
EOF
}

upgrade(){
  INSTALL_DIR="$HOME/.local/lib"

  FRAMEWORK_PATH="$INSTALL_DIR/$FRAMEWORK_NAME"

  [ -d $FRAMEWORK_PATH ] &&  {

    rm -rf $FRAMEWORK_PATH

    inform "removed previous version"
  }

  inform "cloning $FRAMEWORK_RELEASE"
  git clone $FRAMEWORK_URL --branch=$FRAMEWORK_RELEASE $FRAMEWORK_PATH 2>> /dev/null # logs.txt
  [ $? -eq 0 ] ||  {
    error "could not clone framework!" $ERROR
  }

  FRAMEWORK_BINARY="$HOME/.local/bin/$FRAMEWORK_NAME"

  [ -e $FRAMEWORK_BINARY ] && {
    rm -rf $FRAMEWORK_BINARY
    inform "removed previous entry point"
  }

  inform "adding entry point"
  extract_file "template/pj" "$FRAMEWORK_BINARY"

  VERSION=$(ag "version" "$ASSET_PATH/data/project" | sed -E "s/^.*:\s*//g")
  update_template $FRAMEWORK_BINARY $(cat <<EOF
name:$FRAMEWORK_NAME
version:$VERSION
framework:$FRAMEWORK_PATH
release:$FRAMEWORK_RELEASE
url:$FRAMEWORK_URL
EOF
)
  chmod +x "$FRAMEWORK_BINARY"

  inform "upgrade to version $(green $VERSION) successfull!"
}

init(){
  unset -f init

  [ "$1" = "help" ] && { help; return 0; }
  upgrade
  [ $DEBUG -eq 1 ] && {
    export DEBUG_MODULE_NAME="upgrade"
  }
}

init "$@"
