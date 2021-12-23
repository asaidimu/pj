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
  sleep 0.2

  cd $FRAMEWORK_PATH
  git pull origin &> /dev/null

  return $?
}

check_update() {
  sleep 0.2
  repo=$(echo $FRAMEWORK_URL | sed -E "s/.*com.//g")
  json=$(curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/$repo/releases/latest)
  next=$(echo $json | jq ".tag_name" | sed "s/\"//g")

  if [ $next > $FRAMEWORK_VERSION ]; then
      return 0
  else
      return 1
  fi
}

init(){
  unset -f init
  [ "$1" = "help" ] && { help; return 0; }

  banner

  check_update &
  pid=$!
  _load "Checking for updates" $pid
  wait $pid

  if [ $? -ne 0 ]; then
      printf "$(green "[") No updates available. $(green "]")\n"
  else
      upgrade &
      pid=$!
      _load "Pulling updates" $pid
      wait $pid
      [ $? -ne 0 ] && _abort "Upgrade failed !"

      printf "$(green "[") Upgraded to $(bold $FRAMEWORK_VERSION) $(green "]")\n"
  fi
}

init "$@"

