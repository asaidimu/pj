#!/usr/bin/env bash

FRAMEWORK_NAME="pj"
FRAMEWORK_BRANCH="main"
FRAMEWORK_VERSION="{{version}}"
FRAMEWORK_URL="{{url}}"

FRAMEWORK_PATH="$HOME/.local/share/$FRAMEWORK_NAME"
FRAMEWORK_BINARY="$HOME/.local/bin/$FRAMEWORK_NAME"

_clean(){
    sleep 0.2
    if [ -d $FRAMEWORK_PATH ]; then
        rm -rf $FRAMEWORK_PATH
    fi
    if [ -e $FRAMEWORK_BINARY ]; then
        rm -rf $FRAMEWORK_BINARY
    fi
}

_extract() {
    TMPFILE="$(mktemp -t --suffix=.SUFFIX installer_sh.XXXXXX)"
    trap "rm -f '$TMPFILETMPFILE'" 0               # EXIT
    trap "rm -f '$TMPFILETMPFILE'; exit 1" 2       # INT
    trap "rm -f '$TMPFILETMPFILE'; exit 1" 1 15    # HUP TERM

    echo "$SOURCE" | base64 --decode > $TMPFILE
    mkdir -p $FRAMEWORK_PATH
    cd $FRAMEWORK_PATH
    tar -Jxf $TMPFILE
    rm -rf $TMPFILE
}

_install_script() {
    sleep 0.2
cat > $FRAMEWORK_BINARY << EOF
#!/usr/bin/env sh

# -- set framework path --
FRAMEWORK_NAME=\${FRAMEWORK_NAME:-"$FRAMEWORK_NAME"}
FRAMEWORK_PATH=\${FRAMEWORK_PATH:-"$FRAMEWORK_PATH"}
FRAMEWORK_RELEASE="$FRAMEWORK_BRANCH"
FRAMEWORK_URL=\${FRAMEWORK_URL:-"$FRAMEWORK_URL"}
FRAMEWORK_VERSION="$FRAMEWORK_VERSION"

# -- bootstrap --
. "\$FRAMEWORK_PATH/src/bootstrap.sh"
EOF
    if [ -e $FRAMEWORK_BINARY ]; then
        chmod +x $FRAMEWORK_BINARY
    else
        return 2
    fi
}

_main(){
    _banner

    # --perfom checks
    sleep 0.3 &
    pid=$!
    _load "Initializing" "Dependency checks complete" $pid

    # -- clean up --
    _clean &
    pid=$!
    _load "Cleaning previous installations" "Artifacts removed" $pid
    wait $pid
    [ $? -ne 0 ] && _abort

    # -- extract --
    _extract &
    pid=$!
    _load "Extracting files" "Files extracted" $pid
    wait $pid
    [ $? -ne 0 ] && _abort

    # -- add command to path --
    _install_script &
    pid=$!
    _load "Installing script" "Script installed at $(blue $FRAMEWORK_BINARY)" $pid
    wait $pid
    [ $? -ne 0 ] && _abort

    _log "Installed  $(bold $(blue "$FRAMEWORK_NAME-$FRAMEWORK_VERSION"))\n"
    _log "Run ${FRAMEWORK_NAME} to get started.\n"
    _log "Happy Coding!\n"
}

# ---------------------------------------------------------------------------- #

_repl() { printf "$1"'%.s' $(eval "echo {1.."$(($2))"}"); }

_label(){
  color="$1"
  level="$2"
  size=$(printf "$level" | wc -m)
  size=$((6 - size))
  printf "$($color "$(_repl " " $size)${level} │") "
}

_log(){
  _label bold_green "LOG"
  printf "${@}"
}
_alert() {
  _label bold_yellow "ALERT"
  printf "${@}"
}
_error(){
  _label bold_red "ERROR"
  printf "${@}"
}
_trace(){
  _label bold_cyan "TRACE"
  printf "${@}"
}
_debug(){
  _label bold_blue "DEBUG"
  printf "${@}"
}

_abort(){
    printf "$(red "[") Install failed ! $(red "]")\n"
    exit 27
}

bold_blue(){
  printf "\033[1;34;48m${@}\033[0m";
}
bold_cyan(){
  printf "\033[1;36;48m${@}\033[0m";
}
bold_green(){
  printf "\033[1;32;48m${@}\033[0m";
}
bold_grey(){
  printf "\033[1;30;48m${@}\033[0m";
}
bold_red(){
  printf "\033[1;31;48m${@}\033[0m";
}
bold_yellow(){
  printf "\033[1;33;48m${@}\033[0m";
}

bold(){
  echo "\033[1;37;48m${@}\033[0m";
}

red(){
  echo "\033[1;31;48m${@}\033[0m";
}

blue(){
  printf "\033[0;34;48m${@}\033[0m";
}
cyan(){
  printf "\033[0;36;48m${@}\033[0m";
}
yellow(){
  printf "\033[1;33;48m${@}\033[0m";
}

green(){
  printf "\033[1;32;48m${@}\033[0m";
}

_clear_line(){
    printf "\033[1000D" # go to begining of line
    printf "\033[0K" # clear line
}

_load() {
    text="$1"
    msg="$2"
    pid="$3"

    text="$(_trace "${text}")"
    a="${text}    "
    b="${text} .  "
    c="${text} .. "
    d="${text} ..."

    waiting=1
    while [ $waiting -eq 1 ]; do
        printf "$a"
        sleep 0.3
        _clear_line

        printf "$b"
        sleep 0.3
        _clear_line

        printf "$c"
        sleep 0.3
        _clear_line

        printf "$d"

        ps cax | grep -E "\s?$pid" 2>&1 > /dev/null
        if [ $? -ne 0 ]; then
            waiting=0
        fi
        sleep 0.3
        _clear_line
    done
    _log "${msg}\n"
}

_banner(){
    duration=0.03
    printf "\n" && sleep $duration
    printf "\n" && sleep $duration
    yellow '          ,ggggggggggg,\n'        && sleep $duration
    yellow '          dP"""88""""""Y8,\n'     && sleep $duration
    yellow '          Yb,  88      `8b \n'    && sleep $duration
    yellow '           `"  88      ,8P  ' && blue 'ggggg,\n'  && sleep $duration
    yellow '               88aaaad8P"   ' && blue 'dP"  Y8,\n'  && sleep $duration
    yellow '               88"""""      ' && blue 'Yb,  gg\n'  && sleep $duration
    yellow '               88           ' && blue ' `"  8I\n'  && sleep $duration
    yellow '               88           ' && blue '    ,8I\n'  && sleep $duration
    yellow '               88           ' && blue '  _,d8I\n'  && sleep $duration
    yellow '               88           ' && blue '888P"888\n' && sleep $duration
    yellow '                            ' && blue '   ,d8I\n'  && sleep $duration
    yellow "                            " && blue " ,dP'8I\n"  && sleep $duration
    yellow '                            ' && blue ',8"  8I\n'  && sleep $duration
    yellow '                            ' && blue 'I8   8I\n'  && sleep $duration
    yellow '                            ' && blue '`8, ,8I\n'  && sleep $duration
    yellow '                            ' && blue ' `Y8P\n'    && sleep $duration
    printf "\n"
    printf "\n"
}

# ---------------------------------------------------------------------------- #
