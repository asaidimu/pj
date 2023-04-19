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
  load "Checking for updates" "Network request complete" $pid
  wait $pid
  version=$?

  if [ $version -eq 0 ]; then
    success "Already at latest version"
  elif [ $version -eq 1 ]; then
       warn "Could not get latest version information."
       error "${ERROR_MSG}"
  else
    next=$(cat /tmp/pj_upgrade) && rm /tmp/pj_upgrade

    script=$(mktemp "/tmp/XXX.sh")
    curl -fsL "$FRAMEWORK_URL/releases/download/${next}/install.sh" --output "$script" >/dev/null &
    pid=$!
    load "Downloading updates" $pid
    wait $pid

    [ -e "$script" -a -s "$script" ] && {
      sh "$script" > /dev/null &
      pid=$!
      load "Installing updates" $pid
      wait $pid
    } || {
        warn "Could not update framework."
        error "${ERROR_MSG}"
    }

    if [ $? -ne 0 ]; then
        warn "Could not update framework."
        error "${ERROR_MSG}"
    fi

      sed -E "s/(VERSION=.)${FRAMEWORK_VERSION}(.)/\1${next}\2/g" -i `which pj`
      success "Upgraded to $(bold $next)"
  fi
}

init "$@"
