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

t_new_no_args() {
  make_sandbox
  pj "$1" new; assert_exit 2 $? "new with no args"
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
  _zsh_out=$(
    HOME="$SANDBOX/home" \
    FRAMEWORK_PATH="$REPO_ROOT" \
    sh "$REPO_ROOT/src/completion/generate.sh" zsh 2>/dev/null
  ) || {
    FAIL=$((FAIL + 1))
    FAILED="$FAILED    completion all modules: generator failed\n"
    return
  }
  for m in analyze archive commit delete document example help list new open refresh update completion; do
    if printf '%s' "$_zsh_out" | grep -q "'$m:"; then
      PASS=$((PASS + 1))
    else
      FAIL=$((FAIL + 1))
      FAILED="$FAILED    completion all modules: missing $m\n"
    fi
  done
}

ALL_TESTS="t_list_ok t_list_empty_ok t_help_ok t_module_help t_unknown_command \
t_new_no_args t_new_bad_recipe t_new_creates_project t_new_existing_no_overwrite \
t_new_existing_overwrite t_archive_ok t_archive_missing t_delete_missing \
t_list_missing t_refresh_ok t_version t_flag_silent t_default_paths \
t_completion_zsh t_completion_bash t_completion_all_modules"

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
