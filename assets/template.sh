#!/usr/bin/env bash

FRAMEWORK_NAME="pj"
FRAMEWORK_BRANCH="main"
FRAMEWORK_VERSION="{{version}}"
FRAMEWORK_URL="{{url}}"

FRAMEWORK_PATH="$HOME/.local/share/$FRAMEWORK_NAME"
FRAMEWORK_BINARY="$HOME/.local/bin/$FRAMEWORK_NAME"

_clean(){
    if [ -d $FRAMEWORK_PATH ]; then
        rm -rf $FRAMEWORK_PATH
    fi

    if [ -e $FRAMEWORK_BINARY ]; then
        rm -rf $FRAMEWORK_BINARY
    fi

    sleep 0.5
}

_clone_repo() {
    mkdir -p $FRAMEWORK_PATH

    git clone $FRAMEWORK_URL --branch=$FRAMEWORK_BRANCH $FRAMEWORK_PATH &> /dev/null

    return $?
}

_install_script() {

cat > $FRAMEWORK_BINARY << EOF
#!/usr/bin/env sh

# -- set framework path --
export FRAMEWORK_NAME="$FRAMEWORK_NAME"
export FRAMEWORK_PATH="$FRAMEWORK_PATH"
export FRAMEWORK_RELEASE="$FRAMEWORK_BRANCH"
export FRAMEWORK_URL="$FRAMEWORK_URL"
export FRAMEWORK_VERSION="$FRAMEWORK_VERSION"

# -- bootstrap --
. "\$FRAMEWORK_PATH/src/bootstrap.sh"
EOF
    if [ -e $FRAMEWORK_BINARY ]; then
        chmod +x $FRAMEWORK_BINARY
    else
        return 2
    fi
    sleep 0.2
}

_main(){
    _banner

    # -- clean up --
    _clean &
    pid=$!
    _load "Initializing" $pid
    wait $pid || _abort

    # -- clone repo --
    _clone_repo &
    pid=$!
    _load "Fetching repo" $pid
    wait $pid || _abort

    # -- add command to path --
    _install_script &
    pid=$!
    _load "Installing script" $pid
    wait $pid || _abort

    printf "$(green "[") Installed $FRAMEWORK_NAME $(bold $FRAMEWORK_VERSION) $(green "]")\n"
}

# ---------------------------------------------------------------------------- #
_abort(){
    printf "$(red "[") Install failed ! $(red "]")\n"
    exit 27
}

bold(){
  echo "\033[1;37;48m${@}\033[0m";
}

red(){
  echo "\033[1;31;48m${@}\033[0m";
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

_move_left(){
    index="$1"
    printf "\033[${index}D"
}

_move_right(){
    index="$1"
    printf "\033[${index}C"
}

_load() {
    text="$1"
    pid="$2"

    waiting=1
    while [ $waiting -eq 1 ]; do
        green "[ "
        printf "${text}    "
        green " ]"
        sleep 0.3
        _clear_line

        green "[ "
        printf "${text} .  "
        green " ]"
        sleep 0.3
        _clear_line

        green "[ "
        printf "${text} .. "
        green " ]"
        sleep 0.3
        _clear_line

        green "[ "
        printf "${text} ..."
        green " ]"

        ps cax | grep -E "\s?$pid" 2>&1 > /dev/null
        if [ $? -ne 0 ]; then
            waiting=0
        fi
        sleep 0.3
        _clear_line
    done
}

_banner(){
    duration=0.03
    printf "\n" && sleep $duration
    printf "\n" && sleep $duration
    yellow '          ,ggggggggggg,\n'        && sleep $duration
    yellow '          dP"""88""""""Y8,\n'     && sleep $duration
    yellow '          Yb,  88      `8b \n'    && sleep $duration
    yellow '           `"  88      ,8P gg\n'  && sleep $duration
    yellow '               88aaaad8P"  ""\n'  && sleep $duration
    yellow '               88"""""     gg\n'  && sleep $duration
    yellow '               88          8I\n'  && sleep $duration
    yellow '               88         ,8I\n'  && sleep $duration
    yellow '               88       _,d8I\n'  && sleep $duration
    yellow '               88     888P"888\n' && sleep $duration
    yellow '                         ,d8I\n'  && sleep $duration
    yellow "                       ,dP'8I\n"  && sleep $duration
    yellow '                      ,8"  8I\n'  && sleep $duration
    yellow '                      I8   8I\n'  && sleep $duration
    yellow '                      `8, ,8I\n'  && sleep $duration
    yellow '                       `Y8P\n'    && sleep $duration
    printf "\n"
    printf "\n"
}

# ---------------------------------------------------------------------------- #

_main $@
