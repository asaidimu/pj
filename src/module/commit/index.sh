#!/bin/sh
# --------
# summary: generate a conventional commit message
# completion: analysis
# requires: bun git
# --------
# @about   generate a conventional commit message with Google Gemini
# @usage   pj commit [directory]
# @flag    -s, --staged       use staged changes instead of unstaged
# @flag    -t, --type=<type>  commit type (feat, fix, docs, ...; default: inferred)
# @flag    -d, --docs=<file>  documentation file for context (default: README.md)
# @requires bun git
# @arg     [<directory>]      path to the git repository (default: current directory)

PLUGIN_DIR="$FRAMEWORK_ROUTE/commit"

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
  [ -n "${OPT_TYPE:-}" ] && set -- --type "$OPT_TYPE" "$@"
  [ -n "${OPT_DOCS:-}" ] && set -- --docs "$OPT_DOCS" "$@"
  [ -n "${OPT_STAGED:-}" ] && set -- --staged "$@"

  bun "$PLUGIN_DIR/main.ts" "$@"
  status=$?
  if [ $status -ne 0 ]; then
    printf "Error: Commit message generation failed with status %d\n" "$status" >&2
    exit $status
  fi

  # Display the output file
  output_file=".commit-message.md"
  if [ -f "$output_file" ]; then
    _show "$output_file"
    printf "Commit message saved to %s\n" "$output_file"
  else
    printf "Error: Output file %s not found\n" "$output_file" >&2
    exit 1
  fi
}

init() {
  app_start "$@"
}

init "$@"
