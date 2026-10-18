#!/bin/sh
# tests/run.sh - POSIX test harness for pj
#
# Runs the pj framework across every available POSIX shell in an isolated
# sandbox (fresh $HOME, fresh $PROJECTS_PATH) and asserts exit codes and
# key outputs.
#
# Usage:
#   sh tests/run.sh                # all available shells
#   sh tests/run.sh bash zsh       # specific shells

set -u

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BOOTSTRAP="$REPO_ROOT/src/bootstrap.sh"

# ---- shell discovery --------------------------------------------------------

SHELLS="sh"
command -v bash >/dev/null 2>&1 && SHELLS="$SHELLS bash"
command -v zsh  >/dev/null 2>&1 && SHELLS="$SHELLS zsh"

# bash in POSIX mode is a reasonable dash stand-in when dash is absent
if command -v dash >/dev/null 2>&1; then
  SHELLS="$SHELLS dash"
else
  SHELLS="$SHELLS bash_posix"
fi
command -v ksh >/dev/null 2>&1 && SHELLS="$SHELLS ksh"

if [ $# -gt 0 ]; then
  SHELLS="$*"
fi

# ---- sandbox ----------------------------------------------------------------

SANDBOX_ROOT=$(mktemp -d)
trap 'rm -rf "$SANDBOX_ROOT"' 0
trap 'rm -rf "$SANDBOX_ROOT"; exit 1' 1 2 15

# make_sandbox [project ...]  ->  sets SANDBOX
SANDBOX_N=0
make_sandbox() {
  SANDBOX_N=$((SANDBOX_N + 1))
  SANDBOX="$SANDBOX_ROOT/$SANDBOX_N"
  mkdir -p "$SANDBOX/home/projects"
  for p in "$@"; do
    mkdir -p "$SANDBOX/home/projects/$p"
  done
}

# run_shell shell args... -> execute pj with the given shell
run_shell() {
  _shell="$1"; shift
  case "$_shell" in
    bash_posix) bash --posix "$BOOTSTRAP" "$@" ;;
    *)          "$_shell" "$BOOTSTRAP" "$@" ;;
  esac
}

# pj shell args... -> run in sandbox, capture stdout/stderr into SANDBOX
pj() {
  _shell="$1"; shift
  (
    cd "$SANDBOX"
    HOME="$SANDBOX/home" \
    PROJECTS_PATH="$SANDBOX/home/projects" \
    FRAMEWORK_NAME="pj" \
    FRAMEWORK_PATH="$REPO_ROOT" \
    FRAMEWORK_VERSION="v-test" \
    run_shell "$_shell" "$@" >"$SANDBOX/out" 2>"$SANDBOX/err"
  )
  return $?
}

# ---- assertions --------------------------------------------------------------

PASS=0
FAIL=0
FAILED=""

