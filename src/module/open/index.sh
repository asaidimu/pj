# --------
# summary: Initialises the environment for a project
# --------

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

  # a script that takes the two params above. Use them as you may
  # TODO: deprecate .project in favor of .pj
  setup="$path/.project"

  # migrate from .project to .pj
  [ -x "$path/.project" ] && mv "$path/.project" "$path/.pj"

  [ -x "$path/.pj" ] && setup="$path/.pj" || setup=""

  # a file with enviroment variables, with the following specs:
  # entries are formatted as ENV_VARIABLE=myValue
  # comments start with a '#' on a new line.
  env="$path/.env"

  cmd="new-session -ds $session_name -c $path"
  tmp_cmd="$FRAMEWORK_TMP/tmux.cmd"

  echo "$cmd" > "$tmp_cmd"
  # build the tmux options add env variables
  if [ -e "$env" ]; then
    # strip comments and blank lines from the env file
    sed -E '/^(#.*)?$/d; s/^(.*)(=)(.*)$/\1\2"\3"/g;' "$env" | while IFS= read -r var; do
      cmd="$cmd -e $var"
      echo "$cmd" > "$tmp_cmd"
    done
  fi

  # run tmux with the commands
  eval "tmux $(cat "$tmp_cmd")"

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

help() {
  cat <<EOF
$(bold ABOUT)
    $(bold "$FRAMEWORK_NAME $FRAMEWORK_VERSION")
$(bold "COMMAND"): $(blue open)
    initialises the environment for a project

$(bold USAGE)
    $FRAMEWORK_NAME
    $FRAMEWORK_NAME <command>

$(bold "AVAILABE COMMANDS")
    refresh               (re)generates list of projects

$(bold EXAMPLE)
    $(prompt "pj open")
    $(prompt "pj open refresh")
EOF
}

init() {
  option="$*"
  case "$option" in
    help)
      help
      ;;
    refresh)
      _generate_list
      ;;
    "" )
      _sessionize
      ;;
    * )
      help
      exit 1
      ;;
  esac
}

init "$@"
