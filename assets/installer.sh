#!/usr/bin/env bash

FRAMEWORK_NAME="pj"
FRAMEWORK_BRANCH="main"
FRAMEWORK_VERSION="{{version}}"
FRAMEWORK_URL="{{url}}"

FRAMEWORK_PATH="$HOME/.local/share/$FRAMEWORK_NAME"
FRAMEWORK_BINARY="$HOME/.local/bin/$FRAMEWORK_NAME"

# POSIX sleep(1) takes integer seconds only; sub-second delays are a
# widely available extension. Skip them silently when unsupported.
_sleep_frac() {
    sleep "$1" 2>/dev/null || :
}

_clean(){
    _sleep_frac 0.2
    if [ -d "$FRAMEWORK_PATH" ]; then
        rm -rf "$FRAMEWORK_PATH"
    fi
    if [ -e "$FRAMEWORK_BINARY" ]; then
        rm -rf "$FRAMEWORK_BINARY"
    fi
}

_extract() {
    TMPFILE="$(mktemp)"
    trap 'rm -f "$TMPFILE"' 0                # EXIT
    trap 'rm -f "$TMPFILE"; exit 1' 2        # INT
    trap 'rm -f "$TMPFILE"; exit 1' 1 15     # HUP TERM

    printf "%s" "$SOURCE" | base64 --decode > "$TMPFILE"
    mkdir -p "$FRAMEWORK_PATH"
    cd "$FRAMEWORK_PATH" || return 1
    tar -Jxf "$TMPFILE"
    rm -rf "$TMPFILE"
}

_check_extractor() {
    local _tool
    for _tool in tar base64 mktemp; do
        if ! command -v "$_tool" >/dev/null 2>&1; then
            _error "missing tool required to install: ${_tool}"
            return 1
        fi
    done
    return 0
}

_check_dependencies() {
    local _deps="$FRAMEWORK_PATH/src/utils/deps.sh"

    if [ ! -f "$_deps" ]; then
        _error "dependency manifest not found: ${_deps}"
        return 1
    fi
    . "$_deps"

    local _missing
    _missing=$(missing_required)
    if [ -n "$_missing" ]; then
        _error "missing required tools: ${_missing}"
        _alert "install them and run this installer again"
        return 1
    fi

    local _mod _name
    for _mod in "$FRAMEWORK_PATH"/src/module/*/index.sh; do
        [ -f "$_mod" ] || continue
        _name=$(basename "$(dirname "$_mod")")
        warn_missing_deps "$_name" "$_mod"
    done

    local _plugins="$HOME/.config/$FRAMEWORK_NAME/plugins"
    if [ -d "$_plugins" ]; then
        for _mod in "$_plugins"/*/index.sh; do
            [ -f "$_mod" ] || continue
            _name=$(basename "$(dirname "$_mod")")
            warn_missing_deps "$_name" "$_mod"
        done
    fi

    return 0
}

_install_script() {
    _sleep_frac 0.2
    mkdir -p "$(dirname "$FRAMEWORK_BINARY")"
cat > "$FRAMEWORK_BINARY" << EOF
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
    if [ -e "$FRAMEWORK_BINARY" ]; then
        chmod +x "$FRAMEWORK_BINARY"
    else
        return 2
    fi
}

_install_lib() {
    local _utils="$FRAMEWORK_PATH/src/utils"
    local _lib="$FRAMEWORK_PATH/lib"

    [ -f "$_utils/colors.sh" ] && [ -f "$_utils/io.sh" ] && [ -f "$_utils/app.sh" ] || return 1

    mkdir -p "$_lib" || return 1
    cat "$_utils/colors.sh" "$_utils/io.sh" "$_utils/app.sh" > "$_lib/io.sh" || return 1
    return 0
}

_install_completion() {
    local generator="$FRAMEWORK_PATH/src/completion/generate.sh"
    [ -f "$generator" ] || return 1

    # bash
    if command -v bash >/dev/null 2>&1; then
        local completion_dir="$HOME/.local/share/bash-completion/completions"
        local completion_target="$completion_dir/$FRAMEWORK_NAME"
        mkdir -p "$completion_dir"
        if [ -e "$completion_target" ] || [ -L "$completion_target" ]; then
            rm -f "$completion_target"
        fi
        sh "$generator" bash > "$completion_target" 2>/dev/null || return 1
    fi
    # zsh
    if command -v zsh >/dev/null 2>&1; then
        local completion_dir="$HOME/.local/share/zsh/site-functions"
        local completion_target="$completion_dir/_$FRAMEWORK_NAME"
        mkdir -p "$completion_dir"
        if [ -e "$completion_target" ] || [ -L "$completion_target" ]; then
            rm -f "$completion_target"
        fi
        sh "$generator" zsh > "$completion_target" 2>/dev/null || return 1
    fi
    return 0  # Not an error if neither shell is available
}

