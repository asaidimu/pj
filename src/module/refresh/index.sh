# --------
# summary: (re)generates list of projects
# --------

help() {
cat <<EOF
$(bold ABOUT)
    $(bold "$FRAMEWORK_NAME $FRAMEWORK_VERSION")

$(bold "COMMAND"): $(blue refresh)
    (re)generates list of projects

$(bold USAGE)
    $FRAMEWORK_NAME refresh

$(bold EXAMPLE)
    $(prompt "${FRAMEWORK_NAME} refresh")
EOF
}

init() {
  option="$*"
  case "$option" in
    help)
      help
      ;;
    "" )
      _generate_list
      ;;
    * )
      help
      exit 1
      ;;
  esac
}

init "$@"
