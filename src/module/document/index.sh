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

main() {
  # forward pragma-parsed flags to the Bun side; positionals stay as-is
  [ -n "${OPT_FILES:-}" ] && set -- --files "$OPT_FILES" "$@"
  [ -n "${OPT_EXCLUDE:-}" ] && set -- --exclude "$OPT_EXCLUDE" "$@"

  agent_run "$PLUGIN_DIR/main.ts" ".readme.md" \
    "README generation" "README" "$@"
}

init() {
  app_start "$@"
}

init "$@"
