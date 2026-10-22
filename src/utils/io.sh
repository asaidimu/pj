: "${FLAG_SILENT:=0}"
: "${ERROR:=1}"
: "${FRAMEWORK_LOGS:=/dev/null}"

# POSIX sleep(1) accepts only integer seconds; sub-second delays are a
# widely available (GNU/BSD) extension. Try it and skip silently when the
# system only supports integers, so animation degrades instead of
# spewing usage errors.
sleep_frac() {
  sleep "$1" 2>/dev/null || :
}

time_stamp(){
  printf '%s\n' "$(date +%H:%M:%S)"
}

repl() {
  char="$1"
  count="$2"
  i=0
  while [ "$i" -lt "$count" ]; do
    printf "%s" "$char"
    i=$((i + 1))
  done
}

label(){
  color="$1"
  level=$(printf '%s' "$2" | tr '[:lower:]' '[:upper:]')
  size=$(printf '%s' "$level" | wc -m)
  size=$((8 - size))
  printf '%s ' "$($color "$(repl " " $size)${level} │")"
}

log(){
  stamp=$(time_stamp)

  out="[ $stamp ] $*"

  printf '%s\n' "$out" >> "$FRAMEWORK_LOGS"
}

prompt(){
  printf '%s\n' "$(red "user@host:")$(blue "~")$ $*"
}

question() {
    property="$1"
    default="$2"

    prompt="$(bold_grey "${QUESTION_PREFIX:-question}"): $property"

    [ -n "$default" ] && prompt="$prompt ($(blue "$default"))"

    prompt="$prompt: "

    printf "%s" "$prompt" >&2
    read -r input

    [ -z "$input" ] && input=$default

    printf '%s\n' "$input"
}

# how many choices a radio/multiselect menu shows before scrolling
RADIO_WINDOW=${RADIO_WINDOW:-5}
_ESC=$(printf '\033')
_CR=$(printf '\r')
_NL='
'

# print the nth item of a list (1-based): _radio_nth <n> <items...>
_radio_nth() {
    _rn="$1"; shift
    _rj=1
    for _rx in "$@"; do
        [ "$_rj" -eq "$_rn" ] && { printf '%s\n' "$_rx"; return 0; }
        _rj=$((_rj + 1))
    done
    return 1
}

# erase the menu block above the cursor. After any render the cursor sits
# exactly _radio_lines rows below the block start (an n-line block keeps
# that distance even when the terminal scrolls, so cursor-relative up-moves
# stay exact while saved screen coordinates do not)
_radio_erase() {
    [ "${_radio_lines:-0}" -gt 0 ] 2>/dev/null && printf '\033[%dA\r\033[J' "$_radio_lines" >&2
    _radio_lines=0
}

# truncate stdin to <n> display cells: _radio_cut <n>
# ANSI escape sequences pass through uncounted (and are kept past the
# width, so a trailing reset can never be chopped); printable bytes are
# capped, which byte-wise can only under-count cells — never wrap
_radio_cut() {
    awk -v w="$1" '
    {
        if (seen) printf "\n"
        seen = 1
        cnt = 0; esc = 0; s = ""
        for (i = 1; i <= length($0); i++) {
            c = substr($0, i, 1)
            if (esc == 2) { s = s c; if (c ~ /[A-Za-z]/) esc = 0; continue }
            if (esc == 1) { s = s c; if (c == "[") esc = 2; else esc = 0; continue }
            if (c == "\033") { s = s c; esc = 1; continue }
            if (cnt < w) { s = s c; cnt++ }
        }
        printf "%s", s
    }'
}

# 1-based index of a choice: _radio_index <value> <choices...> (fails if absent)
_radio_index() {
    _rixv="$1"; shift
    _rixn=1
    for _rixc in "$@"; do
        [ "$_rixc" = "$_rixv" ] && { printf '%d\n' "$_rixn"; return 0; }
        _rixn=$((_rixn + 1))
    done
    return 1
}

