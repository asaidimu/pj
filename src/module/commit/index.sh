#!/bin/sh

# --------
# summary: generate a conventional commit message
# --------

PLUGIN_DIR="$FRAMEWORK_ROUTE/commit"

help() {
  cat <<EOF
$(bold ABOUT)
    $(bold "$FRAMEWORK_NAME $FRAMEWORK_VERSION")

$(bold "COMMAND"): $(blue commit)
    Generates a conventional commit message using Google Gemini 2.5 Flash based on git diff and an optional documentation file.
    Requires GEMINI_API_KEY, FRAMEWORK_NAME, and FRAMEWORK_VERSION environment variables.
    Requires Bun to run the TypeScript plugin.
    Requires git to be installed and a git repository to be initialized.

$(bold USAGE)
    $FRAMEWORK_NAME commit [directory] [-s|--staged] [-t|--type <commit-type>] [-d|--docs <file>]

$(bold OPTIONS)
    directory          Path to the git repository (default: current directory)
    -s, --staged       Use staged changes (git diff --staged) instead of unstaged changes
    -t, --type         Specify the commit type (e.g., feat, fix, docs, chore; default: inferred by Gemini)
    -d, --docs         Documentation file to include for context (default: README.md)

$(bold EXAMPLE)
    $(prompt "$FRAMEWORK_NAME commit ~/projects/myproject -s -t feat -d README.md")
EOF
  exit 0
}

init() {
  # Check if FRAMEWORK_NAME is set
  if [ -z "$FRAMEWORK_NAME" ]; then
    printf "Error: FRAMEWORK_NAME environment variable not set\n" >&2
    exit 1
  fi

  # Check if FRAMEWORK_VERSION is set
  if [ -z "$FRAMEWORK_VERSION" ]; then
    printf "Error: FRAMEWORK_VERSION environment variable not set\n" >&2
    exit 1
  fi

  # Check if Bun is installed
  if ! command -v bun >/dev/null 2>&1; then
    printf "Error: 'bun' is required to run the commit plugin\n" >&2
    exit 1
  fi

  # Check if git is installed
  if ! command -v git >/dev/null 2>&1; then
    printf "Error: 'git' is required to run the commit plugin\n" >&2
    exit 1
  fi

  # Check if main.ts exists
  if [ ! -f "$PLUGIN_DIR/main.ts" ]; then
    printf "Error: 'main.ts' not found in %s\n" "$PLUGIN_DIR" >&2
    exit 1
  fi

  case "$1" in
    help)
      help
      ;;
    *)
      # Delegate to Bun script, passing all arguments and output file
      bun "$PLUGIN_DIR/main.ts" "$@"
      status=$?
      if [ $status -ne 0 ]; then
        printf "Error: Commit message generation failed with status %d\n" "$status" >&2
        exit $status
      fi

      # Display the output file
      output_file=".commit-message.md"
      if [ -f "$output_file" ]; then
        if command -v glow >/dev/null 2>&1; then
          glow -p "$output_file"
        else
          less "$output_file"
        fi
        printf "Commit message saved to %s\n" "$output_file"
      else
        printf "Error: Output file %s not found\n" "$output_file" >&2
        exit 1
      fi
      ;;
  esac
}

init "$@"
