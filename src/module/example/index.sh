# --------
# summary: example module
# --------
# @about   says hello world
# @usage   pj example

main() {
  printf "Hello, World!\n"
}

init() {
  app_start "$@"
}

init "$@"