assert_exit() {
  _want="$1"; _got="$2"; _name="$3"
  if [ "$_want" -eq "$_got" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    $_name: expected exit $_want, got $_got\n"
    FAILED="$FAILED        stderr: $(sed 's/^/        /' "$SANDBOX/err" 2>/dev/null | tr '\n' ' ')\n"
  fi
}

assert_out() {
  _needle="$1"; _name="$2"
  if grep -q -- "$_needle" "$SANDBOX/out" 2>/dev/null; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    $_name: stdout missing \"$_needle\"\n"
    FAILED="$FAILED        stderr: $(sed 's/^/        /' "$SANDBOX/err" 2>/dev/null | tr '\n' ' ')\n"
  fi
}

assert_file() {
  _file="$1"; _name="$2"
  if [ -e "$_file" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    $_name: expected file $_file\n"
  fi
}

# ---- tests -------------------------------------------------------------------

# list
t_list_ok() {
  make_sandbox alpha
  pj "$1" list; assert_exit 0 $? "list ok"
  assert_out "alpha" "list shows project"
}

t_list_empty_ok() {
  make_sandbox
  pj "$1" list; assert_exit 0 $? "list empty ok"
}

# help
t_help_ok() {
  make_sandbox
  pj "$1" help; assert_exit 0 $? "help ok"
  assert_out "list" "help lists modules"
}

t_module_help() {
  make_sandbox
  pj "$1" new help; assert_exit 0 $? "module help ok"
  assert_out "new" "module help names module"
}

# dispatch / errors
t_unknown_command() {
  make_sandbox
  pj "$1" bogus; assert_exit 7 $? "unknown command is illegal op"
}

t_unknown_flag() {
  make_sandbox
  pj "$1" --bogus list; assert_exit 6 $? "unknown global flag is an error"
  assert_out "unknown flag" "unknown flag message"
  pj "$1" new --script x; assert_exit 0 $? "module flags after command still work"
}

t_help_extended() {
  make_sandbox
  pj "$1" help --extended; assert_exit 0 $? "help extended rc"
  assert_out "HOMEPAGE" "extended shows homepage"
  assert_out "REPOSITORY" "extended shows repository"
  assert_out "AUTHOR" "extended shows author"
  assert_out "LICENSE" "extended shows license"
  pj "$1" help -x; assert_exit 0 $? "help -x rc"
}

t_module_pragma() {
  make_sandbox
  pj "$1" env help; assert_exit 0 $? "pragma module help rc"
  assert_out "USAGE" "pragma module help shows usage"
  assert_out "check" "pragma module help lists routes"
  pj "$1" env bogus; assert_exit 1 $? "pragma unknown route rc"
  assert_out "unknown command" "pragma unknown route message"
  pj "$1" refresh extra; assert_exit 1 $? "refresh rejects extra args"
  pj "$1" archive; assert_exit 1 $? "archive missing arg rc"
  assert_out "required" "archive names the missing arg"
  pj "$1" example; assert_exit 0 $? "example module rc"
  assert_out "Hello, World!" "example module runs"
}

t_new_module() {
  make_sandbox
  pj "$1" new --module greet; assert_exit 0 $? "new --module rc"
  _m="$SANDBOX/home/.config/pj/plugins/greet/index.sh"
  assert_file "$_m" "module scaffolded"
  if grep -q "summary: greet module" "$_m"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    new --module: summary not substituted\n"
  fi
  if grep -q "__NAME__" "$_m"; then
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    new --module: placeholder left in file\n"
  else
    PASS=$((PASS + 1))
  fi
  pj "$1" greet; assert_exit 0 $? "scaffolded module runs"
  assert_out "Hello from greet!" "scaffolded module output"
  pj "$1" new --module greet; assert_exit 3 $? "refuses overwrite"
  pj "$1" new -o --module greet; assert_exit 0 $? "overwrite with -o"
  pj "$1" new --module; assert_exit 1 $? "bare --module errors"
  pj "$1" new --module='../evil' x; assert_exit 2 $? "rejects path in name"
  pj "$1" new --module=two; assert_exit 0 $? "--module=name form"
  assert_file "$SANDBOX/home/.config/pj/plugins/two/index.sh" "module=name form scaffolded"
}

t_new_no_args() {
  make_sandbox
  pj "$1" new; assert_exit 2 $? "new with no args"
}

# --names is the machine-readable list the completions consume
t_new_names() {
  make_sandbox
  pj "$1" new --names; assert_exit 0 $? "new --names ok"
  assert_out "base" "new --names lists base"
}

t_new_bad_recipe() {
  make_sandbox
  pj "$1" new doesnotexist x; assert_exit 5 $? "unknown recipe"
}

t_new_creates_project() {
  make_sandbox
  pj "$1" new base beta; assert_exit 0 $? "new base beta"
  assert_file "$SANDBOX/home/projects/beta/README.md" "project README created"
}

t_new_existing_no_overwrite() {
  make_sandbox
  pj "$1" new base beta
  pj "$1" new base beta; assert_exit 3 $? "existing project without overwrite"
}

t_new_existing_overwrite() {
  make_sandbox
  pj "$1" new base beta
  pj "$1" -o new base beta; assert_exit 0 $? "existing project with -o"
}

t_archive_ok() {
  make_sandbox alpha
  pj "$1" archive alpha; assert_exit 0 $? "archive alpha"
  assert_file "$SANDBOX/home/projects/.pj/archives" "archive dir exists"
}

t_archive_missing() {
  make_sandbox
  pj "$1" archive ghost; assert_exit 8 $? "archive missing project"
}

t_delete_missing() {
  make_sandbox
  pj "$1" delete ghost; assert_exit 8 $? "delete missing project"
}

t_list_missing() {
  make_sandbox
  pj "$1" list ghost; assert_exit 8 $? "list missing project"
}

# refresh + generator
t_refresh_ok() {
  make_sandbox
  pj "$1" new base alpha >/dev/null 2>&1
  pj "$1" refresh; assert_exit 0 $? "refresh ok"
  assert_file "$SANDBOX/home/.config/pj/data/projects" "project list written"
}

# flags
t_version() {
  make_sandbox
  pj "$1" --version; assert_exit 0 $? "version flag"
}

t_flag_silent() {
  make_sandbox alpha
  pj "$1" -s list; assert_exit 0 $? "silent flag still runs"
}

# bare `pj` (no command) defaults to open; the dispatcher must not shift
# an empty argv on the way there
t_bare_defaults_to_open() {
  make_sandbox alpha
  pj "$1" >/dev/null 2>&1
  _bare=$?
  _bare_err=$(cat "$SANDBOX/err" 2>/dev/null)
  pj "$1" open >/dev/null 2>&1
  _open=$?
  assert_exit "$_open" "$_bare" "bare pj matches pj open"
  case "$_bare_err" in
    *shift*) FAIL=$((FAIL + 1)); FAILED="$FAILED    bare pj: stderr must not mention shift: $_bare_err\n";;
    *) PASS=$((PASS + 1));;
  esac
}

# hooks: pre_hook runs in the command shell (exports visible), post_hooks
# all run — a core hook calling `exit` must not skip the user hook — and
# post_hooks run even when the module fails, preserving its status
t_hooks() {
  make_sandbox
  mkdir -p "$SANDBOX/home/.config/pj/plugins/new" "$SANDBOX/home/.config/pj/plugins/fail"

  printf 'echo USER-NEW-PRE\n' > "$SANDBOX/home/.config/pj/plugins/new/pre_hook.sh"
  printf 'echo USER-NEW-POST\n' > "$SANDBOX/home/.config/pj/plugins/new/post_hook.sh"
  pj "$1" new base beta
  assert_out "USER-NEW-PRE" "user pre_hook runs for core command"
  assert_out "USER-NEW-POST" "user post_hook runs alongside exiting core hook"
  assert_file "$SANDBOX/home/.config/pj/data/projects" "core new post_hook still refreshes"

  cat > "$SANDBOX/home/.config/pj/plugins/fail/index.sh" <<'EOF'
#!/bin/sh
# summary: fails on purpose
main() {
  echo "state=${HOOK_STATE:-unset}"
  return 1
}
app_start "$@"
EOF
  printf 'export HOOK_STATE=from-pre\n' > "$SANDBOX/home/.config/pj/plugins/fail/pre_hook.sh"
  printf 'touch "$HOME/.config/pj/post-ran"\n' > "$SANDBOX/home/.config/pj/plugins/fail/post_hook.sh"
  pj "$1" fail
  assert_exit 1 $? "failing module status preserved"
  assert_out "state=from-pre" "pre_hook export reaches the module"
  assert_file "$SANDBOX/home/.config/pj/post-ran" "post_hook runs after module failure"
}