# redraw a scrolling menu (stderr): _radio_draw <prompt> <sel> <top> <mode> <marks> <items...>
# mode is "radio" (○/●) or "check" (☐/☑); marks is a space-separated
# list of 1-based indexes rendered as filled
_radio_draw() {
    _rp="$1"; _rsel="$2"; _rtop="$3"; _rmode="$4"; _rmarks="$5"; shift 5
    _rn=$#
    _rw=$RADIO_WINDOW
    _rlast=$((_rtop + _rw))
    [ "$_rlast" -gt "$_rn" ] && _rlast=$_rn

    if [ "${FLAG_COLORED_OUTPUT:-1}" -eq 1 ]; then
        _rdim=$(printf '\033[2m'); _rbld=$(printf '\033[1m')
        _rrst=$(printf '\033[0m'); _rcol=$(printf '\033[36m')
        _rerr=$(printf '\033[31m')
    else
        _rdim=""; _rbld=""; _rrst=""; _rcol=""; _rerr=""
    fi

    _rcols=$(stty size 2>/dev/null | awk '{ print $2 }')
    case "$_rcols" in ""|*[!0-9]*) _rcols=80;; esac
    [ "$_rcols" -gt 0 ] || _rcols=80
    _rbudget=$(( _rcols - 8 )); [ "$_rbudget" -lt 4 ] && _rbudget=4

    # one frame, one write(): cursor-up (scroll-safe), then every line as
    # CR + EL (clear-to-EOL) + text, so old content is overwritten in place
    # and the terminal repaints the whole menu in a single update — no
    # blank-gap flicker between the clear and the redraw
    _rframe=""
    [ "${_radio_lines:-0}" -gt 0 ] && _rframe="${_ESC}[${_radio_lines}A"
    _rframe="${_rframe}${_CR}${_ESC}[K$(printf '%s' "$_rp" | _radio_cut $((_rcols - 1)))${_NL}"
    _ri=$_rtop
    while [ "$_ri" -lt "$_rlast" ]; do
        _ritem=$(_radio_nth $((_ri + 1)) "$@")
        case " ${_rmarks:-} " in
            *" $((_ri + 1)) "*)
                if [ "$_rmode" = "check" ]; then _rmark="☑"; else _rmark="●"; fi
                ;;
            *)
                if [ "$_rmode" = "check" ]; then _rmark="☐"; else _rmark="○"; fi
                ;;
        esac
        _ritem=$(printf '%s' "$_ritem" | _radio_cut "$_rbudget")
        if [ "$_ri" -eq "$_rsel" ]; then
            _rline="${_rcol}❯ ${_rmark} ${_rbld}${_ritem}${_rrst}"
        else
            _rline="  ${_rmark} ${_ritem}"
        fi
        _rframe="${_rframe}${_CR}${_ESC}[K${_rline}${_NL}"
        _ri=$((_ri + 1))
    done
    _rcnt=$(printf '(%d/%d) space choose, enter continue, arrows move' "$((_rsel + 1))" "$_rn" | _radio_cut $((_rcols - 1)))
    _rframe="${_rframe}${_CR}${_ESC}[K${_rdim}${_rcnt}${_rrst}${_NL}"
    if [ "${_rwarn:-0}" -eq 1 ]; then
        _rframe="${_rframe}${_CR}${_ESC}[K${_rerr}! nothing chosen yet - press space${_rrst}${_NL}"
    fi
    _rframe="${_rframe}${_CR}${_ESC}[K"
    printf '%s' "$_rframe" >&2
    _radio_lines=$(( _rlast - _rtop + 2 + ${_rwarn:-0} ))
}

# read one raw key; prints up/down/enter/pick-N/q/other
# (the printf X sentinel keeps $( ) from stripping a trailing newline)
_radio_key() {
    _rk=$(dd bs=1 count=1 2>/dev/null; printf X); _rk=${_rk%X}
    case "$_rk" in
        "") printf 'q\n'; return;;
        "
