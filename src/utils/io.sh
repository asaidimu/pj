time_stamp(){
  echo "`date +%H:%M:%S`"
}

repl() {
  char="$1"
  count="$2"
  i=0
  while [ "$i" -lt "$count" ]; do
    printf "%s" "$char"
    i=$((i + 1))
  done
}

label(){
  color="$1"
  level=$(echo "$2" | tr '[:lower:]' '[:upper:]')
  size=$(printf "$level" | wc -m)
  size=$((8 - size))
  printf "$($color "$(repl " " $size)${level} │") "
}

log(){
  stamp=$(time_stamp)

  out="[ $stamp ] $@"

  echo "$out" >> $FRAMEWORK_LOGS
}

prompt(){
  echo "$(red "user@host:")$(blue "~")$ $@"
}

question() {
    property="$1"
    default="$2"

    prompt="$(bold_grey 'question'): $property"

    [ -n "$default" ] && prompt="$prompt ($(blue "$default"))"

    prompt="$prompt: "

    printf "%s" "$prompt"
    read -r input

    [ -z "$input" ] && input=$default

    echo "$input"
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

notify(){
  # report the outcome of the previous command (its exit status)
  _status=$?

  [ "$FLAG_SILENT" -eq 0 ] || return "$_status"

  success_msg="$1"; failure_msg="$2";

  if [ "$_status" -eq 0 ]; then
    success "$success_msg"
  else
    error "$failure_msg" "$_status"
  fi
  return "$_status"
}

# NOTE: the banner artwork is duplicated in assets/installer.sh (self-contained
# installer). Keep the two in sync when changing it.
banner(){
    duration=0.02
    printf "\n" && sleep $duration
    printf "\n" && sleep $duration
    bold_yellow '          ,ggggggggggg,\n'        && sleep $duration
    bold_yellow '          dP"""88""""""Y8,\n'     && sleep $duration
    bold_yellow '          Yb,  88      `8b \n'    && sleep $duration
    bold_yellow '           `"  88      ,8P  ' && blue 'ggggg,\n'  && sleep $duration
    bold_yellow '               88aaaad8P"   ' && blue 'dP"  Y8,\n'  && sleep $duration
    bold_yellow '               88"""""      ' && blue 'Yb,  gg\n'  && sleep $duration
    bold_yellow '               88           ' && blue ' `"  8I\n'  && sleep $duration
    bold_yellow '               88           ' && blue '    ,8I\n'  && sleep $duration
    bold_yellow '               88           ' && blue '  _,d8I\n'  && sleep $duration
    bold_yellow '               88           ' && blue '888P"888\n' && sleep $duration
    bold_yellow '                            ' && blue '   ,d8I\n'  && sleep $duration
    bold_yellow "                            " && blue " ,dP'8I\n"  && sleep $duration
    bold_yellow '                            ' && blue ',8"  8I\n'  && sleep $duration
    bold_yellow '                            ' && blue 'I8   8I\n'  && sleep $duration
    bold_yellow '                            ' && blue '`8, ,8I\n'  && sleep $duration
    bold_yellow '                            ' && blue ' `Y8P\n'    && sleep $duration
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

        if ! kill -0 "$pid" 2>/dev/null; then
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
