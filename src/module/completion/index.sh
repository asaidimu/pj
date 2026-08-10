# --------
# summary: regenerates shell completions
# --------

GENERATOR="$FRAMEWORK_PATH/src/completion/generate.sh"

help() {
cat <<EOF
$(bold ABOUT)
    $(bold "$FRAMEWORK_NAME $FRAMEWORK_VERSION")

$(bold "COMMAND"): $(blue completion)
    (re)generates the shell completion files for $FRAMEWORK_NAME from the
    installed modules and plugins, and installs them into the shell
    completion directories.

$(bold USAGE)
    $FRAMEWORK_NAME completion
    $FRAMEWORK_NAME completion zsh
    $FRAMEWORK_NAME completion bash

$(bold EXAMPLE)
    $(prompt "pj completion")
    $(prompt "pj completion bash")

EOF
}

_confirm_generator() {
  [ -e "$GENERATOR" ] || {
    panic "completion generator not found: $GENERATOR" "$ERROR_MISSING_COMMAND"
  }
}

# install a generated completion file if the target shell is available
_install() {
  shell="$1"
  dest="$2"

  command -v "$shell" >/dev/null 2>&1 || {
    inform "$shell not installed, skipping"
    return 0
  }

  mkdir -p "$(dirname "$dest")"

  if sh "$GENERATOR" "$shell" > "$dest" 2>/dev/null; then
    success "$shell completion installed at $dest"
  else
    panic "could not generate $shell completion" "$ERROR"
  fi
}

init() {
  _confirm_generator

  case "$1" in
    help)
      help
      ;;
    bash)
      _install bash "$HOME/.local/share/bash-completion/completions/$FRAMEWORK_NAME"
      ;;
    zsh)
      _install zsh "$HOME/.local/share/zsh/site-functions/_$FRAMEWORK_NAME"
      ;;
    "")
      _install bash "$HOME/.local/share/bash-completion/completions/$FRAMEWORK_NAME"
      _install zsh "$HOME/.local/share/zsh/site-functions/_$FRAMEWORK_NAME"
      ;;
    *)
      help
      panic "unknown shell: $1 (expected bash or zsh)" "$ERROR_INVALID_OPTIONS"
      ;;
  esac
}

init "$@"