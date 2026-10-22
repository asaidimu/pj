# @about   (re)generates shell completion files from installed modules and plugins
# @usage   pj completion [zsh|bash|all]
# @route   zsh   install zsh completions
# @route   bash  install bash completions
# @route   all   install completions for every available shell
# @default all

GENERATOR="$FRAMEWORK_PATH/src/completion/generate.sh"

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

zsh() {
  _confirm_generator
  _install zsh "$HOME/.local/share/zsh/site-functions/_$FRAMEWORK_NAME"
}

bash() {
  _confirm_generator
  _install bash "$HOME/.local/share/bash-completion/completions/$FRAMEWORK_NAME"
}

all() {
  _confirm_generator
  bash
  zsh
}

init() {
  app_start "$@"
}

init "$@"