# default paths (Phase 1: PROJECTS_PATH defaults to $HOME/projects)
t_default_paths() {
  make_sandbox alpha
  (
    cd "$SANDBOX"
    unset PROJECTS_PATH
    HOME="$SANDBOX/home" \
    FRAMEWORK_NAME="pj" \
    FRAMEWORK_PATH="$REPO_ROOT" \
    FRAMEWORK_VERSION="v-test" \
    run_shell "$1" list >"$SANDBOX/out" 2>"$SANDBOX/err"
  )
  assert_exit 0 $? "default PROJECTS_PATH used"
  assert_out "alpha" "default path lists projects"
}

# pure function: repl must be portable across shells
t_repl() {
  make_sandbox
  _out=$(
    . "$REPO_ROOT/src/utils/io.sh" 2>/dev/null
    repl "=" 4
  )
  if [ "$_out" = "====" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    repl: expected \"====\", got \"$_out\"\n"
  fi
}

# dependency declarations
t_deps_module_requires() {
  make_sandbox
  _out=$(
    . "$REPO_ROOT/src/utils/deps.sh"
    module_requires "$REPO_ROOT/src/module/open/index.sh"
  )
  if [ "$_out" = "tmux fzf tree" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    deps requires: expected \"tmux fzf tree\", got \"$_out\"\n"
  fi
  _out=$(
    . "$REPO_ROOT/src/utils/deps.sh"
    module_requires "$REPO_ROOT/src/module/list/index.sh"
  )
  if [ -z "$_out" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    deps requires: tagless module should be empty, got \"$_out\"\n"
  fi
}

t_deps_missing() {
  make_sandbox
  _out=$(
    . "$REPO_ROOT/src/utils/deps.sh"
    deps_missing sh pj_tool_that_does_not_exist
  )
  if [ "$_out" = "pj_tool_that_does_not_exist" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    deps missing: expected fake tool reported, got \"$_out\"\n"
  fi
  _out=$(
    . "$REPO_ROOT/src/utils/deps.sh"
    deps_missing sh
  )
  if [ -z "$_out" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    deps missing: present tool should be empty, got \"$_out\"\n"
  fi
}

# core commands must work on a system with only the required tools
t_bare_system_list() {
  make_sandbox alpha
  mkdir -p "$SANDBOX/bin"
  for _t in $(. "$REPO_ROOT/src/utils/deps.sh"; printf '%s' "$FRAMEWORK_REQUIRED_DEPS"); do
    _p=$(command -v "$_t" 2>/dev/null)
    [ -f "$_p" ] && ln -sf "$_p" "$SANDBOX/bin/$_t"
  done
  _shellbin=$(command -v "$1" 2>/dev/null)
  [ "$1" = "bash_posix" ] && _shellbin=$(command -v bash)
  (
    cd "$SANDBOX"
    HOME="$SANDBOX/home" \
    PROJECTS_PATH="$SANDBOX/home/projects" \
    FRAMEWORK_PATH="$REPO_ROOT" \
    FRAMEWORK_NAME="pj" \
    FRAMEWORK_VERSION="v-test" \
    PATH="$SANDBOX/bin" \
    "$_shellbin" "$BOOTSTRAP" list >"$SANDBOX/out" 2>"$SANDBOX/err"
  )
  assert_exit 0 $? "list works without tmux/fzf/jq"
  assert_out "alpha" "bare-system list shows project"
}

t_module_missing_dep_warns() {
  make_sandbox
  mkdir -p "$SANDBOX/home/.config/pj/plugins/noop"
  printf '%s\n' \
    '# summary: noop plugin' \
    '# requires: pj_tool_that_does_not_exist' \
    'init() {' \
    '  case "$1" in' \
    '    help) echo "noop help" ;;' \
    '    *) echo "noop ran" ;;' \
    '  esac' \
    '}' \
    'init "$@"' > "$SANDBOX/home/.config/pj/plugins/noop/index.sh"
  pj "$1" noop; assert_exit 0 $? "plugin runs despite missing dep"
  assert_out "pj_tool_that_does_not_exist" "warning names the missing tool"
  assert_out "noop ran" "plugin still executes"
}

t_help_user_plugin() {
  make_sandbox
  mkdir -p "$SANDBOX/home/.config/pj/plugins/foo"
  printf '%s\n' \
    '# summary: foo plugin' \
    'init() {' \
    '  case "$1" in' \
    '    help) echo "foo-help-marker" ;;' \
    '    *) echo "foo ran" ;;' \
    '  esac' \
    '}' \
    'init "$@"' > "$SANDBOX/home/.config/pj/plugins/foo/index.sh"
  pj "$1" help foo; assert_exit 0 $? "help for user plugin"
  assert_out "foo-help-marker" "help dispatches to the user plugin"
}

t_help_self() {
  make_sandbox
  pj "$1" help help; assert_exit 0 $? "help help does not crash"
  assert_out "USAGE" "help help shows usage"
}

# assert_out_file: needle, file, name
assert_out_file() {
  _needle="$1"; _file="$2"; _name="$3"
  if grep -q -- "$_needle" "$_file" 2>/dev/null; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    $_name: file $_file missing \"$_needle\"\n"
  fi
}

# completion generation through the module
t_completion_zsh() {
  make_sandbox
  pj "$1" completion zsh; assert_exit 0 $? "completion zsh ok"
  _f="$SANDBOX/home/.local/share/zsh/site-functions/_pj"
  if [ -e "$_f" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    completion zsh: file $_f not written\n"
  fi
  assert_out_file "archive" "$_f" "completion zsh lists archive"
  assert_out_file "new" "$_f" "completion zsh lists new"
  if command -v zsh >/dev/null 2>&1; then
    if zsh -n "$_f" >/dev/null 2>&1; then
      PASS=$((PASS + 1))
    else
      FAIL=$((FAIL + 1))
      FAILED="$FAILED    completion zsh: generated file fails zsh -n\n"
    fi
  fi
}

t_completion_bash() {
  make_sandbox
  pj "$1" completion bash; assert_exit 0 $? "completion bash ok"
  _f="$SANDBOX/home/.local/share/bash-completion/completions/pj"
  if [ -e "$_f" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    completion bash: file $_f not written\n"
  fi
  assert_out_file "archive" "$_f" "completion bash lists archive"
  assert_out_file "new" "$_f" "completion bash lists new"
  if command -v bash >/dev/null 2>&1; then
    if bash -n "$_f" >/dev/null 2>&1; then
      PASS=$((PASS + 1))
    else
      FAIL=$((FAIL + 1))
      FAILED="$FAILED    completion bash: generated file fails bash -n\n"
    fi
  fi
}

# generator must include every core module (name:summary lines)
t_completion_all_modules() {
  make_sandbox
  mkdir -p "$SANDBOX/home/.config/pj/plugins/colon"
  cat > "$SANDBOX/home/.config/pj/plugins/colon/index.sh" <<'EOF'
#!/bin/sh
# --------
# summary: fixes: things with colons
# --------
EOF
  _zsh_out=$(
    HOME="$SANDBOX/home" \
    FRAMEWORK_PATH="$REPO_ROOT" \
    sh "$REPO_ROOT/src/completion/generate.sh" zsh 2>/dev/null
  ) || {
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    completion all modules: generator failed\n"
    return
  }
  for m in analyze archive commit delete document example help list new open refresh update completion env; do
    if printf '%s' "$_zsh_out" | grep -q "'$m:"; then
      PASS=$((PASS + 1))
    else
      FAIL=$((FAIL + 1))
      FAILED="$FAILED    completion all modules: missing $m\n"
    fi
  done
  # a summary containing ':' must not be truncated at the last colon
  if printf '%s' "$_zsh_out" | grep -q "'colon:fixes things with colons'"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    completion all modules: colon summary mangled\n"
  fi
}

# agent prompt templates: the Gemini-backed modules keep their prompts as
# reusable {{PLACEHOLDER}} text templates next to main.ts
t_agent_prompts() {
  make_sandbox
  assert_file "$REPO_ROOT/src/utils/prompt.ts" "shared prompt renderer exists"
  for m in commit analyze document; do
    _t="$REPO_ROOT/src/module/$m/prompt.txt"
    assert_file "$_t" "$m prompt template exists"
    if grep -q '{{[A-Z_]\{1,\}}}' "$_t"; then
      PASS=$((PASS + 1))
    else
      FAIL=$((FAIL + 1))
      FAILED="$FAILED    $m prompt template: no {{PLACEHOLDER}} slots found\n"
    fi
  done
  if grep -q '{{DIFF}}' "$REPO_ROOT/src/module/commit/prompt.txt" &&
     grep -q '{{CODEBASE_SUMMARY}}' "$REPO_ROOT/src/module/analyze/prompt.txt" &&
     grep -q '{{CODEBASE_SUMMARY}}' "$REPO_ROOT/src/module/document/prompt.txt"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    agent prompts: expected placeholder names missing\n"
  fi

  # with bun available, render each template through the real wrappers
  if command -v bun >/dev/null 2>&1; then
    cat > "$SANDBOX/render.ts" <<EOF
import { createPrompt as commit } from "$REPO_ROOT/src/module/commit/prompts";
import { createPrompt as analyze } from "$REPO_ROOT/src/module/analyze/prompts";
import { createPrompt as document } from "$REPO_ROOT/src/module/document/prompts";
const rendered = [
  commit("main", "diff --git a/x b/x", null),
  analyze("SNAP"),
  document("SNAP"),
];
process.exit(rendered.every((r) => r.length > 0 && !/\{\{\w+\}\}/.test(r)) ? 0 : 1);
EOF
    bun "$SANDBOX/render.ts" >/dev/null 2>&1
    assert_exit 0 $? "bun renders all prompt templates"
  fi
}

# agent shared runner: the Gemini modules share one bun runner and one
# shell helper; user plugins can build their own commands on the same pieces
t_agent_utils() {
  make_sandbox
  assert_file "$REPO_ROOT/src/utils/gemini.ts" "shared gemini runner exists"
  assert_file "$REPO_ROOT/src/utils/agent.sh" "shared agent shell helper exists"

  # agent.sh defines the helpers and is sourced by the utils index
  if sh -c '. "$1"; type agent_run >/dev/null 2>&1 && type agent_show >/dev/null 2>&1' sh "$REPO_ROOT/src/utils/agent.sh"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    agent.sh: agent_run/agent_show not defined after sourcing\n"
  fi
  if grep -q 'agent\.sh' "$REPO_ROOT/src/utils/index.sh"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    utils/index.sh: agent.sh not sourced\n"
  fi

  # with bun, import the shared runner and exercise the file walker
  if command -v bun >/dev/null 2>&1; then
    mkdir -p "$SANDBOX/walk/node_modules/x" "$SANDBOX/walk/src" "$SANDBOX/walk/dist"
    printf 'dist/\n*.local\n' > "$SANDBOX/walk/.gitignore"
    printf 'x\n' > "$SANDBOX/walk/main.go"
    printf 'x\n' > "$SANDBOX/walk/src/index.ts"
    printf 'x\n' > "$SANDBOX/walk/node_modules/x/junk.js"
    printf 'x\n' > "$SANDBOX/walk/dist/bundle.js"
    printf 'x\n' > "$SANDBOX/walk/app.local"
    cat > "$SANDBOX/agent-import.ts" <<EOF
import { runAgent, callGeminiApi, collectFiles, generateCodebaseSummary } from "$REPO_ROOT/src/utils/gemini";
const need = [runAgent, callGeminiApi, collectFiles, generateCodebaseSummary];
if (need.some((f) => typeof f !== "function")) process.exit(1);
const files = await collectFiles("$SANDBOX/walk", [], []);
const names = files.map((f) => f.slice("$SANDBOX/walk/".length)).sort();
process.exit(JSON.stringify(names) === JSON.stringify(["main.go", "src/index.ts"]) ? 0 : 2);
EOF
    bun "$SANDBOX/agent-import.ts" >/dev/null 2>&1
    assert_exit 0 $? "bun imports shared runner, walker excludes defaults+gitignore"
  fi

  # each agent module uses the shared runner (no local callGeminiApi copies)
  for m in commit analyze document; do
    if grep -q 'utils/gemini' "$REPO_ROOT/src/module/$m/main.ts" &&
       ! grep -q 'callGeminiApi' "$REPO_ROOT/src/module/$m/main.ts"; then
      PASS=$((PASS + 1))
    else
      FAIL=$((FAIL + 1))
      FAILED="$FAILED    $m/main.ts: does not use shared runner (or still has local callGeminiApi)\n"
    fi
    if grep -q 'agent_run' "$REPO_ROOT/src/module/$m/index.sh"; then
      PASS=$((PASS + 1))
    else
      FAIL=$((FAIL + 1))
      FAILED="$FAILED    $m/index.sh: does not use agent_run\n"
    fi
  done
}

# ---- app layer (pragma reflection) ------------------------------------------

run_fx() {
  _fxs="$1"; _fxf="$2"; shift 2
  (
    cd "$SANDBOX"
    HOME="$SANDBOX/home"
    APP_TEST_UTILS="$REPO_ROOT/src/utils"
    export HOME APP_TEST_UTILS
    case "$_fxs" in
      bash_posix) bash --posix "$_fxf" "$@" ;;
      *) "$_fxs" "$_fxf" "$@" ;;
    esac >"$SANDBOX/out" 2>"$SANDBOX/err"
  )
  return $?
}

# writes a fixture with routes + flags + version
fx_app() {
  cat > "$SANDBOX/fx.sh" <<'EOF'
#!/bin/sh
# @about     App fixture
# @version   1.2.3
# @usage     fx [command] [options]
# @flag      -n, --name=<who>    whom to greet
# @route     hello               greet someone
# @route     info                show info
# @default   hello
. "$APP_TEST_UTILS/colors.sh"
. "$APP_TEST_UTILS/io.sh"
. "$APP_TEST_UTILS/app.sh"
hello(){ inform "hi ${OPT_NAME:-world}"; }
info(){ inform "fx $APP_VERSION"; }
app_start "$@"
EOF
}

t_app_help() {
  make_sandbox
  fx_app
  run_fx "$1" "$SANDBOX/fx.sh" -h; assert_exit 0 $? "app help rc"
  assert_out "App fixture" "app help shows about"
  assert_out "hello" "app help lists routes"
  assert_out "-n,--name" "app help lists flag"
  assert_out "show version" "app help lists version flag"
}

t_app_flags() {
  make_sandbox
  fx_app
  run_fx "$1" "$SANDBOX/fx.sh" --name=bob; assert_exit 0 $? "app flag --x=v rc"
  assert_out "hi bob" "app flag --x=v value"
  run_fx "$1" "$SANDBOX/fx.sh" -n bob; assert_exit 0 $? "app flag -x v rc"
  assert_out "hi bob" "app flag -x v value"
  run_fx "$1" "$SANDBOX/fx.sh" --name "a b"; assert_exit 0 $? "app flag spaced value rc"
  assert_out "hi a b" "app flag keeps spaces"
  run_fx "$1" "$SANDBOX/fx.sh" --bogus; assert_exit 1 $? "app unknown flag rc"
  assert_out "unknown flag" "app unknown flag message"
  run_fx "$1" "$SANDBOX/fx.sh" -v; assert_exit 0 $? "app version rc"
  assert_out "1.2.3" "app version prints"
}

t_app_routes() {
  make_sandbox
  fx_app
  run_fx "$1" "$SANDBOX/fx.sh"; assert_exit 0 $? "app default route rc"
  assert_out "hi world" "app default route runs"
  run_fx "$1" "$SANDBOX/fx.sh" info; assert_exit 0 $? "app route dispatch rc"
  assert_out "fx 1.2.3" "app route runs matching function"

  cat > "$SANDBOX/strict.sh" <<'EOF'
#!/bin/sh
# @usage strict <command>
# @route build  make a build
# @route clean  remove output
. "$APP_TEST_UTILS/colors.sh"
. "$APP_TEST_UTILS/io.sh"
. "$APP_TEST_UTILS/app.sh"
build(){ inform "building ${1:-nothing}"; }
clean(){ inform "cleaning"; }
app_start "$@"
EOF
  run_fx "$1" "$SANDBOX/strict.sh"; assert_exit 1 $? "app strict no-command rc"
  run_fx "$1" "$SANDBOX/strict.sh" bogus; assert_exit 1 $? "app strict unknown rc"
  assert_out "unknown command" "app strict unknown message"
  run_fx "$1" "$SANDBOX/strict.sh" build x; assert_exit 0 $? "app strict dispatch rc"
  assert_out "building x" "app strict passes positionals"
}

t_app_requires() {
  make_sandbox
  cat > "$SANDBOX/req.sh" <<'EOF'
#!/bin/sh
# @requires jq no-such-tool-xyz
. "$APP_TEST_UTILS/colors.sh"
. "$APP_TEST_UTILS/io.sh"
. "$APP_TEST_UTILS/app.sh"
main(){ inform up; }
app_start "$@"
EOF
  run_fx "$1" "$SANDBOX/req.sh"; assert_exit 1 $? "app requires missing rc"
  assert_out "no-such-tool-xyz is required" "app requires names the tool"
}

t_app_args() {
  make_sandbox
  cat > "$SANDBOX/args.sh" <<'EOF'
#!/bin/sh
# @usage work <path> [extra]
# @arg path   target folder
# @arg [extra] optional extra
. "$APP_TEST_UTILS/colors.sh"
. "$APP_TEST_UTILS/io.sh"
. "$APP_TEST_UTILS/app.sh"
main(){ inform "path<$1> extra<${2:-}>"; }
app_start "$@"
EOF
  run_fx "$1" "$SANDBOX/args.sh"; assert_exit 1 $? "app missing arg rc"
  assert_out "path is required" "app missing arg message"
  run_fx "$1" "$SANDBOX/args.sh" "a b" "c d"; assert_exit 0 $? "app args rc"
  assert_out "path<a b> extra<c d>" "app args keep spaces"
}

t_app_passthrough() {
  make_sandbox
  cat > "$SANDBOX/plain.sh" <<'EOF'
#!/bin/sh
. "$APP_TEST_UTILS/colors.sh"
. "$APP_TEST_UTILS/io.sh"
. "$APP_TEST_UTILS/app.sh"
main(){ inform "plain $1"; }
app_start "$@"
EOF
  run_fx "$1" "$SANDBOX/plain.sh" hello; assert_exit 0 $? "app no-pragma rc"
  assert_out "plain hello" "app no-pragma passes args"
}

t_new_script() {
  make_sandbox
  pj "$1" new --script prog.sh; assert_exit 0 $? "new --script rc"
  assert_file "$SANDBOX/prog.sh" "new --script creates file"
  if [ -x "$SANDBOX/prog.sh" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    new --script: prog.sh not executable\n"
  fi
  if grep -q "@about" "$SANDBOX/prog.sh"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    new --script: pragma block missing\n"
  fi

  pj "$1" new --script prog.sh; assert_exit 3 $? "new --script refuses overwrite"
  pj "$1" new -o --script prog.sh; assert_exit 0 $? "new -o --script overwrites"

  # the scaffold runs through the app layer (bundle built on the fly)
  mkdir -p "$SANDBOX/lib"
  cat "$REPO_ROOT/src/utils/colors.sh" \
      "$REPO_ROOT/src/utils/io.sh" \
      "$REPO_ROOT/src/utils/app.sh" > "$SANDBOX/lib/io.sh"
  (
    cd "$SANDBOX"
    HOME="$SANDBOX/home" FRAMEWORK_LIB="$SANDBOX/lib" \
      sh ./prog.sh --name=alice >"$SANDBOX/out" 2>"$SANDBOX/err"
  )
  assert_exit 0 $? "scaffolded script runs"
  assert_out "hello alice" "scaffolded script uses flag value"
  (
    cd "$SANDBOX"
    HOME="$SANDBOX/home" FRAMEWORK_LIB="$SANDBOX/lib" \
      sh ./prog.sh -h >"$SANDBOX/out" 2>"$SANDBOX/err"
  )
  assert_exit 0 $? "scaffolded script help rc"
  assert_out "greet someone" "scaffolded script help lists routes"

  pj "$1" new --script=eq.sh; assert_exit 0 $? "new --script=name rc"
  assert_file "$SANDBOX/eq.sh" "new --script=name creates file"

  # dispatcher must preserve quoting end-to-end (regression: FRAMEWORK_ARGUMENTS)
  pj "$1" new --script "my tool.sh"; assert_exit 0 $? "new --script spaced rc"
  assert_file "$SANDBOX/my tool.sh" "new --script spaced creates file"
  (
    cd "$SANDBOX"
    HOME="$SANDBOX/home" FRAMEWORK_LIB="$SANDBOX/lib" \
      sh "./my tool.sh" --name=x >"$SANDBOX/out" 2>"$SANDBOX/err"
  )
  assert_exit 0 $? "spaced script runs"
  pj "$1" new --script "it's.sh"; assert_exit 0 $? "new --script quoted rc"
  assert_file "$SANDBOX/it's.sh" "new --script quoted creates file"
  pj "$1" new --script spaced2.sh -o; assert_exit 0 $? "trailing flag still stripped"
  assert_file "$SANDBOX/spaced2.sh" "trailing -o does not leak to module"
}

t_env_list() {
  make_sandbox
  pj "$1" env; assert_exit 0 $? "env list rc"
  assert_out "PROJECTS_PATH" "env lists projects path"
  assert_out "override" "env shows override scope"
  assert_out "derived" "env shows derived scope"
  assert_out "ERROR_ILLEGAL_OP" "env lists error codes"
  assert_out "PJ_GEMINI_MODEL" "env lists PJ_GEMINI_MODEL"
  assert_out "gemini-3.8-flash" "env defaults PJ_GEMINI_MODEL to gemini-3.8-flash"
}

t_env_check() {
  make_sandbox
  pj "$1" env check; assert_exit 0 $? "env check rc"
  assert_out "environment ok" "env check success message"
}

t_env_check_broken() {
  make_sandbox
  mkdir -p "$SANDBOX/home/.config/pj"
  echo 'export PROJECTS_LIST_GENERATOR="/nope/gen"' > "$SANDBOX/home/.config/pj/env.sh"
  pj "$1" env check; [ $? -ne 0 ] && PASS=$((PASS + 1)) || {
    FAIL=$((FAIL + 1)); FAILED="$FAILED    env check broken: expected nonzero rc\n"
  }
  assert_out "not found" "env check names missing generator"
  pj "$1" list; [ $? -ne 0 ] && PASS=$((PASS + 1)) || {
    FAIL=$((FAIL + 1)); FAILED="$FAILED    broken env: pj list should fail fast\n"
  }
}

t_question() {
  make_sandbox
  cat > "$SANDBOX/q.sh" <<'EOF'
#!/bin/sh
. "$APP_TEST_UTILS/colors.sh"
. "$APP_TEST_UTILS/io.sh"
a=$(printf 'hello\n' | question "pick one" "def")
printf 'got:%s\n' "$a"
b=$(printf '\n' | question "pick two" "def")
printf 'got:%s\n' "$b"
EOF
  run_fx "$1" "$SANDBOX/q.sh"; assert_exit 0 $? "question script rc"
  assert_out "got:hello" "question returns only the typed answer"
  assert_out "got:def" "question falls back to the default"
  assert_out_file "question:" "$SANDBOX/err" "question prompt goes to stderr"
}

t_radio() {
  make_sandbox
  cat > "$SANDBOX/r.sh" <<'EOF'
#!/bin/sh
. "$APP_TEST_UTILS/colors.sh"
. "$APP_TEST_UTILS/io.sh"
c=$(printf '2\n' | radio "pick" alpha beta gamma) || { echo cancelled; exit 1; }
printf 'got:%s\n' "$c"
d=$(printf '9\n' | radio "pick" alpha beta 2>/dev/null) || printf 'oor\n'
m=$(printf '1,3\n' | multiselect "many" one two three) || { echo cancelled; exit 1; }
printf 'many:%s\n' "$(printf '%s' "$m" | tr '\n' ',')"
e=$(printf '\n' | radio -d beta "pick" alpha beta gamma 2>/dev/null) && printf 'dgot:%s\n' "$e"
printf '\n' | radio "pick" alpha beta 2>/dev/null || printf 'empty-refused\n'
f=$(printf '\n' | multiselect -d "one,three" "many" one two three 2>/dev/null) && printf 'dmany:%s\n' "$(printf '%s' "$f" | tr '\n' ',')"
radio -d nope "pick" alpha beta 2>/dev/null || printf 'dbad-refused\n'
FLAG_COLORED_OUTPUT=0
QUESTION_PREFIX=step
p=$(printf '2\n' | radio "pick" alpha beta 2>&1)
case "$p" in *"step: pick"*) printf 'pfx-ok\n';; esac
EOF
  run_fx "$1" "$SANDBOX/r.sh"; assert_exit 0 $? "radio script rc"
  assert_out "got:beta" "radio fallback picks the numbered choice"
  assert_out "oor" "radio rejects out-of-range choice"
  assert_out "many:one,three" "multiselect fallback picks comma-separated choices"
  assert_out "dgot:beta" "radio -d pre-fills the fallback answer"
  assert_out "empty-refused" "radio without a default refuses an empty answer"
  assert_out "dmany:one,three" "multiselect -d pre-fills the fallback answer"
  assert_out "dbad-refused" "radio rejects a default that is not a choice"
  assert_out "pfx-ok" "QUESTION_PREFIX rebrands the question prefix"

  # interactive menu on a real pty (skip where script(1) is absent)
  if command -v script >/dev/null 2>&1; then
    cat > "$SANDBOX/rp.sh" <<'EOF'
#!/bin/sh
. "$APP_TEST_UTILS/colors.sh"
. "$APP_TEST_UTILS/io.sh"
c=$(radio "pick" alpha beta gamma) || { echo cancelled; exit 1; }
printf 'got:%s\n' "$c"
EOF
    cat > "$SANDBOX/rpd.sh" <<'EOF'
#!/bin/sh
. "$APP_TEST_UTILS/colors.sh"
. "$APP_TEST_UTILS/io.sh"
c=$(radio -d beta "pick" alpha beta gamma) || { echo cancelled; exit 1; }
printf 'got:%s\n' "$c"
EOF
    cat > "$SANDBOX/ms.sh" <<'EOF'
#!/bin/sh
. "$APP_TEST_UTILS/colors.sh"
. "$APP_TEST_UTILS/io.sh"
c=$(multiselect "many" one two three) || { echo cancelled; exit 1; }
printf 'many:%s\n' "$(printf '%s' "$c" | tr '\n' ',')"
EOF
    case "$1" in
      bash_posix) _ptycmd="bash --posix $SANDBOX/rp.sh"; _ptycmd2="bash --posix $SANDBOX/rpd.sh"; _ptycmd3="bash --posix $SANDBOX/ms.sh";;
      *) _ptycmd="$1 $SANDBOX/rp.sh"; _ptycmd2="$1 $SANDBOX/rpd.sh"; _ptycmd3="$1 $SANDBOX/ms.sh";;
    esac
    export APP_TEST_UTILS="$REPO_ROOT/src/utils"
    _out=$(printf '\033[B \n' | script -qec "$_ptycmd" /dev/null 2>/dev/null | tr -d '\r')
    case "$_out" in
      *got:beta*) PASS=$((PASS + 1));;
      *) FAIL=$((FAIL + 1)); FAILED="$FAILED    radio pty: down+space+enter should pick beta\n";;
    esac
    _out=$(printf '\033[B\033[B\033[B \n' | script -qec "$_ptycmd" /dev/null 2>/dev/null | tr -d '\r')
    case "$_out" in
      *got:alpha*) PASS=$((PASS + 1));;
      *) FAIL=$((FAIL + 1)); FAILED="$FAILED    radio pty: window should wrap to first\n";;
    esac
    _out=$(printf '\nq' | script -qec "$_ptycmd" /dev/null 2>/dev/null | tr -d '\r')
    case "$_out" in
      *got:*) FAIL=$((FAIL + 1)); FAILED="$FAILED    radio pty: enter with no choice must not proceed\n";;
      *cancelled*"nothing chosen"*|*"nothing chosen"*cancelled*) PASS=$((PASS + 1));;
      *) FAIL=$((FAIL + 1)); FAILED="$FAILED    radio pty: refusal should hint and stay\n";;
    esac
    _out=$(printf '\n' | script -qec "$_ptycmd2" /dev/null 2>/dev/null | tr -d '\r')
    case "$_out" in
      *got:beta*) PASS=$((PASS + 1));;
      *) FAIL=$((FAIL + 1)); FAILED="$FAILED    radio pty: -d default continues on plain enter\n";;
    esac
    _out=$(printf ' \033[B \n' | script -qec "$_ptycmd3" /dev/null 2>/dev/null | tr -d '\r')
    case "$_out" in
      *many:one,two*) PASS=$((PASS + 1));;
      *) FAIL=$((FAIL + 1)); FAILED="$FAILED    multiselect pty: space toggles, enter continues\n";;
    esac
    _out=$(printf '\nq' | script -qec "$_ptycmd3" /dev/null 2>/dev/null | tr -d '\r')
    case "$_out" in
      *many:*) FAIL=$((FAIL + 1)); FAILED="$FAILED    multiselect pty: enter with no choice must not proceed\n";;
      *cancelled*"nothing chosen"*|*"nothing chosen"*cancelled*) PASS=$((PASS + 1));;
      *) FAIL=$((FAIL + 1)); FAILED="$FAILED    multiselect pty: refusal should hint and stay\n";;
    esac
  fi
}

