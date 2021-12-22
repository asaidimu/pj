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
  repo=$(echo $FRAMEWORK_URL | sed -E "s/.*com.//g")
  json=$(curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/$repo/releases/latest)
  next=$(echo $json | jq ".tag_name" | sed "s/\"//g")

  if [ $next > $FRAMEWORK_VERSION ]; then
      cd $FRAMEWORK_PATH
      git pull origin
      cat CHANGELOG.md
      inform "upgrade to version $(green $next) successfull!"
  else
      inform "nothing to do!"
  fi

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
