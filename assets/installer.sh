#!/usr/bin/env sh

# NOTE: this is a template. bin/build.sh appends the bundled io library
# (src/utils/{colors,io}.sh), the SOURCE tarball, and the _main call.
# The installer runs before pj exists, so it carries its own copy of the
# framework UI — generated from the same source on every build, which is
# what keeps the two in sync.

FRAMEWORK_NAME="pj"
FRAMEWORK_BRANCH="main"
FRAMEWORK_VERSION="{{version}}"
FRAMEWORK_URL="{{url}}"

FRAMEWORK_PATH="$HOME/.local/share/$FRAMEWORK_NAME"

# -- where the launcher lives -------------------------------------------------

# does colon-joined PATH already contain this directory?
_path_contains() {
    case ":$PATH:" in
        *":$1:"*) return 0 ;;
        *) return 1 ;;
    esac
}

# pick the directory for the pj launcher:
#   1. $FRAMEWORK_BIN_DIR, when set (unattended installs pin this)
#   2. $HOME/.local/bin, when it is (or can be created and is) on PATH
#   3. the first writable directory already on PATH
#   4. $FRAMEWORK_PATH/bin — inside the install tree; never on PATH, so
#      _ensure_path offers to add it to the shell rc afterwards
_pick_bin_dir() {
    if [ -n "${FRAMEWORK_BIN_DIR:-}" ]; then
        printf '%s\n' "$FRAMEWORK_BIN_DIR"
        return 0
    fi

    case ":$PATH:" in
        *":$HOME/.local/bin:"*)
            mkdir -p "$HOME/.local/bin" 2>/dev/null
            if [ -d "$HOME/.local/bin" ] && [ -w "$HOME/.local/bin" ]; then
                printf '%s\n' "$HOME/.local/bin"
                return 0
            fi
            ;;
    esac

    _pb_old_ifs=$IFS
    IFS=:
    for _pb_dir in $PATH; do
        [ -n "$_pb_dir" ] || continue
        if [ -d "$_pb_dir" ] && [ -w "$_pb_dir" ]; then
            IFS=$_pb_old_ifs
            printf '%s\n' "$_pb_dir"
            return 0
        fi
    done
    IFS=$_pb_old_ifs

    printf '%s\n' "$FRAMEWORK_PATH/bin"
}

# the rc file for the user's login shell
_rc_file() {
    case "${SHELL:-}" in
        */zsh)  printf '%s\n' "$HOME/.zshrc" ;;
        */bash) printf '%s\n' "$HOME/.bashrc" ;;
        */fish) printf '%s\n' "$HOME/.config/fish/config.fish" ;;
        *)      printf '%s\n' "$HOME/.profile" ;;
    esac
}

