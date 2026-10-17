#!/bin/sh
# src/utils/flags.sh - global flag state
#
# Global flags are consumed by run_command (src/index.sh) BEFORE the
# command word: -s/--silent, -o/--overwrite, --color/--no-color,
# -h/--help, -v/--version. After the command word every flag belongs to
# the module itself (e.g. `pj commit -s` is --staged, `pj analyze -x`
# is --exclude), so there is no ambiguity to resolve.

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
