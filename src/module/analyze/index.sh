#!/bin/sh

# --------
# summary: analyze codebase
# --------

PLUGIN_DIR="$CUSTOM_PLUGINS_PATH/analyze"

help() {
  cat <<EOF
$(bold ABOUT)
    $(bold "$FRAMEWORK_NAME $FRAMEWORK_VERSION")

$(bold "COMMAND"): $(blue analyze)
    Analyzes a codebase using Google Gemini 2.5 Flash and displays results with glow (or less).
    Requires GEMINI_API_KEY environment variable. Requires Bun to run the TypeScript plugin.

$(bold USAGE)
    $FRAMEWORK_NAME analyze [directory] [-f|--files <pattern>] [-x|--exclude <pattern>]

$(bold OPTIONS)
    directory          Path to the codebase directory (default: current directory)
    -f, --files        Files or glob patterns to include (e.g., "*.py *.js", "src/*/**/*.ts")
    -x, --exclude      Files or directories to exclude (e.g., "node_modules *.log", "tests/**")

$(bold EXAMPLE)
    $(prompt "$FRAMEWORK_NAME analyze ~/projects/myproject -f 'src/*/**/*.{ts,js,jsx,tsx,.d.ts}' -x 'node_modules tests/**'")
EOF
  exit 0
}

init() {
  # Check if Bun is installed
  if ! command -v bun >/dev/null 2>&1; then
    printf "Error: 'bun' is required to run the analyze plugin\n" >&2
    exit 1
  fi

  # Check if main.ts exists
  if [ ! -f "$PLUGIN_DIR/main.ts" ]; then
    printf "Error: 'main.ts' not found in %s\n" "$PLUGIN_DIR" >&2
    exit 1
  fi

  # Generate output file name
  output_file=`mktemp /tmp/pj-analyze.XXXXXX.md`

  case "$1" in
    help)
      help
      ;;
    *)
      # Delegate to Bun script, passing all arguments and output file
      bun "$PLUGIN_DIR/main.ts" --output "$output_file" "$@"
      status=$?
      if [ $status -ne 0 ]; then
        printf "Error: Analysis failed with status %d\n" "$status" >&2
        exit $status
      fi

      # Display the output file
      if [ -f "$output_file" ]; then
        if command -v glow >/dev/null 2>&1; then
          glow -p "$output_file"
        else
          less "$output_file"
        fi
        printf "Analysis saved to %s\n" "$output_file"
      else
        printf "Error: Output file %s not found\n" "$output_file" >&2
        exit 1
      fi
      ;;
  esac
}

init "$@"

