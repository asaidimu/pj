#!/bin/sh
# --------
# summary: analyze codebase
# completion: analysis
# requires: bun
# --------
# @about   analyze a codebase with Google Gemini
# @usage   pj analyze [directory]
# @flag    -f, --files=<pattern>    glob patterns to include
# @flag    -x, --exclude=<pattern>  files or directories to exclude
# @requires bun
# @arg     [<directory>]            path to the codebase (default: current directory)

PLUGIN_DIR="$FRAMEWORK_ROUTE/analyze"

_show() {
  if command -v glow >/dev/null 2>&1; then
    glow -p "$1"
  else
    less "$1"
  fi
}

main() {
  if [ ! -f "$PLUGIN_DIR/main.ts" ]; then
    printf "Error: 'main.ts' not found in %s\n" "$PLUGIN_DIR" >&2
    exit 1
  fi

  output_file=$(mktemp "$FRAMEWORK_TMP/pj-analyze.XXXXXX")

  # forward pragma-parsed flags to the Bun side; positionals stay as-is
  [ -n "${OPT_FILES:-}" ] && set -- --files "$OPT_FILES" "$@"
  [ -n "${OPT_EXCLUDE:-}" ] && set -- --exclude "$OPT_EXCLUDE" "$@"

  bun "$PLUGIN_DIR/main.ts" --output "$output_file" "$@"
  status=$?
  if [ $status -ne 0 ]; then
    printf "Error: Analysis failed with status %d\n" "$status" >&2
    exit $status
  fi

  if [ -f "$output_file" ]; then
    _show "$output_file"
    printf "Analysis saved to %s\n" "$output_file"
  else
    printf "Error: Output file %s not found\n" "$output_file" >&2
    exit 1
  fi
}

init() {
  app_start "$@"
}

init "$@"
