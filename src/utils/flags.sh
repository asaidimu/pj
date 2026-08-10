#!/bin/sh
# src/utils/flags.sh - global flag parsing

# -- flag state (reset on every run) --
export FLAG_SILENT=0
export FLAG_OVERWRITE=0

# Colors default to on when stdout is a terminal, off otherwise.
# --no-color forces them off; --color forces them on.
if [ -t 1 ]; then
  export FLAG_COLORED_OUTPUT=1
else
  export FLAG_COLORED_OUTPUT=0
fi

# sentinel returned by parse_flag for non-flag arguments
NOT_A_FLAG=997

parse_flag() {
  case "$1" in
    -s|--silent)
      export FLAG_SILENT=1
      return 0
      ;;
    -o|--overwrite)
      export FLAG_OVERWRITE=1
      return 0
      ;;
    --color)
      export FLAG_COLORED_OUTPUT=1
      return 0
      ;;
    --no-color)
      export FLAG_COLORED_OUTPUT=0
      return 0
      ;;
    -h|--help)
      global_help
      exit
      ;;
    -v|--version)
      show_version
      exit
      ;;
    *)
      return $NOT_A_FLAG
      ;;
  esac
}
