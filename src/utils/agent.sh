# src/utils/agent.sh - shared shell helper for the Gemini agent modules
#
# The agent modules (commit, analyze, document) are the same shell with
# custom hydration. Their index.sh keeps the pragma header (CLI surface),
# forwards module-specific flags, then hands off to agent_run. User
# plugins building their own Gemini-backed commands can do the same:
#
#   . "$UTILITIES_PATH/agent.sh"    # already sourced by the bootstrap
#   main() {
#     [ -n "${OPT_FOO:-}" ] && set -- --foo "$OPT_FOO" "$@"
#     agent_run "$PLUGIN_DIR/main.ts" ".foo.md" "Foo failed" "Foo" "$@"
#   }
#   init() { app_start "$@"; }
#   init "$@"

# Display a file with a pager: glow if available, else less
agent_show() {
  if command -v glow >/dev/null 2>&1; then
    glow -p "$1"
  else
    less "$1"
  fi
}

# agent_run MAIN_TS OUTPUT ERR_LABEL OK_LABEL [args...]
#   Run the module's bun entry point, then show and report the output
#   file. The output file is written (and looked for) in the current
#   working directory — the artifact lands where you ran the command.
agent_run() {
  _agent_main="$1"
  _agent_out="$2"
  _agent_err="$3"
  _agent_ok="$4"
  shift 4

  if [ ! -f "$_agent_main" ]; then
    printf "Error: 'main.ts' not found in %s\n" "${_agent_main%/*}" >&2
    exit 1
  fi

  bun "$_agent_main" "$@"
  _agent_status=$?
  if [ "$_agent_status" -ne 0 ]; then
    printf "Error: %s failed with status %d\n" "$_agent_err" "$_agent_status" >&2
    exit "$_agent_status"
  fi

  if [ -f "$_agent_out" ]; then
    agent_show "$_agent_out"
    printf "%s saved to %s\n" "$_agent_ok" "$_agent_out"
  else
    printf "Error: Output file %s not found\n" "$_agent_out" >&2
    exit 1
  fi
}