"|"$_CR") printf 'enter\n'; return;;
        j|J) printf 'down\n'; return;;
        ' ') printf 'space\n'; return;;
        k|K) printf 'up\n'; return;;
        q|Q) printf 'q\n'; return;;
        1|2|3|4|5|6|7|8|9) printf 'pick-%s\n' "$_rk"; return;;
        "$_ESC") :;;
        *) printf 'other\n'; return;;
    esac
    _rk2=$(dd bs=1 count=1 2>/dev/null; printf X); _rk2=${_rk2%X}
    [ "$_rk2" = "[" ] || { printf 'other\n'; return; }
    _rk3=$(dd bs=1 count=1 2>/dev/null; printf X); _rk3=${_rk3%X}
    case "$_rk3" in
        A|D) printf 'up\n';;
        B|C) printf 'down\n';;
        *) printf 'other\n';;
    esac
}

# radio [-d <choice>] "prompt" <choice>... — pick exactly one choice
# (prints it). Arrows / j / k move a 5-item window; space chooses the
# highlighted item; enter continues with the chosen item — refused, with
# a hint, until one is chosen (a -d default is chosen up front); numbers
# 1-9 jump and choose; q cancels (rc 1). Non-tty input falls back to a
# numbered list answered through question(), pre-filled with the default.
radio() {
    _rdef=""
    while [ $# -gt 0 ]; do
        case "$1" in
            -d|--default)
                [ $# -ge 2 ] || { error "radio: $1 needs a value"; return 1; }
                _rdef="$2"; shift 2;;
            --default=*) _rdef="${1#*=}"; shift;;
            *) break;;
        esac
    done
    _rprompt="$1"; shift
    [ $# -gt 0 ] || { error "radio needs at least one choice"; return 1; }
    _rtotal=$#
    _rdefidx=""
    if [ -n "$_rdef" ]; then
        _rdefidx=$(_radio_index "$_rdef" "$@") || {
            error "radio: default '$_rdef' is not one of the choices"; return 1;
        }
    fi
    _rshow="$(bold_grey "${QUESTION_PREFIX:-question}"): $_rprompt"
    [ -n "$_rdef" ] && _rshow="$_rshow ($(blue "$_rdef"))"

    if [ ! -t 0 ]; then
        _ri=1
        for _rc in "$@"; do
            printf '%s) %s\n' "$_ri" "$_rc" >&2
            _ri=$((_ri + 1))
        done
        _rn=$(question "$_rprompt [1-$_rtotal]" "${_rdefidx:-}")
        _rn=$(printf '%s' "$_rn" | sed 's/^0*//')
        case "$_rn" in
            ""|*[!0-9]*) error "radio: invalid choice '$_rn'"; return 1;;
        esac
        [ "$_rn" -le "$_rtotal" ] || { error "radio: choice out of range"; return 1; }
        _radio_nth "$_rn" "$@"
        return $?
    fi

    _rsel=0
    _rtop=0
    _rmarks=""
    _rwarn=0
    _rwin=$RADIO_WINDOW
    [ "$_rtotal" -le "$_rwin" ] && _rwin=$_rtotal
    if [ -n "$_rdefidx" ]; then
        _rmarks=$_rdefidx
        _rsel=$((_rdefidx - 1))
        [ "$_rsel" -ge "$_rwin" ] && _rtop=$(( _rsel - _rwin + 1 ))
    fi

    _rsave=$(stty -g 2>/dev/null)
    stty -icanon -echo min 1 time 0 2>/dev/null

    _radio_lines=0
    _radio_draw "$_rshow" "$_rsel" "$_rtop" radio "$_rmarks" "$@"
    while :; do
        _rkey=$(_radio_key)
        _rwarn=0
        case "$_rkey" in
            up)
                if [ "$_rsel" -eq 0 ]; then
                    _rsel=$((_rtotal - 1))
                    _rtop=$(( _rtotal - _rwin )); [ "$_rtop" -lt 0 ] && _rtop=0
                else
                    _rsel=$((_rsel - 1))
                    [ "$_rsel" -lt "$_rtop" ] && _rtop=$_rsel
                fi
                ;;
            down)
                if [ "$_rsel" -eq $((_rtotal - 1)) ]; then
                    _rsel=0
                    _rtop=0
                else
                    _rsel=$((_rsel + 1))
                    [ "$_rsel" -ge $((_rtop + _rwin)) ] && _rtop=$(( _rsel - _rwin + 1 ))
                fi
                ;;
            space)
                _rmarks="$((_rsel + 1))"
                ;;
            enter)
                if [ -z "${_rmarks:-}" ]; then
                    _rwarn=1
                else
                    stty "$_rsave" 2>/dev/null
                    _radio_erase
                    _radio_nth "$_rmarks" "$@"
                    return 0
                fi
                ;;
            pick-*)
                _rpk=${_rkey#pick-}
                if [ "$_rpk" -ge 1 ] && [ "$_rpk" -le "$_rtotal" ]; then
                    _rsel=$((_rpk - 1))
                    [ "$_rsel" -lt "$_rtop" ] && _rtop=$_rsel
                    [ "$_rsel" -ge $((_rtop + _rwin)) ] && _rtop=$(( _rsel - _rwin + 1 ))
                    _rmarks=$_rpk
                fi
                ;;
            q)
                stty "$_rsave" 2>/dev/null
                _radio_erase
                return 1
                ;;
        esac
        _radio_draw "$_rshow" "$_rsel" "$_rtop" radio "$_rmarks" "$@"
    done
}

