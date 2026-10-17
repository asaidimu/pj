#!/bin/sh
# src/utils/app.sh - pragma-driven app layer
#
# Scripts declare their CLI structure in "# @..." comment pragmas.
# app_start reflects over the caller file to parse flags (with value
# capture), dispatch commands, check required tools and render help —
# so scaffolds never need parsing code edited by hand.
#
# Pragma reference:
#   # @about      <text>            one-line description
#   # @usage      <text>            usage line (default: $SCRIPT_NAME [options])
#   # @version    <text>            enables -v/--version
#   # @requires   <cmd>...          checked before dispatch (after --help)
#   # @flag       -x, --xx=<val>    help text  [=> VAR]   sets OPT_XX (or VAR)
#   # @route      <name>            help text             calls <name>()
#   # @default    <name>            route used when none given
#   # @arg        <name>            help text             required positional
#   # @arg        [<name>]          help text             optional positional

APP_TAB=$(printf '\t')

# Caller script path, captured at source time. In zsh, "$0" inside a
# function is the function name (ARGZERO); the call trace's first entry
# is the sourcing site as "file:line".
if [ -n "${ZSH_VERSION:-}" ]; then
  APP_CALLER="${funcfiletrace[1]:-$0}"
  APP_CALLER="${APP_CALLER%:<->}"
else
  APP_CALLER="$0"
fi

APP_ABOUT=""
APP_USAGE=""
APP_VERSION=""
APP_REQUIRES=""
APP_DEFAULT_ROUTE=""
APP_ROUTES=""
APP_FLAGS=""
APP_ARGS=""

app_trim(){
  read -r APP_TRIMMED <<EOF
$1
EOF
}

app_decl_flag(){
  [ -n "$1" ] || panic "flag pragma needs at least one alias"

  _rest="$1"
  _aliases=""
  _has_value=0
  while [ -n "$_rest" ]; do
    app_trim "$_rest"
    _rest="$APP_TRIMMED"
    [ -n "$_rest" ] || break
    _tok=${_rest%%[ 	]*}
    case "$_tok" in
      -*) :;;
      *) break;;
    esac
    _rest=${_rest#"$_tok"}
    _tok=${_tok%,}
    case "$_tok" in
      *=*) _has_value=1; _tok=${_tok%%=*};;
    esac
    [ -n "$_tok" ] || break
    _aliases="${_aliases:+$_aliases }$_tok"
  done
  [ -n "$_aliases" ] || panic "flag pragma needs at least one alias"

  app_trim "$_rest"
  _rest="$APP_TRIMMED"

  _varspec=""
  case "$_rest" in
    *" => "*) _varspec=${_rest##* => }; _rest=${_rest% => *};;
  esac

  if [ -n "$_varspec" ]; then
    _var="$_varspec"
  else
    _name=""
    _alias_lines=$(printf '%s' "$_aliases" | tr ' ' '\n')
    while read -r _a; do
      [ -n "$_a" ] || continue
      case "$_a" in --*) _name="$_a"; break;; esac
    done <<EOF
$_alias_lines
EOF
    [ -n "$_name" ] || _name=${_aliases%% *}
    _var="OPT_$(printf '%s' "$_name" | tr '[:lower:]-' '[:upper:]_' | sed 's/^_*//')"
  fi

  APP_FLAGS="${APP_FLAGS}${_aliases}${APP_TAB}${_has_value}${APP_TAB}${_var}${APP_TAB}${_rest}
"
}

app_decl_route(){
  [ -n "$1" ] || panic "route pragma needs a name"
  _name=${1%%[ 	]*}
  _rest=${1#"$_name"}
  app_trim "$_rest"
  APP_ROUTES="${APP_ROUTES}${_name}${APP_TAB}${_name}${APP_TAB}${APP_TRIMMED}
"
}

app_decl_arg(){
  [ -n "$1" ] || panic "arg pragma needs a name"
  _name=${1%%[ 	]*}
  _rest=${1#"$_name"}
  app_trim "$_rest"
  _req=1
  case "$_name" in
    \[*\]) _req=0; _name=${_name#\[}; _name=${_name%\]};;
  esac
  APP_ARGS="${APP_ARGS}${_name}${APP_TAB}${_req}${APP_TAB}${APP_TRIMMED}
"
}

app_reflect(){
  APP_REFLECT_SRC="${APP_SOURCE:-$APP_CALLER}"
  [ -f "$APP_REFLECT_SRC" ] || return 0

  APP_ABOUT=""
  APP_USAGE=""
  APP_VERSION=""
  APP_REQUIRES=""
  APP_DEFAULT_ROUTE=""
  APP_ROUTES=""
  APP_FLAGS=""
  APP_ARGS=""

  _pragmas=$(sed -n 's/^# *@ *//p' "$APP_REFLECT_SRC") || return 0
  [ -n "$_pragmas" ] || return 0

  while read -r _key _rest || [ -n "${_key:-}" ]; do
    [ -n "${_key:-}" ] || continue
    case "$_key" in
      about)    APP_ABOUT="$_rest";;
      usage)    APP_USAGE="$_rest";;
      version)  APP_VERSION="$_rest";;
      requires) APP_REQUIRES="$_rest";;
      default)  app_trim "$_rest"; APP_DEFAULT_ROUTE="$APP_TRIMMED";;
      flag)     app_decl_flag "$_rest";;
      route)    app_decl_route "$_rest";;
      arg)      app_decl_arg "$_rest";;
      *) panic "pragma error in $APP_REFLECT_SRC: unknown key '$_key'";;
    esac
  done <<EOF
