time_stamp(){
  echo "`date +%H:%M:%S`"
}

log(){
  stamp=$(time_stamp)

  out="[ $stamp ] $@"

  echo "$out" >> $FRAMEWORK_LOGS
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


  log "ERROR $error: $message"
  echo "$(bold_red '[')" "$(bold_red 'ERROR')" "$(bold_red ']')" "${message}"
  exit $error
}

abort(){
    [ -n "$1" ] && message=$1 || message="an unexpected error occured !"
    [ -n "$2" ] && error=$2 || error=$ERROR

    log "ABORTED"
    printf "$(bold_red "[") $message $(bold_red "]")\n"
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

banner(){
    duration=0.02
    printf "\n" && sleep $duration
    printf "\n" && sleep $duration
    bold_yellow '          ,ggggggggggg,\n'        && sleep $duration
    bold_yellow '          dP"""88""""""Y8,\n'     && sleep $duration
    bold_yellow '          Yb,  88      `8b \n'    && sleep $duration
    bold_yellow '           `"  88      ,8P gg\n'  && sleep $duration
    bold_yellow '               88aaaad8P"  ""\n'  && sleep $duration
    bold_yellow '               88"""""     gg\n'  && sleep $duration
    bold_yellow '               88          8I\n'  && sleep $duration
    bold_yellow '               88         ,8I\n'  && sleep $duration
    bold_yellow '               88       _,d8I\n'  && sleep $duration
    bold_yellow '               88     888P"888\n' && sleep $duration
    bold_yellow '                         ,d8I\n'  && sleep $duration
    bold_yellow "                       ,dP'8I\n"  && sleep $duration
    bold_yellow '                      ,8"  8I\n'  && sleep $duration
    bold_yellow '                      I8   8I\n'  && sleep $duration
    bold_yellow '                      `8, ,8I\n'  && sleep $duration
    bold_yellow '                       `Y8P\n'    && sleep $duration
    printf "\n"
    printf "\n"
}

label() {
    bold_green "[ "
    printf "$@"
    bold_green " ]\n"
}

clear_line(){
    printf "\033[1000D" # go to begining of line
    printf "\033[0K" # clear line
}

load() {
    text="$1"
    pid="$2"

    waiting=1
    while [ $waiting -eq 1 ]; do
        bold_green "[ "
        printf "${text}    "
        bold_green " ]"
        sleep 0.3
        clear_line

        bold_green "[ "
        printf "${text} .  "
        bold_green " ]"
        sleep 0.3
        clear_line

        bold_green "[ "
        printf "${text} .. "
        bold_green " ]"
        sleep 0.3
        clear_line

        bold_green "[ "
        printf "${text} ..."
        bold_green " ]"

        ps cax | grep -E "\s?$pid" 2>&1 > /dev/null
        if [ $? -ne 0 ]; then
            waiting=0
        fi
        sleep 0.3
        clear_line
    done
}

show_version(){
    banner
    sleep 0.2 &
    pid=$!
    load "Checking Version" $pid
    wait $pid
    label "Using version $(echo $FRAMEWORK_VERSION | sed -E 's/v//g')"
}

