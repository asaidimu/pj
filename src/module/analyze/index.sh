#!/bin/sh
# @about        analyze a codebase with Google Gemini
# @usage        pj analyze [directory]
# @completion   analysis
# @flag         -f, --files=<pattern>    glob patterns to include
# @flag         -x, --exclude=<pattern>  files or directories to exclude
# @requires     bun
# @arg          [<directory>]            path to the codebase (default: current directory)

PLUGIN_DIR="$FRAMEWORK_ROUTE/analyze"

main() {
  # forward pragma-parsed flags to the Bun side; positionals stay as-is
  [ -n "${OPT_FILES:-}" ] && set -- --files "$OPT_FILES" "$@"
  [ -n "${OPT_EXCLUDE:-}" ] && set -- --exclude "$OPT_EXCLUDE" "$@"

  agent_run "$PLUGIN_DIR/main.ts" ".analysis.md" \
    "Analysis" "Analysis" "$@"
}

init() {
  app_start "$@"
}

init "$@"