# multiselect [-d <v1,v2,...>] "prompt" <choice>... — pick any number of
# choices, one per line on stdout. Same menu as radio; space toggles an
# item; enter continues with the toggled items — refused, with a hint,
# until at least one is chosen (a -d default list is toggled up front);
# q cancels (rc 1). Non-tty input falls back to a comma-separated
# numbered answer through question(), pre-filled with the defaults.
multiselect() {
    _mdef=""
    while [ $# -gt 0 ]; do
        case "$1" in
            -d|--default)
                [ $# -ge 2 ] || { error "multiselect: $1 needs a value"; return 1; }
                _mdef="$2"; shift 2;;
            --default=*) _mdef="${1#*=}"; shift;;
            *) break;;
        esac
    done
    _mprompt="$1"; shift
    [ $# -gt 0 ] || { error "multiselect needs at least one choice"; return 1; }
    _mtotal=$#
    _mdefmarks=""
    _mdefcsv=""
    _mdleft=$_mdef
    while [ -n "$_mdleft" ]; do
        _mdv=${_mdleft%%,*}
        case "$_mdleft" in *,*) _mdleft=${_mdleft#*,};; *) _mdleft="";; esac
        [ -n "$_mdv" ] || continue
        _mdi=$(_radio_index "$_mdv" "$@") || {
            error "multiselect: default '$_mdv' is not one of the choices"; return 1;
        }
        _mdefmarks="${_mdefmarks:-} $_mdi"
        _mdefcsv="${_mdefcsv:+$_mdefcsv,}$_mdi"
    done
    _mshow="$(bold_grey "${QUESTION_PREFIX:-question}"): $_mprompt"
    [ -n "$_mdef" ] && _mshow="$_mshow ($(blue "$_mdef"))"

    if [ ! -t 0 ]; then
        _mi=1
        for _mc in "$@"; do
            printf '%s) %s\n' "$_mi" "$_mc" >&2
            _mi=$((_mi + 1))
        done
        _mans=$(question "$_mprompt (comma-separated 1-$_mtotal)" "${_mdefcsv:-}")
        _midx=$(mktemp)
        printf '%s\n' "$_mans" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' > "$_midx"
        _mcount=0
        while IFS= read -r _mn; do
            [ -n "$_mn" ] || continue
            case "$_mn" in *[!0-9]*) rm -f "$_midx"; error "multiselect: invalid choice '$_mn'"; return 1;; esac
            [ "$_mn" -ge 1 ] && [ "$_mn" -le "$_mtotal" ] || {
                rm -f "$_midx"; error "multiselect: choice out of range"; return 1;
            }
            _mcount=$((_mcount + 1))
        done < "$_midx"
        [ "$_mcount" -gt 0 ] || { rm -f "$_midx"; error "multiselect: nothing selected"; return 1; }
        _mout=""
        while IFS= read -r _mn; do
            [ -n "$_mn" ] || continue
            _mout="${_mout}$(_radio_nth "$_mn" "$@")${_NL}"
        done < "$_midx"
        rm -f "$_midx"
        printf '%s' "$_mout"
        return 0
    fi

    _msel=0
    _mtop=0
    _mwin=$RADIO_WINDOW
    [ "$_mtotal" -le "$_mwin" ] && _mwin=$_mtotal
    _mmarks=""
    _rwarn=0
    if [ -n "$_mdefmarks" ]; then
        _mmarks=$_mdefmarks
        _mfirst=${_mdefmarks# }
        _mfirst=${_mfirst%% *}
        _msel=$((_mfirst - 1))
        [ "$_msel" -ge "$_mwin" ] && _mtop=$(( _msel - _mwin + 1 ))
    fi

    _msave=$(stty -g 2>/dev/null)
    stty -icanon -echo min 1 time 0 2>/dev/null

    _radio_lines=0
    _radio_draw "$_mshow" "$_msel" "$_mtop" check "$_mmarks" "$@"
    while :; do
        _mkey=$(_radio_key)
        _rwarn=0
        case "$_mkey" in
            up)
                if [ "$_msel" -eq 0 ]; then
                    _msel=$((_mtotal - 1))
                    _mtop=$(( _mtotal - _mwin )); [ "$_mtop" -lt 0 ] && _mtop=0
                else
                    _msel=$((_msel - 1))
                    [ "$_msel" -lt "$_mtop" ] && _mtop=$_msel
                fi
                ;;
            down)
                if [ "$_msel" -eq $((_mtotal - 1)) ]; then
                    _msel=0
                    _mtop=0
                else
                    _msel=$((_msel + 1))
                    [ "$_msel" -ge $((_mtop + _mwin)) ] && _mtop=$(( _msel - _mwin + 1 ))
                fi
                ;;
            space)
                _mtog=$((_msel + 1))
                case " ${_mmarks:-} " in
                    *" $_mtog "*)
                        _mnew=""
                        _mi2=1
                        while [ "$_mi2" -le "$_mtotal" ]; do
                            if [ "$_mi2" -ne "$_mtog" ]; then
                                case " ${_mmarks:-} " in
                                    *" $_mi2 "*) _mnew="$_mnew $_mi2";;
                                esac
                            fi
                            _mi2=$((_mi2 + 1))
                        done
                        _mmarks=$_mnew
                        ;;
                    *) _mmarks="${_mmarks:-} $_mtog";;
                esac
                ;;
            enter)
                _mout=""
                _mn=1
                while [ "$_mn" -le "$_mtotal" ]; do
                    case " ${_mmarks:-} " in
                        *" $_mn "*) _mout="${_mout}$(_radio_nth "$_mn" "$@")${_NL}";;
                    esac
                    _mn=$((_mn + 1))
                done
                if [ -z "$_mout" ]; then
                    _rwarn=1
                else
                    stty "$_msave" 2>/dev/null
                    _radio_erase
                    printf '%s' "$_mout"
                    return 0
                fi
                ;;
            q)
                stty "$_msave" 2>/dev/null
                _radio_erase
                return 1
                ;;
        esac
        _radio_draw "$_mshow" "$_msel" "$_mtop" check "$_mmarks" "$@"
    done
}