_main(){
    _banner

    # -- check the installer's own tools before touching anything --
    _check_extractor || _abort

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

    # -- required framework deps abort; module-specific deps only warn --
    _check_dependencies || _abort

    # -- add command to path --
    _install_script &
    pid=$!
    _load "Installing script" "Script installed at $(blue "$FRAMEWORK_BINARY")" $pid
    wait $pid
    [ $? -ne 0 ] && _abort

    # -- install completion --
    _install_completion &
    pid=$!
    _load "Installing completions" "Shell completions installed" $pid
    wait $pid

    # -- install the standalone io library --
    _install_lib &
    pid=$!
    _load "Installing io library" "Library available at $(blue "$FRAMEWORK_PATH/lib/io.sh")" $pid
    wait $pid
    [ $? -ne 0 ] && _abort

    _log "Installed  $(bold $(blue "$FRAMEWORK_NAME-$FRAMEWORK_VERSION"))"
    _log "Run ${FRAMEWORK_NAME} to get started."
    _log "Happy Coding!"
}

# ---------------------------------------------------------------------------- #

_repl() {
    local char="$1"
    local count="$2"
    local result=""
    local i=0
    while [ $i -lt $count ]; do
        result="${result}${char}"
        i=$((i + 1))
    done
    printf "%s" "$result"
}

_label(){
  color="$1"
  level="$2"
  size=$(printf '%s' "$level" | wc -m)
  size=$((6 - size))
  printf '%s ' "$($color "$(_repl " " $size)${level} │")"
}

_log(){
  _label bold_green "LOG"
  printf '%s\n' "$*"
}
_alert() {
  _label bold_yellow "ALERT"
  printf '%s\n' "$*"
}
_error(){
  _label bold_red "ERROR"
  printf '%s\n' "$*"
}
_trace(){
  _label bold_cyan "TRACE"
  printf '%s' "$*"
}
_debug(){
  _label bold_blue "DEBUG"
  printf '%s\n' "$*"
}

_abort(){
    printf '%s\n' "$(red "[") Install failed ! $(red "]")"
    exit 27
}

bold_blue(){
  printf '\033[1;34;48m%s\033[0m' "$*";
}
bold_cyan(){
  printf '\033[1;36;48m%s\033[0m' "$*";
}
bold_green(){
  printf '\033[1;32;48m%s\033[0m' "$*";
}
bold_grey(){
  printf '\033[1;30;48m%s\033[0m' "$*";
}
bold_red(){
  printf '\033[1;31;48m%s\033[0m' "$*";
}
bold_yellow(){
  printf '\033[1;33;48m%s\033[0m' "$*";
}

bold(){
  printf '\033[1;37;48m%s\033[0m' "$*";
}

red(){
  printf '\033[1;31;48m%s\033[0m' "$*";
}

blue(){
  printf '\033[0;34;48m%s\033[0m' "$*";
}
cyan(){
  printf '\033[0;36;48m%s\033[0m' "$*";
}
yellow(){
  printf '\033[1;33;48m%s\033[0m' "$*";
}

green(){
  printf '\033[1;32;48m%s\033[0m' "$*";
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
        printf '%s' "$a"
        _sleep_frac 0.3
        _clear_line

        printf '%s' "$b"
        _sleep_frac 0.3
        _clear_line

        printf '%s' "$c"
        _sleep_frac 0.3
        _clear_line

        printf '%s' "$d"

        if ! kill -0 "$pid" 2>/dev/null; then
            waiting=0
        fi
        _sleep_frac 0.3
        _clear_line
    done
    _log "$msg"
}

# NOTE: the banner artwork is duplicated in src/utils/io.sh (the framework's
# banner()). Keep the two in sync. This installer is intentionally
# self-contained because it runs before pj is installed.
_banner(){
    duration=0.03
    printf "\n" && _sleep_frac $duration
    printf "\n" && _sleep_frac $duration
    yellow '          ,ggggggggggg,'        && printf '\n' && _sleep_frac $duration
    yellow '          dP"""88""""""Y8,'     && printf '\n' && _sleep_frac $duration
    yellow '          Yb,  88      `8b '    && printf '\n' && _sleep_frac $duration
    yellow '           `"  88      ,8P  ' && blue 'ggggg,'  && printf '\n' && _sleep_frac $duration
    yellow '               88aaaad8P"   ' && blue 'dP"  Y8,'  && printf '\n' && _sleep_frac $duration
    yellow '               88"""""      ' && blue 'Yb,  gg,'  && printf '\n' && _sleep_frac $duration
    yellow '               88           ' && blue ' `"  8I,'  && printf '\n' && _sleep_frac $duration
    yellow '               88           ' && blue '    ,8I,'  && printf '\n' && _sleep_frac $duration
    yellow '               88           ' && blue '  _,d8I,'  && printf '\n' && _sleep_frac $duration
    yellow '               88           ' && blue '888P"888,' && printf '\n' && _sleep_frac $duration
    yellow '                            ' && blue '   ,d8I,'  && printf '\n' && _sleep_frac $duration
    yellow "                            " && blue " ,dP'8I,"  && printf '\n' && _sleep_frac $duration
    yellow '                            ' && blue ',8"  8I,'  && printf '\n' && _sleep_frac $duration
    yellow '                            ' && blue 'I8   8I,'  && printf '\n' && _sleep_frac $duration
    yellow '                            ' && blue '`8, ,8I,'  && printf '\n' && _sleep_frac $duration
    yellow '                            ' && blue ' `Y8P,'    && printf '\n' && _sleep_frac $duration
    printf "\n"
    printf "\n"
}

# ---------------------------------------------------------------------------- #