# after install: if the launcher dir is not on PATH, offer to fix the rc
# file (TTY) or print the line to add (non-interactive, e.g. curl | sh)
_ensure_path() {
    _ep_bin="$1"
    _path_contains "$_ep_bin" && return 0

    _ep_rc="$(_rc_file)"

    # fish does not understand export PATH=...; give it its own hint
    case "${SHELL:-}" in
        */fish)
            warn "$_ep_bin is not on your PATH"
            inform "enable it with:  fish_add_path $_ep_bin"
            return 0
            ;;
    esac

    # stdin is a pipe (curl | sh): never block, just print the instruction
    if [ ! -t 0 ]; then
        warn "$_ep_bin is not on your PATH"
        inform "add it with:  export PATH=\"$_ep_bin:\$PATH\"   (in $_ep_rc)"
        return 0
    fi

    _ep_answer="$(question "$_ep_bin is not on your PATH — add it to $_ep_rc" "y/N")"
    case "$_ep_answer" in
        y|Y|yes|YES)
            if [ -f "$_ep_rc" ] && grep -qF "$_ep_bin" "$_ep_rc"; then
                inform "$_ep_rc already references $_ep_bin"
                return 0
            fi
            # keep $HOME literal so the line survives moving the home dir
            _ep_entry="$_ep_bin"
            case "$_ep_bin" in
                "$HOME"/*) _ep_entry="\$HOME${_ep_bin#"$HOME"}" ;;
            esac
            {
                printf '\n# pj: added by the installer\n'
                printf 'export PATH="%s:$PATH"\n' "$_ep_entry"
            } >> "$_ep_rc"
            success "added $_ep_bin to $_ep_rc — open a new shell or run: . $_ep_rc"
            ;;
        *)
            inform "skipped — run the launcher directly: $_ep_bin/pj"
            ;;
    esac
}

# -- install steps ------------------------------------------------------------

_clean(){
    sleep_frac 0.2
    if [ -d "$FRAMEWORK_PATH" ]; then
        rm -rf "$FRAMEWORK_PATH"
    fi
    # launchers from this and earlier installs — the location can move
    # between versions (e.g. a new writable PATH dir), so clear them all
    if [ -e "$HOME/.local/bin/$FRAMEWORK_NAME" ]; then
        rm -f "$HOME/.local/bin/$FRAMEWORK_NAME"
    fi
    if [ -n "${FRAMEWORK_BINARY:-}" ] && [ -e "$FRAMEWORK_BINARY" ] &&
       [ "$FRAMEWORK_BINARY" != "$HOME/.local/bin/$FRAMEWORK_NAME" ]; then
        rm -f "$FRAMEWORK_BINARY"
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
            error "missing tool required to install: ${_tool}"
            return 1
        fi
    done
    return 0
}

_check_dependencies() {
    local _deps="$FRAMEWORK_PATH/src/utils/deps.sh"

    if [ ! -f "$_deps" ]; then
        error "dependency manifest not found: ${_deps}"
        return 1
    fi
    . "$_deps"

    local _missing
    _missing=$(missing_required)
    if [ -n "$_missing" ]; then
        error "missing required tools: ${_missing}"
        warn "install them and run this installer again"
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
    sleep_frac 0.2
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
    banner
    inform "pj${FRAMEWORK_VERSION:+ $FRAMEWORK_VERSION} — $FRAMEWORK_URL"

    # -- check the installer's own tools before touching anything --
    _check_extractor || _abort

    # choose the launcher location before cleaning (clean removes the
    # previous copy, wherever it lived)
    FRAMEWORK_BINARY="$(_pick_bin_dir)/$FRAMEWORK_NAME"

    # -- clean up --
    _clean &
    pid=$!
    load "Cleaning previous installations" "Artifacts removed" $pid
    wait $pid
    [ $? -ne 0 ] && _abort

    # -- extract --
    _extract &
    pid=$!
    load "Extracting files" "Files extracted" $pid
    wait $pid
    [ $? -ne 0 ] && _abort

    # -- required framework deps abort; module-specific deps only warn --
    _check_dependencies || _abort

    # -- add command to path --
    _install_script &
    pid=$!
    load "Installing launcher" "Launcher installed at $FRAMEWORK_BINARY" $pid
    wait $pid
    [ $? -ne 0 ] && _abort

    # -- install completion --
    _install_completion &
    pid=$!
    load "Installing completions" "Shell completions installed" $pid
    wait $pid

    # -- install the standalone io library --
    _install_lib &
    pid=$!
    load "Installing io library" "Library available at $FRAMEWORK_PATH/lib/io.sh" $pid
    wait $pid
    [ $? -ne 0 ] && _abort

    # -- make sure the launcher is reachable --
    _ensure_path "$(dirname "$FRAMEWORK_BINARY")"

    printf '\n'
    success "pj${FRAMEWORK_VERSION:+ $FRAMEWORK_VERSION} installed"
    inform "launcher   $FRAMEWORK_BINARY"
    inform "framework  $FRAMEWORK_PATH"
    inform "io library $FRAMEWORK_PATH/lib/io.sh"
    printf '\n'
    inform "run $(bold "$FRAMEWORK_NAME") to get started — $(bold "$FRAMEWORK_NAME help") for usage"
    printf '\n'
}

_abort(){
    panic "Install failed!" 27
}
