export FRAMEWORK_REQUIRED_DEPS="sh mkdir ls cat date sed awk grep tr wc sleep find xargs sort uniq mktemp mv rm cp chmod basename dirname printf echo read"

module_requires() (
  [ -f "$1" ] || exit 0
  awk 'tolower($0) ~ /^#[ \t]*requires[ \t]*:/ {
         sub(/^[^:]*:[ \t]*/, "")
         print
         exit
       }' "$1"
)

deps_missing() (
  _found=""
  for _dep in "$@"; do
    [ -n "$_dep" ] || continue
    command -v "$_dep" >/dev/null 2>&1 || _found="$_found $_dep"
  done
  printf '%s' "${_found# }"
)

missing_required() (
  deps_missing $FRAMEWORK_REQUIRED_DEPS
)

warn_missing_deps() (
  _wname="$1"
  _wfile="$2"
  _wreq=$(module_requires "$_wfile")
  [ -n "$_wreq" ] || exit 0
  _wmiss=$(deps_missing $_wreq)
  [ -n "$_wmiss" ] || exit 0
  if command -v warn >/dev/null 2>&1; then
    warn "$_wname needs $_wmiss but $_wmiss is not installed (expect failures)"
  else
    printf 'warning: %s needs %s but it is not installed\n' "$_wname" "$_wmiss" >&2
  fi
  exit 0
)
