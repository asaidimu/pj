# --------
# summary: (re)generates list of projects
# --------
# @about   (re)generates list of projects
# @usage   pj refresh

main() {
  [ $# -eq 0 ] || { app_help; exit 1; }
  _generate_list
}

init() {
  app_start "$@"
}

init "$@"
