time_stamp(){
  echo "`date +%H:%M:%S`"
}

repl() { printf "$1"'%.s' $(eval "echo {1.."$(($2))"}"); }

label(){
  color="$1"
  level=$(echo "$2" | sed -E "s/^(.*)/\U\1/g")
  size=$(printf "$level" | wc -m)
  size=$((8 - size))
  printf "$($color "$(repl " " $size)${level} │") "
}

log(){
  stamp=$(time_stamp)

  out="[ $stamp ] $@"

  echo "$out" >> $FRAMEWORK_LOGS
}

inquire(){
  msg=$(label bold_blue "INPUT")
  read -p "$msg $@? " answer
  echo "$answer"
}

prompt(){
  echo "$(red "user@host:")$(blue "~")$ $@"
}

question(){
  property=$1
  default=$2

  prompt="$(echo `bold_grey  'question'`): $property"

  [ -n "$default" ] && prompt="$prompt ($(blue "$default"))"

  prompt="$prompt: "

  read -p "$prompt" input

  [ -z "$input" ] && input=$default

  echo $input
}

inform(){
  label bold_blue "INFO"
  echo "${@}";
}
success(){
  label bold_green "success"
  echo "${@}";
}
warn(){
  label bold_yellow "warning"
  echo "${@}";
}

trace(){
  label bold_cyan "TRACE"
  printf "${@}"
}

debug(){
  silent=$FLAG_SILENT
  export FLAG_SILENT=0
  label bold_blue "debug"
  echo "${@}";
  export FLAG_SILENT=$silent;
}

error(){
  export FLAG_SILENT=0
  [ -n "$1" ] && message=$1 || message="an unexpected error occured !"
  [ -n "$2" ] && error=$2 || error=$ERROR

  log "ERROR ($error): $message"
  label bold_red "error"
  echo "${message}"
}

panic() {
  export FLAG_SILENT=0
  [ -n "$1" ] && message=$1 || message="an unexpected error occured !"
  [ -n "$2" ] && error=$2 || error=$ERROR

  log "ERROR ($error): $message"
  label bold_red "error"
  echo "${message}"
  exit $error
}

abort(){
    [ -n "$1" ] && message=$1 || message="an unexpected error occured !"
    [ -n "$2" ] && error=$2 || error=$ERROR

    log "ERROR ($error): $message"
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

clear_line(){
    printf "\033[1000D" # go to begining of line
    printf "\033[0K" # clear line
}

load() {
    text="$1"
    msg="$2"
    pid="$3"

    [ -z "$pid" ] &&  {
      pid="$msg"
      msg=""
    }

    text="$(trace "${text}")"
    a="${text}    "
    b="${text} .  "
    c="${text} .. "
    d="${text} ..."

    waiting=1
    while [ $waiting -eq 1 ]; do
        printf "$a"
        sleep 0.3
        clear_line

        printf "$b"
        sleep 0.3
        clear_line

        printf "$c"
        sleep 0.3
        clear_line

        printf "$d"

        ps cax | grep -E "\s?$pid" 2>&1 > /dev/null
        if [ $? -ne 0 ]; then
            waiting=0
        fi
        sleep 0.3
        clear_line
    done

    [ -z "$msg" ] && clear_line || inform "${msg}"
}

show_version(){
    banner
    sleep 0.2 &
    pid=$!
    load "Checking Version" $pid
    wait $pid
    bold_green "\t     Version $(echo $FRAMEWORK_VERSION | sed -E 's/v//g')\n"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        abort "$1 is required but not installed."
        exit 1
    fi
}