inform(){
  label bold_blue "INFO"
  printf '%s\n' "$*"
}
success(){
  label bold_green "success"
  printf '%s\n' "$*"
}
warn(){
  label bold_yellow "warning"
  printf '%s\n' "$*"
}

trace(){
  label bold_cyan "TRACE"
  printf '%s' "$*"
}

debug(){
  silent=$FLAG_SILENT
  export FLAG_SILENT=0
  label bold_blue "debug"
  printf '%s\n' "$*"
  export FLAG_SILENT=$silent;
}

error(){
  export FLAG_SILENT=0
  [ -n "$1" ] && message=$1 || message="an unexpected error occurred !"
  [ -n "$2" ] && error=$2 || error=$ERROR

  log "ERROR ($error): $message"
  label bold_red "error"
  printf '%s\n' "$message"
}

panic() {
  export FLAG_SILENT=0
  [ -n "$1" ] && message=$1 || message="an unexpected error occurred !"
  [ -n "$2" ] && error=$2 || error=$ERROR

  log "ERROR ($error): $message"
  label bold_red "error"
  printf '%s\n' "$message"
  exit $error
}

notify(){
  # report the outcome of the previous command (its exit status)
  _status=$?

  [ "$FLAG_SILENT" -eq 0 ] || return "$_status"

  success_msg="$1"; failure_msg="$2";

  if [ "$_status" -eq 0 ]; then
    success "$success_msg"
  else
    error "$failure_msg" "$_status"
  fi
  return "$_status"
}