$_pragmas
EOF

  return 0
}

app_help(){
  bold ABOUT
  printf "\n    %s" "$SCRIPT_NAME"
  [ -n "$APP_ABOUT" ] && printf "\n    %s" "$APP_ABOUT"
  printf "\n\n"
  bold USAGE
  printf "\n    %s\n\n" "${APP_USAGE:-$SCRIPT_NAME [options]}"

  if [ -n "$APP_ARGS" ]; then
    bold ARGUMENTS
    while IFS="$APP_TAB" read -r _hn _hr _hh; do
      [ -n "$_hn" ] || continue
      printf "\n    %-12s %s" "$_hn" "$_hh"
    done <<EOF
$APP_ARGS
EOF
    printf "\n\n"
  fi

  if [ -n "$APP_ROUTES" ]; then
    bold COMMANDS
    while IFS="$APP_TAB" read -r _rn _rf _rh; do
      [ -n "$_rn" ] || continue
      printf "\n    %-12s %s" "$_rn" "$_rh"
    done <<EOF
$APP_ROUTES
EOF
    printf "\n\n"
  fi

  bold options
  printf "\n    %-16s %s" "-h, --help" "show help"
  [ -n "$APP_VERSION" ] && printf "\n    %-16s %s" "-v, --version" "show version"
  if [ -n "$APP_FLAGS" ]; then
    while IFS="$APP_TAB" read -r _fa _fv _fvar _fh; do
      [ -n "$_fa" ] || continue
      case " $_fa " in *" -h "*|*" --help "*) continue;; esac
      _disp=$(printf '%s' "$_fa" | tr ' ' ',')
      [ "$_fv" = "1" ] && _disp="$_disp=..."
      printf "\n    %-16s %s" "$_disp" "$_fh"
    done <<EOF
$APP_FLAGS
EOF
  fi
  printf "\n\n"
}

app_start(){
  if [ "${APP_MODULE:-0}" = "1" ]; then
    SCRIPT_NAME="${SCRIPT_NAME:-$FRAMEWORK_NAME $(basename "$(dirname "${APP_SOURCE:-$APP_CALLER}")")}"
  else
    SCRIPT_NAME="${SCRIPT_NAME:-$(basename "$APP_CALLER")}"
  fi
  export SCRIPT_NAME

  app_reflect

  if [ "${APP_MODULE:-0}" = "1" ] && [ "${1:-}" = "help" ]; then
    app_help
    exit 0
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      --) shift; break;;
      -h|--help) app_help; exit 0;;
      -v|--version)
        [ -n "$APP_VERSION" ] && { printf "%s %s\n" "$SCRIPT_NAME" "$APP_VERSION"; exit 0; }
        ;;
    esac

    case "$1" in
      -*) :;;
      *) break;;
    esac

    _input="$1"
    _inline=""
    case "$_input" in
      *=*) _inline=${_input#*=}; _input=${_input%%=*};;
    esac

    _matched=0
    if [ -n "$APP_FLAGS" ]; then
      while IFS="$APP_TAB" read -r _aliases _has_value _var _help; do
        [ -n "$_aliases" ] || continue
        case " $_aliases " in
          *" $_input "*)
            _matched=1
            if [ "$_has_value" = "1" ]; then
              if [ -n "$_inline" ]; then
                export "$_var=$_inline"
              else
                shift
                [ $# -gt 0 ] || panic "flag $_input requires a value"
                export "$_var=$1"
              fi
            else
              [ -z "$_inline" ] || panic "flag $_input does not take a value"
              export "$_var=1"
            fi
            shift
            break
            ;;
        esac
      done <<EOF
$APP_FLAGS
EOF
    fi
    [ "$_matched" = "1" ] || panic "unknown flag: $1 (see --help)"
  done

  if [ -n "$APP_REQUIRES" ]; then
    _req_lines=$(printf '%s' "$APP_REQUIRES" | tr ' ' '\n')
    while read -r _cmd; do
      [ -n "$_cmd" ] || continue
      command -v "$_cmd" >/dev/null 2>&1 || panic "$_cmd is required to run $SCRIPT_NAME"
    done <<EOF
$_req_lines
EOF
  fi

  if [ -n "$APP_ARGS" ]; then
    _need=0
    _max=0
    while IFS="$APP_TAB" read -r _n _r _h; do
      [ -n "$_n" ] || continue
      _max=$((_max + 1))
      [ "$_r" = "1" ] || continue
      _need=$((_need + 1))
      if [ "$#" -lt "$_need" ]; then
        _missing="$_n"
        app_help
        panic "$_missing is required"
      fi
    done <<EOF
$APP_ARGS
EOF
    if [ "$#" -gt "$_max" ]; then
      panic "unexpected argument: $((_max + 1))th (flags come before arguments, see --help)"
    fi
  fi

  if [ -n "$APP_ROUTES" ]; then
    _route="$APP_DEFAULT_ROUTE"
    if [ "$#" -gt 0 ]; then
      _names=""
      while IFS="$APP_TAB" read -r _n _f _h; do
        [ -n "$_n" ] || continue
        _names="${_names}$_n "
      done <<EOF
$APP_ROUTES
EOF
      _matched=""
      case " $_names " in
        *" $1 "*) _route="$1"; shift; _matched=1;;
      esac
      if [ -z "$_matched" ]; then
        panic "unknown command: $1 (see --help)"
      fi
    fi
    if [ -z "$_route" ]; then
      panic "a command is required (see --help)"
    fi
    "$_route" "$@"
  else
    main "$@"
  fi
}