ALL_TESTS="t_list_ok t_list_empty_ok t_help_ok t_module_help t_unknown_command \
t_unknown_flag t_help_extended t_module_pragma \
t_new_no_args t_new_names t_new_bad_recipe t_new_creates_project t_new_existing_no_overwrite \
t_new_existing_overwrite t_archive_ok t_archive_missing t_delete_missing \
t_list_missing t_refresh_ok t_version t_flag_silent t_bare_defaults_to_open \
t_default_paths \
t_deps_module_requires t_deps_missing t_bare_system_list \
t_question t_radio \
t_module_missing_dep_warns t_help_user_plugin t_help_self t_hooks \
t_app_help t_app_flags t_app_routes t_app_requires t_app_args t_app_passthrough \
t_new_script t_new_module t_env_list t_env_check t_env_check_broken \
t_completion_zsh t_completion_bash t_completion_all_modules t_agent_prompts \
t_agent_utils"

# ---- runner -----------------------------------------------------------------

for shell in $SHELLS; do
  printf "== %s ==\n" "$shell"
  for test in $ALL_TESTS; do
    make_sandbox
    "$test" "$shell"
  done
  make_sandbox
  t_repl "$shell"
done

printf "\n"
printf "passed: %d   failed: %d\n" "$PASS" "$FAIL"
if [ -n "$FAILED" ]; then
  printf "failures:\n%b" "$FAILED"
  exit 1
fi
exit 0
