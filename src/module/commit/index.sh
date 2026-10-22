#!/bin/sh
# @about        generate a conventional commit message with Google Gemini
# @usage        pj commit [directory]
# @completion   analysis
# @flag         -s, --staged       use staged changes instead of unstaged
# @flag         -t, --type=<type>  commit type (feat, fix, docs, ...; default: inferred)
# @flag         -d, --docs=<file>  documentation file for context (default: README.md)
# @requires     bun git
# @arg          [<directory>]      path to the git repository (default: current directory)

PLUGIN_DIR="$FRAMEWORK_ROUTE/commit"

main() {
  # forward pragma-parsed flags to the Bun side; positionals stay as-is
  [ -n "${OPT_TYPE:-}" ] && set -- --type "$OPT_TYPE" "$@"
  [ -n "${OPT_DOCS:-}" ] && set -- --docs "$OPT_DOCS" "$@"
  [ -n "${OPT_STAGED:-}" ] && set -- --staged "$@"

  agent_run "$PLUGIN_DIR/main.ts" ".commit-message.md" \
    "Commit message generation" "Commit message" "$@"
}

init() {
  app_start "$@"
}

init "$@"
