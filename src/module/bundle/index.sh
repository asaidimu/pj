# @about        create a compact standalone script from a pj-scaffolded script
# @usage        pj bundle <script> [-o|--output=<file>]
# @completion   none
# @requires     gzip
# @flag         -o, --output=<file>   output path (default: <basename>.app)
# Flags and the script path may appear in any order:
#   pj bundle example.sh -o example
#   pj bundle -o example example.sh
#   pj bundle example.sh              # writes example.app
#
# The output is a self-extracting script: the assembled source is
# gzip-compressed and base64-encoded into a heredoc, with a small
# unwrapper that decodes, decompresses and eval's it at runtime.
# Pragma comments stay in the clear so app_start can still reflect
# over $0 for --help / flag parsing.

# Strip full-line comments and blank lines from the runtime sources so the
# payload compresses better.
_compact_lib() {
  sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$@"
}

# Build the concatenated runtime (colors + io + app), compacted.
_runtime_source() {
  _c="$UTILITIES_PATH/colors.sh"
  _i="$UTILITIES_PATH/io.sh"
  _a="$UTILITIES_PATH/app.sh"

  [ -f "$_c" ] && [ -f "$_i" ] && [ -f "$_a" ] || {
    panic "runtime sources missing under $UTILITIES_PATH" "$ERROR_ILLEGAL_OP"
  }

  {
    printf '%s\n' "# ---- pj runtime (bundled by pj bundle) ----"
    _compact_lib "$_c" "$_i" "$_a"
    printf '%s\n' "# ---- end pj runtime ----"
  }
}

# True when a line looks like a source of the pj io library.
_is_io_source_line() {
  case "$1" in
    *"/io.sh"*|*"io.sh\""*|*"io.sh'"*)
      case "$1" in
        *". "*|*.\ *) return 0 ;;
      esac
      ;;
  esac
  return 1
}

# Default output name: strip a trailing extension and append .app.
_default_output() {
  _base=$(basename -- "$1")
  case "$_base" in
    *.*) printf '%s.app\n' "${_base%.*}" ;;
    *)   printf '%s.app\n' "$_base" ;;
  esac
}

# Portable base64 encoder (stdout). Prefer base64(1), fall back to openssl.
_b64_encode() {
  if command -v base64 >/dev/null 2>&1; then
    # GNU wraps at 76 cols by default; -w0 disables. BSD has no -w.
    base64 -w0 2>/dev/null || base64 | tr -d '\n'
    printf '\n'
  elif command -v openssl >/dev/null 2>&1; then
    openssl base64 -A 2>/dev/null || openssl base64
  else
    panic "base64 or openssl is required to bundle" "$ERROR_MISSING_COMMAND"
  fi
}

# Assemble the full standalone source into $1 (tmp path):
#   shebang + pragmas + embedded runtime + user code  (template docs dropped)
_assemble() {
  _in="$1"
  _out="$2"
  _runtime=$(_runtime_source) || return $?
  _replaced=0

  while IFS= read -r _line || [ -n "$_line" ]; do
    case "$_line" in
      \#*how\ to\ use\ this\ template*) break ;;
    esac
    if _is_io_source_line "$_line"; then
      printf '%s\n' "$_runtime"
      _replaced=1
    else
      printf '%s\n' "$_line"
    fi
  done < "$_in" > "$_out"

  if [ "$_replaced" -eq 0 ]; then
    _tmp2=$(mktemp) || return 1
    _injected=0
    while IFS= read -r _line || [ -n "$_line" ]; do
      if [ "$_injected" -eq 0 ]; then
        case "$_line" in
          \#!*)  printf '%s\n' "$_line"; continue ;;
          \#*|'') printf '%s\n' "$_line"; continue ;;
          *)
            printf '%s\n' "$_runtime"
            printf '%s\n' "$_line"
            _injected=1
            continue
            ;;
        esac
      fi
      printf '%s\n' "$_line"
    done < "$_out" > "$_tmp2"
    [ "$_injected" -eq 0 ] && printf '%s\n' "$_runtime" >> "$_tmp2"
    mv "$_tmp2" "$_out"
  fi
}

# Split assembled source: header (shebang + @-pragmas + blanks) stays
# clear-text for pragma reflection; everything else is the compressible body.
_split_header_body() {
  _src="$1"
  _hdr="$2"
  _body="$3"
  _past=0

  : > "$_hdr"
  : > "$_body"

  while IFS= read -r _line || [ -n "$_line" ]; do
    if [ "$_past" -eq 0 ]; then
      case "$_line" in
        \#!*)
          printf '%s\n' "$_line" >> "$_hdr"
          continue
          ;;
        '')
          printf '%s\n' "$_line" >> "$_hdr"
          continue
          ;;
        \#\ @*|\#@*)
          printf '%s\n' "$_line" >> "$_hdr"
          continue
          ;;
        \#*)
          # non-pragma comment (e.g. runtime marker, template leftovers)
          _past=1
          ;;
        *)
          _past=1
          ;;
      esac
    fi
    printf '%s\n' "$_line" >> "$_body"
  done < "$_src"
}

