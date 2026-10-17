# --------
# summary: inspect and verify framework environment variables
# completion: none
# --------
# @about   inspect and verify framework environment variables
# @usage   pj env [check]
# @route   list   list variables with values and descriptions
# @route   check  verify all variables (exit code = issue count)
# @default list

list() {
  bold ENVIRONMENT
  while IFS='|' read -r _n _k _s _d; do
    [ -n "$_n" ] || continue
    eval "_v=\${$_n}"
    case "$_n" in
      *KEY*|*TOKEN*|*SECRET*|*PASSWORD*) _v="****";;
    esac
    printf "\n    %-26s %s" "$_n" "$_v"
    printf "\n    %-26s %s (%s, %s)" "" "$_d" "$_k" "$_s"
  done <<EOF
$FRAMEWORK_ENV_TABLE
EOF
  printf "\n"
}

check() {
  env_verify
  _rc=$?
  if [ "$_rc" -eq 0 ]; then
    success "environment ok ($(printf '%s' "$FRAMEWORK_ENV_TABLE" | grep -c .) variables checked)"
  fi
  return "$_rc"
}

init() {
  app_start "$@"
}

init "$@"