# NOTE: bin/build.sh bundles colors.sh + this file into the generated
# install.sh, so the installer renders this same banner — no second copy.
banner(){
    duration=0.02
    printf "\n" && sleep_frac $duration
    printf "\n" && sleep_frac $duration
    bold_yellow '          ,ggggggggggg,'        && printf '\n' && sleep_frac $duration
    bold_yellow '          dP"""88""""""Y8,'     && printf '\n' && sleep_frac $duration
    bold_yellow '          Yb,  88      `8b '    && printf '\n' && sleep_frac $duration
    bold_yellow '           `"  88      ,8P  ' && blue 'ggggg,'  && printf '\n' && sleep_frac $duration
    bold_yellow '               88aaaad8P"   ' && blue 'dP"  Y8,'  && printf '\n' && sleep_frac $duration
    bold_yellow '               88"""""      ' && blue 'Yb,  gg,'  && printf '\n' && sleep_frac $duration
    bold_yellow '               88           ' && blue ' `"  8I,'  && printf '\n' && sleep_frac $duration
    bold_yellow '               88           ' && blue '    ,8I,'  && printf '\n' && sleep_frac $duration
    bold_yellow '               88           ' && blue '  _,d8I,'  && printf '\n' && sleep_frac $duration
    bold_yellow '               88           ' && blue '888P"888,' && printf '\n' && sleep_frac $duration
    bold_yellow '                            ' && blue '   ,d8I,'  && printf '\n' && sleep_frac $duration
    bold_yellow "                            " && blue " ,dP'8I,"  && printf '\n' && sleep_frac $duration
    bold_yellow '                            ' && blue ',8"  8I,'  && printf '\n' && sleep_frac $duration
    bold_yellow '                            ' && blue 'I8   8I,'  && printf '\n' && sleep_frac $duration
    bold_yellow '                            ' && blue '`8, ,8I,'  && printf '\n' && sleep_frac $duration
    bold_yellow '                            ' && blue ' `Y8P,'    && printf '\n' && sleep_frac $duration
    printf "\n"
    printf "\n"
}

clear_line(){
    printf "\033[1000D" # go to begining of line
    printf "\033[0K" # clear line
}

load() {
    text="$1"
    msg="$2"
    pid="$3"

    [ -z "$pid" ] &&  {
      pid="$msg"
      msg=""
    }

    text="$(trace "${text}")"
    a="${text}    "
    b="${text} .  "
    c="${text} .. "
    d="${text} ..."

    waiting=1
    while [ $waiting -eq 1 ]; do
        printf '%s' "$a"
        sleep_frac 0.3
        clear_line

        printf '%s' "$b"
        sleep_frac 0.3
        clear_line

        printf '%s' "$c"
        sleep_frac 0.3
        clear_line

        printf '%s' "$d"

        if ! kill -0 "$pid" 2>/dev/null; then
            waiting=0
        fi
        sleep_frac 0.3
        clear_line
    done

    [ -z "$msg" ] && clear_line || inform "${msg}"
}

show_version(){
    banner
    bold_green "$(printf '\t     Version %s' "${FRAMEWORK_VERSION#v}")"
    printf '\n'
}