main() {
  input=""
  output="${OPT_OUTPUT:-}"

  while [ $# -gt 0 ]; do
    case "$1" in
      -o|--output)
        shift
        [ $# -gt 0 ] || panic "--output requires a value" "$ERROR_INVALID_OPTIONS"
        output="$1"
        ;;
      --output=*) output="${1#--output=}" ;;
      -o=*)       output="${1#-o=}" ;;
      -*)
        panic "unknown flag: $1 (see --help)" "$ERROR_UNKNOWN_FLAG"
        ;;
      *)
        if [ -z "$input" ]; then
          input="$1"
        else
          panic "unexpected argument: $1" "$ERROR_INVALID_OPTIONS"
        fi
        ;;
    esac
    shift
  done

  [ -n "$input" ] || {
    app_help
    panic "script path is required" "$ERROR_INVALID_OPTIONS"
  }

  [ -f "$input" ] || panic "script not found: $input" "$ERROR_MISSING_COMMAND"
  [ -r "$input" ] || panic "script not readable: $input" "$ERROR_ILLEGAL_OP"

  command -v gzip >/dev/null 2>&1 || {
    panic "gzip is required to bundle" "$ERROR_MISSING_COMMAND"
  }

  if [ -z "$output" ]; then
    output="$(_default_output "$input")"
  fi

  if [ -e "$output" ] && [ "${FLAG_OVERWRITE:-0}" -ne 1 ]; then
    panic "$output already exists (use pj -o bundle ... to overwrite)" "$ERROR_PROJECT_EXISTS"
  fi

  if [ "$output" = "$input" ] && [ "${FLAG_OVERWRITE:-0}" -ne 1 ]; then
    panic "output path is the same as input (use pj -o bundle ... to overwrite in place)" "$ERROR_ILLEGAL_OP"
  fi

  assembled=$(mktemp) || panic "could not create temp file" "$ERROR_ILLEGAL_OP"
  header=$(mktemp)    || panic "could not create temp file" "$ERROR_ILLEGAL_OP"
  body=$(mktemp)      || panic "could not create temp file" "$ERROR_ILLEGAL_OP"
  payload=$(mktemp)   || panic "could not create temp file" "$ERROR_ILLEGAL_OP"
  final=$(mktemp)     || panic "could not create temp file" "$ERROR_ILLEGAL_OP"
  trap 'rm -f "$assembled" "$header" "$body" "$payload" "$final"' 0 1 2 15

  _assemble "$input" "$assembled" || panic "failed to assemble script" "$ERROR_ILLEGAL_OP"

  if ! grep -q 'app_start\|main[ ]*(' "$assembled"; then
    warn "script does not call app_start or define main — bundled file may not run as expected"
  fi

  _split_header_body "$assembled" "$header" "$body"

  # gzip + base64 the body (runtime + user code)
  gzip -n -c "$body" | _b64_encode > "$payload" || {
    panic "compression failed" "$ERROR_ILLEGAL_OP"
  }

  # Write self-extracting wrapper:
  #   1. shebang + pragma header (clear-text, for app_reflect on $0)
  #   2. tiny decoder that base64-decodes + gunzips + evals the payload
  # Pragmas must live in the outer file so SCRIPT_NAME / --help keep working.
  {
    # Prefer the original shebang if present, else a portable one.
    if head -n1 "$header" | grep -q '^#!'; then
      head -n1 "$header"
      tail -n +2 "$header"
    else
      printf '%s\n' '#!/usr/bin/env sh'
      cat "$header"
    fi

    cat <<'UNWRAP'

# --- pj bundle self-extractor ---
# payload is gzip+base64 of the runtime and user code; pragmas above stay
# clear so app_start can reflect over this file ($0).
_pj_b64d() {
  if command -v base64 >/dev/null 2>&1; then
    base64 -d 2>/dev/null || base64 -D
  elif command -v openssl >/dev/null 2>&1; then
    openssl base64 -d
  else
    echo "pj bundle: base64 or openssl required" >&2
    exit 127
  fi
}
eval "$(_pj_b64d <<'PJ_BUNDLE_EOF' | gzip -d
UNWRAP

    cat "$payload"

    printf '%s\n' 'PJ_BUNDLE_EOF
)"
'
  } > "$final"

  outdir=$(dirname -- "$output")
  [ "$outdir" = "." ] || mkdir -p "$outdir" 2>/dev/null || true
  mv "$final" "$output" || panic "could not write $output" "$ERROR_ILLEGAL_OP"
  chmod +x "$output" || panic "could not make $output executable" "$ERROR_ILLEGAL_OP"
  trap - 0 1 2 15
  rm -f "$assembled" "$header" "$body" "$payload"

  size=$(wc -c < "$output" | tr -d ' ')
  plain=$(wc -c < "$input" | tr -d ' ')
  success "Bundled $(green "$input") → $(green "$output") (${size} bytes, from ${plain} + runtime)"
  inform "Run with: ./$output --help"
}

app_start "$@"
