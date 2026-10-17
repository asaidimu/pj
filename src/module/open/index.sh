#!/bin/sh
# --------
# summary: open a project in a tmux session
# requires: tmux fzf tree
# --------
# @about   open a project in a tmux session (fuzzy selection)
# @usage   pj open [refresh]
# @route   refresh  (re)generate the project list
# @default main

# use fzf to list and select a session target
_select_target() {
  [ -e "$PROJECTS_LIST" ] || _generate_list

  target=$(fzf --border=rounded --preview 'tree --dirsfirst -C -L 1 {}' --margin=0% \
    --color fg:#cdcecf,bg:#2a2f38,gutter:#2a2f38,hl:#f6a878,hl+:#f6a878,bg+:#283648 \
    --with-nth=-2.. --delimiter="/" < "$PROJECTS_LIST")

  echo "$target"
}

# create a tmux session
_create_session() {
  path="$1"
  session_name="$2"

  # the sessionizer script; legacy .project files are migrated to .pj
  [ -x "$path/.project" ] && mv "$path/.project" "$path/.pj"

  setup=""
  [ -x "$path/.pj" ] && setup="$path/.pj"

  # a file with enviroment variables, with the following specs:
  # entries are formatted as ENV_VARIABLE=myValue
  # comments start with a '#' on a new line.
  env="$path/.env"

  # accumulate the tmux argv safely (no eval): each -e VAR=value is one argument
  set -- new-session -ds "$session_name" -c "$path"
  if [ -e "$env" ]; then
    # strip comments and blank lines from the env file
    while IFS= read -r var; do
      [ -n "$var" ] || continue
      set -- "$@" -e "$var"
    done <<EOF
$(sed -E '/^(#.*)?$/d' "$env")
EOF
  fi

  # run tmux with the commands
  tmux "$@"

  # execute the setup script
  [ -x "$setup" ] && "$setup" "$session_name" "$path"

  # ensures continuity of script. Why?
  echo
}

# go to the selected target session
_goto_session() {
  session_name="$1"

  # if we are in a tmux session, switch to the session, otherwise attach to the
  # session

  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$session_name"
  else
    tmux attach-session -t "$session_name"
  fi
}

# start a session or switch to one.
_sessionize() {
  target=$(_select_target)
  session_name=$(basename "$target" | sed -E "s/^(\.)+//; s/\./_/g")

  # create a session if it does not exist
  if ! tmux has -t "$session_name" 2>/dev/null; then
    _create_session "$target" "$session_name"
  fi

  _goto_session "$session_name"
}

main() {
  _sessionize
}

refresh() {
  _generate_list
}

init() {
  app_start "$@"
}

init "$@"
