#!/bin/sh
# src/utils/env_check.sh - validate the environment after the user config loads

# -- create runtime directories --
mkdir -p "$PROJECTS_PATH" \
  "$FRAMEWORK_CONFIG_DIR" \
  "$FRAMEWORK_TMP" \
  "$FRAMEWORK_DATA" \
  "$ARCHIVE_PATH" \
  || panic "cannot create runtime directories" "$ERROR_MISSING_COMMAND"

# Verify every variable declared with env_set: it must be set, non-empty,
# and match its declared kind (dir exists, file exists, num is numeric).
# Prints one warning per problem and returns the issue count; pass -q to
# suppress the warnings (startup uses -q, "pj env check" prints them).
env_verify() {
  _env_quiet=""
  [ "$1" = "-q" ] && _env_quiet=1
  _env_issues=0
  while IFS='|' read -r _env_n _env_k _env_s _env_d; do
    [ -n "$_env_n" ] || continue
    eval "_env_v=\${$_env_n}"
    if [ -z "$_env_v" ]; then
      [ -n "$_env_quiet" ] || warn "$_env_n is empty — ${_env_d}"
      _env_issues=$((_env_issues + 1))
      continue
    fi
    case "$_env_k" in
      dir)
        [ -d "$_env_v" ] || {
          [ -n "$_env_quiet" ] || warn "$_env_n is not a directory: $_env_v"
          _env_issues=$((_env_issues + 1))
        }
        ;;
      file)
        [ -e "$_env_v" ] || {
          [ -n "$_env_quiet" ] || warn "$_env_n not found: $_env_v"
          _env_issues=$((_env_issues + 1))
        }
        ;;
      num)
        case "$_env_v" in
          *[!0-9]*)
            [ -n "$_env_quiet" ] || warn "$_env_n is not a number: $_env_v"
            _env_issues=$((_env_issues + 1))
            ;;
        esac
        ;;
    esac
  done <<EOF
$FRAMEWORK_ENV_TABLE
EOF
  return $_env_issues
}

# -- required tools (module-specific tools only warn, see deps.sh) --
if [ -n "$(missing_required)" ]; then
  panic "required tools not found: $(missing_required)" "$ERROR_MISSING_COMMAND"
fi

# -- every declared environment variable --
# `pj env` / `pj env check` are allowed through so they can list problems
# and exit with their own status; everything else fails fast.
_env_issues=0
env_verify -q || _env_issues=$?
if [ "$_env_issues" -ne 0 ]; then
  if [ "$1" = "env" ]; then
    :
  else
    panic "invalid environment ($_env_issues issues) — run: pj env check" "$ERROR_MISSING_COMMAND"
  fi
fi
