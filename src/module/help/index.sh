#!/bin/sh
# @about   show help message
# @usage   pj help [command]
# @flag    -x, --extended  show extended framework info (authorship, license, paths)

_help_body() {
  if [ -n "${OPT_EXTENDED:-}" ]; then
    about_full
  else
    about_short
  fi
cat <<EOF

$(bold USAGE)
    pj help
    pj help <command>
    pj <command> help
    pj <command> <command options> [flags]

$(bold "AVAILABLE FLAGS")
    -v  --version      show command version

$(bold "AVAILABLE COMMANDS")
$(module_list)

EOF
}

_module() {
  route="$1"
  shift
  export APP_SOURCE="$route"
  export APP_MODULE=1
  . "$route"
}

_scripts_section() {
  printf '\n'
  bold "$1"
  printf '\n'
}

_scripts_guide() {
  bold "WRITING SCRIPTS"
  cat <<'SCRIPT_GUIDE'

pj ships a small runtime for writing your own command-line scripts. A
script declares its interface in ordinary "# @..." comments, sources the
runtime, and ends with app_start "$@" — flags, routes, help, arity
checks and dependency checks are generated from the comments.

SCRIPT_GUIDE

  _scripts_section "TWO SHAPES"
  cat <<'SCRIPT_GUIDE'
    standalone script   any executable .sh file; sources the io library
    pj plugin           ~/.config/pj/plugins/<name>/index.sh; run as pj <name>

Both use the same pragma grammar. A plugin is sourced into pj's shell, so
it must NOT source the library (the utilities are already loaded). A
standalone script must source it.

SCRIPT_GUIDE

  _scripts_section "1. SCAFFOLD"
  cat <<'SCRIPT_GUIDE'
    pj new --script tools/deploy.sh     # standalone script
    pj new --module greet               # plugin: pj greet

The generated file is ready to run and contains a documented example.
Use -o/--overwrite to replace an existing target.

SCRIPT_GUIDE

  _scripts_section "2. DECLARE THE CLI"
  cat <<'SCRIPT_GUIDE'
Comments at the top of the file are the interface. The "#" keeps them
invisible to sh; the runtime reflects over them before dispatching.

    # @about      copy a project, with optional exclusions
    # @usage      deploy.sh [options] <source> <target>
    # @version    1.0.0
    # @requires   rsync
    # @flag       -n, --dry-run            show what would happen
    # @flag       -e, --exclude=<pattern>  skip matching paths
    # @arg        source                   project to copy
    # @arg        target                   destination name

Pragma reference:

    @about <text>                  one-line description in --help
    @usage <text>                  usage line
    @version <text>                enables -v / --version
    @requires <tool ...>           checked before dispatch (not for --help)
    @flag -x, --xx=<val> <help>    value flag; sets OPT_XX
    @flag -x, --xx <help> [=> V]   boolean flag (1) or custom variable V
    @route <name> <help>           calls name(); first positional selects it
    @default <name>                route when none is given
    @arg <name> <help>             required positional (arity checked)
    @arg [<name>] <help>           optional positional
    @completion <type>             plugin operand completion: none|projects|
                                   recipes|analysis

Rules:

    - flags come BEFORE arguments:    script [options] <args...>
    - value flags accept --xx=v and --xx v
    - -- forces every later word to be positional
    - -h/--help is always generated; -v works when @version is present
    - without any @route, implement main() and positionals arrive as "$@"
    - without any pragma at all, app_start forwards everything to main "$@"

SCRIPT_GUIDE

  _scripts_section "3. IMPLEMENT"
  cat <<'SCRIPT_GUIDE'
Standalone script (source the published library once, at the top):

    #!/usr/bin/env sh
    # @about     copy a project, with optional exclusions
    # @requires  rsync
    # @flag      -n, --dry-run            show what would happen
    # @flag      -e, --exclude=<pattern>  skip matching paths
    # @arg       source                   project to copy
    # @arg       target                   destination name

    . "${FRAMEWORK_LIB:-$HOME/.local/share/pj/lib}/io.sh"

    main() {
      source="$1"
      target="$2"

      if [ -n "${OPT_DRY_RUN:-}" ]; then
        warn "dry run: would copy $source to $target"
        return 0
      fi

      if [ -n "${OPT_EXCLUDE:-}" ]; then
        rsync -a --exclude="$OPT_EXCLUDE" "$source/" "$target/" ||
          panic "rsync failed" "$ERROR_ILLEGAL_OP"
      else
        rsync -a "$source/" "$target/" ||
          panic "rsync failed" "$ERROR_ILLEGAL_OP"
      fi

      success "copied $source to $target"
    }

    app_start "$@"

Plugin with routes (no library source line):

    # @about    greet people
    # @route    greet  a polite greeting (default)
    # @route    shout  an enthusiastic greeting
    # @default  greet

    greet() {
      inform "Hello, ${1:-World}!"
    }

    shout() {
      name=$(printf '%s' "${1:-World}" | tr '[:lower:]' '[:upper:]')
      inform "HELLO, $name!"
    }

    app_start "$@"

SCRIPT_GUIDE

  _scripts_section "4. USE THE RUNTIME"
  cat <<'SCRIPT_GUIDE'
Output helpers (from the io library):

    inform "..."          informational line
    success "..."         success line
    warn "..."            warning line
    error "..." [code]    error line, no exit
    panic "..." [code]    error line, then exits with the code
    log "..."             appends to $FRAMEWORK_LOGS (/dev/null by default)

Colors: bold, underline, header, red, green, yellow, blue, cyan, grey
and their bold_* variants. They print plain text when not on a TTY or
when --no-color / FLAG_COLORED_OUTPUT=0 is in effect.

Prompts: question "label" [default], radio and multiselect. Use these
only for humans; give agents flags instead.

Exit codes: use the framework constants for consistency —

    $ERROR                    generic failure (1)
    $ERROR_INVALID_OPTIONS    bad arguments (2)
    $ERROR_PROJECT_EXISTS     target exists (3)
    $ERROR_UNKNOWN_PLUGIN     unknown recipe/plugin (5)
    $ERROR_UNKNOWN_FLAG       bad flag (6)
    $ERROR_ILLEGAL_OP         operation failed (7)
    $ERROR_MISSING_COMMAND    tool/file missing (9)

SCRIPT_GUIDE

  _scripts_section "5. AGENT CHECKLIST"
  cat <<'SCRIPT_GUIDE'
    - Write POSIX sh only: no arrays, [[ ]], local, or bash-isms.
    - Declare the whole CLI in pragmas; never hand-parse argv.
    - Flags before positional arguments; support -- for pass-through.
    - Non-interactive by default: flags in, deterministic output out.
    - Human messages via inform/success/warn; machine-readable results
      via plain printf on stdout.
    - Fail loudly: panic "what went wrong" "$ERROR_..." (non-zero exit).
    - Declare external tools with @requires so missing deps fail early.
    - In a plugin, do not source the library and do not edit parsing
      code; pj dispatches to your file and sets SCRIPT_NAME for you.
    - Verify both paths: script --help renders, and bad input exits
      non-zero with a useful message.
    - For a plugin, run pj completion afterwards so tab-completion sees
      the new command.

SCRIPT_GUIDE

  _scripts_section "NEXT"
  cat <<'SCRIPT_GUIDE'
    pj new --script <file.sh>       generate a documented starting point
    pj new --module <name>          generate a plugin
    pj help <command>               help for any installed command
    pj help --extended              install paths and framework metadata

The README sections "Pragma-driven apps", "Using the io library in your
own scripts" and "Adding Custom Plugins" contain the same reference with
more examples.

SCRIPT_GUIDE
}

main() {
  module="${1:-}"
  if [ -n "$module" ] && [ "$module" != "help" ]; then
    user_route="$CUSTOM_PLUGINS_PATH/${module}/index.sh"
    route="$FRAMEWORK_ROUTE/$module/index.sh"

    if [ -e "$user_route" ]; then
      route="$user_route"
    fi

    if [ -e "$route" ]; then
      _module "$route" help
      return 0
    fi

    case "$module" in
      scripts|script)
        _scripts_guide
        return 0
        ;;
    esac
  fi

  # No banner here: help is a reference lookup, not a splash screen.
  # The animated banner still plays on `pj -v` and `pj update`.
  _help_body
}

init() {
  app_start "$@"
}

init "$@"
