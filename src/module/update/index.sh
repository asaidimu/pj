# --------
# summary: upgrades the framework
# --------

ERROR_MSG="Update failed! Check $(bold $FRAMEWORK_LOGS) for details."

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
    $FRAMEWORK_NAME $_command

$(bold EXAMPLE)
    $(prompt "pj $_command $_params")
EOF
}

upgrade(){
  sleep 0.2
  cd $FRAMEWORK_PATH

  node >> $FRAMEWORK_LOGS - <<EOF
const { exec } = require("child_process")
exec("git pull origin main", (error, stout, stderr) => {
if(error)
    console.log(stderr)
    process.exit(2)
})
EOF

return $?
}

check_update() {
  sleep 0.3
  repo=$(echo $FRAMEWORK_URL | sed -E "s/.*com.//g")
  json=$(curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/$repo/releases/latest)

  if [ $? -ne 0 ]; then
      return 1
  fi

  next=$(echo $json | jq ".tag_name" | sed "s/\"//g")

  if [ "$next" = "$FRAMEWORK_VERSION" ]; then
      return 0
  else
      echo $next > /tmp/pj_upgrade
      return 2
  fi
}

init(){
  unset -f init
  [ "$1" = "help" ] && { help; return 0; }

  sleep 0.2
  banner

  check_update &
  pid=$!
  load "Checking for updates" $pid
  wait $pid
  version=$?

  if [ $version -eq 0 ]; then
      printf "$(bold_green "[") Already using the latest and greatest $(bold_green "]")\n"
  elif [ $version -eq 1 ]; then
       log "Could not get latest version."
       abort "${ERROR_MSG}"
  else
      next=$(cat /tmp/pj_upgrade) && rm /tmp/pj_upgrade

      upgrade "$logs" &
      pid=$!
      load "Pulling updates" $pid
      wait $pid

    if [ $? -ne 0 ]; then
        log "Could not update framework."
        abort "${ERROR_MSG}"
    fi

      sed -E "s/(VERSION=.)${FRAMEWORK_VERSION}(.)/\1${next}\2/g" -i `which pj`
      printf "$(bold_green "[") Upgraded to $(bold $next) $(bold_green "]")\n"
  fi
}

init "$@"

