#!/bin/sh

# --------
# summary: generate a standard project README
# --------

PLUGIN_DIR="$CUSTOM_PLUGINS_PATH/document"

help() {
  cat <<EOF
$(bold ABOUT)
    $(bold "$FRAMEWORK_NAME $FRAMEWORK_VERSION")

$(bold "COMMAND"): $(blue document)
    Generates a standard, informative README based on the codebase using Google Gemini 2.5 Flash.
    Requires GEMINI_API_KEY
    Requires Bun to run the TypeScript plugin.

$(bold USAGE)
    $FRAMEWORK_NAME document [directory] [-f|--files <pattern>] [-x|--exclude <pattern>]

$(bold OPTIONS)
    directory          Path to the codebase directory (default: current directory)
    -f, --files        Files or glob patterns to include (e.g., "*.py *.js", "src/*/**/*.ts")
    -x, --exclude      Files or directories to exclude (e.g., "node_modules *.log", "tests/**")

$(bold EXAMPLE)
    $(prompt "$FRAMEWORK_NAME document ~/projects/myproject -f 'src/*/**/*.{ts,js,jsx,tsx}' -x 'node_modules tests/**'")
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
    printf "Error: 'bun' is required to run the document plugin\n" >&2
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
      # Delegate to Bun script, passing all arguments
      bun "$PLUGIN_DIR/main.ts" "$@"
      status=$?
      if [ $status -ne 0 ]; then
        printf "Error: README generation failed with status %d\n" "$status" >&2
        exit $status
      fi

      # Display the output file
      output_file=".readme.md"
      if [ -f "$output_file" ]; then
        if command -v glow >/dev/null 2>&1; then
          glow -p "$output_file"
        else
          less "$output_file"
        fi
        printf "README saved to %s\n" "$output_file"
      else
        printf "Error: Output file %s not found\n" "$output_file" >&2
        exit 1
      fi
      ;;
  esac
}

init "$@"
