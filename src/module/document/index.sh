#!/bin/sh
# --------
# summary: generate a standard project README
# completion: analysis
# requires: bun
# --------
# @about   generate a standard project README with Google Gemini
# @usage   pj document [directory]
# @flag    -f, --files=<pattern>    glob patterns to include
# @flag    -x, --exclude=<pattern>  files or directories to exclude
# @requires bun
# @arg     [<directory>]            path to the codebase (default: current directory)

PLUGIN_DIR="$FRAMEWORK_ROUTE/document"

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

  # forward pragma-parsed flags to the Bun side; positionals stay as-is
  [ -n "${OPT_FILES:-}" ] && set -- --files "$OPT_FILES" "$@"
  [ -n "${OPT_EXCLUDE:-}" ] && set -- --exclude "$OPT_EXCLUDE" "$@"

  bun "$PLUGIN_DIR/main.ts" "$@"
  status=$?
  if [ $status -ne 0 ]; then
    printf "Error: README generation failed with status %d\n" "$status" >&2
    exit $status
  fi

  # Display the output file
  output_file=".readme.md"
  if [ -f "$output_file" ]; then
    _show "$output_file"
    printf "README saved to %s\n" "$output_file"
  else
    printf "Error: Output file %s not found\n" "$output_file" >&2
    exit 1
  fi
}

init() {
  app_start "$@"
}

init "$@"
