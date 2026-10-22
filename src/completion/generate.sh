#!/bin/sh
# src/completion/generate.sh - generate shell completions for pj
#
# Reads the "# @..." pragmas from every module's index.sh (core modules +
# user plugins) and emits a completion script for the requested shell on
# stdout. The same pragma block that drives `--help` (see src/utils/app.sh)
# drives completions — description, tab-completion kind and flags:
#
#   # @about        <text>          one-line description (completion menu)
#   # @completion   <type>          none | projects | recipes | analysis
#   # @flag         -x, --xx=<val>  flag completion (short, long, value hint)
#
# Usage:
#   sh generate.sh [zsh|bash]    # default zsh
#
# Env:
#   FRAMEWORK_NAME  default: pj
#   FRAMEWORK_PATH  required - framework install location
#   FRAMEWORK_ROUTE default: $FRAMEWORK_PATH/src/module
#   CUSTOM_PLUGINS_PATH default: $HOME/.config/$FRAMEWORK_NAME/plugins

set -u

FRAMEWORK_NAME="${FRAMEWORK_NAME:-pj}"
FRAMEWORK_PATH="${FRAMEWORK_PATH:?FRAMEWORK_PATH must be set}"
FRAMEWORK_ROUTE="${FRAMEWORK_ROUTE:-$FRAMEWORK_PATH/src/module}"
CUSTOM_PLUGINS_PATH="${CUSTOM_PLUGINS_PATH:-$HOME/.config/$FRAMEWORK_NAME/plugins}"
RECIPES_PATH="${RECIPES_PATH:-$FRAMEWORK_PATH/plugins/recipes}"
CUSTOM_RECIPES_PATH="${CUSTOM_RECIPES_PATH:-$CUSTOM_PLUGINS_PATH/recipes}"

TARGET="${1:-zsh}"

TEMPDIR="${TMPDIR:-/tmp}"
MODULES_FILE="$TEMPDIR/pj-completion-$$"
trap 'rm -f "$MODULES_FILE"' 0

# -- collection ---------------------------------------------------------------

# one awk per module: anchored @-pragma parse. Emits
#   name:about:completion:hasflags:index
# about has colons/quotes/backticks stripped so the ":" record format and
# zsh _describe stay intact (colons would truncate the field).
collect_modules() {
  for route in "$FRAMEWORK_ROUTE" "$CUSTOM_PLUGINS_PATH"; do
    [ -d "$route" ] || continue
    for module in "$route"/*; do
      [ -d "$module" ] || continue
      index="$module/index.sh"
      [ -f "$index" ] || continue

      name="${module##*/}"
      awk -v name="$name" -v idx="$index" \
          -v fallback="see $FRAMEWORK_NAME $name help" '
        {
          if (!sum && $0 ~ /^# *@ *about[ \t]/) { sum = $0; sub(/^# *@ *about[ \t]+/, "", sum) }
          if (!cmp && $0 ~ /^# *@ *completion[ \t]/) { cmp = $0; sub(/^# *@ *completion[ \t]+/, "", cmp) }
          if ($0 ~ /^# *@ *flag[ \t]/) flags++
        }
        END {
          if (sum == "") sum = fallback
          if (cmp == "") cmp = "none"
          gsub(/["\047`:]/, "", sum)
          printf "%s:%s:%s:%d:%s\n", name, sum, cmp, (flags > 0 ? 1 : 0), idx
        }
      ' "$index"
    done
  done
}

# one zsh _arguments spec per @flag, already quoted where the shell needs
# it; the {-s,--staged} braces stay unquoted so zsh expands them.
zsh_flag_specs() {
  awk '
    function sanit(s) { gsub(/[\[\]\047`]/, "", s); return s }
    /^# *@ *flag[ \t]/ {
      line = $0; sub(/^# *@ *flag[ \t]+/, "", line)
      n = split(line, tok, /[ \t]+/)
      short = ""; long = ""; hasval = 0; hint = ""; i = 1
      while (i <= n && tok[i] ~ /^-/) {
        a = tok[i]; sub(/,$/, "", a)
        if (a ~ /=/) {
          hasval = 1
          h = a; sub(/.*=</, "", h); sub(/>.*/, "", h)
          hint = sanit(h); if (hint == "") hint = "value"
          sub(/=.*/, "", a)
        }
        if (a ~ /^--/) long = a; else if (a ~ /^-/) short = a
        i++
      }
      help = ""
      while (i <= n) { help = help (help == "" ? "" : " ") tok[i]; i++ }
      help = sanit(help)
      if (short != "" && long != "") {
        excl = "(" short " " long ")"
        if (hasval) printf "\047%s\047{%s,%s}\047[%s]:%s\047 \\\n", excl, short, long, help, hint
        else        printf "\047%s\047{%s,%s}\047[%s]\047 \\\n", excl, short, long, help
      } else if (long != "") {
        if (hasval) printf "\047%s[%s]:%s\047 \\\n", long, help, hint
        else        printf "\047%s[%s]\047 \\\n", long, help
      } else if (short != "") {
        if (hasval) printf "\047%s[%s]:%s\047 \\\n", short, help, hint
        else        printf "\047%s[%s]\047 \\\n", short, help
      }
    }
  ' "$1"
}

# one "-x:help" / "--xx:help" _describe entry per @flag alias
zsh_flag_opts() {
  awk '
    function sanit(s) { gsub(/[`\047]/, "", s); gsub(/:/, "", s); return s }
    /^# *@ *flag[ \t]/ {
      line = $0; sub(/^# *@ *flag[ \t]+/, "", line)
      n = split(line, tok, /[ \t]+/)
      short = ""; long = ""; i = 1
      while (i <= n && tok[i] ~ /^-/) {
        a = tok[i]; sub(/,$/, "", a); sub(/=.*/, "", a)
        if (a ~ /^--/) long = a; else if (a ~ /^-/) short = a
        i++
      }
      help = ""
      while (i <= n) { help = help (help == "" ? "" : " ") tok[i]; i++ }
      help = sanit(help)
      if (short != "") printf "\047%s:%s\047\n", short, help
      if (long != "")  printf "\047%s:%s\047\n", long, help
    }
  ' "$1"
}

# flag words for bash compgen (short + long names, values stripped)
bash_flag_words() {
  awk '
    /^# *@ *flag[ \t]/ {
      line = $0; sub(/^# *@ *flag[ \t]+/, "", line)
      n = split(line, tok, /[ \t]+/)
      i = 1
      while (i <= n && tok[i] ~ /^-/) {
        a = tok[i]; sub(/,$/, "", a); sub(/=.*/, "", a)
        printf "%s ", a
        i++
      }
    }
  ' "$1"
}

# flagless groups (flagged commands get their own dispatch arm); skips help.
# leaf (no operand completion) is only needed by bash, whose empty case
# arm keeps those commands from falling through to the command list.
build_groups() {
  projects=""
  recipes=""
  analysis=""
  leaf=""
  while IFS=: read -r name about completion hasflags index; do
    [ -z "$name" ] && continue
    [ "$name" = "help" ] && continue
    [ "$hasflags" = "1" ] && continue
    case "$completion" in
      projects) projects="${projects:+$projects|}$name" ;;
      recipes) recipes="${recipes:+$recipes|}$name" ;;
      analysis) analysis="${analysis:+$analysis|}$name" ;;
      *) leaf="${leaf:+$leaf|}$name" ;;
    esac
  done < "$MODULES_FILE"
}

# -- zsh ---------------------------------------------------------------------

emit_zsh() {
  # #compdef must be the first line for zsh to load this as a completion
  printf '#compdef pj\n\n'
  printf '# Zsh completion for pj command\n'
  printf '# Generated by src/completion/generate.sh - do not edit\n\n'
  # bake the recipe directories into the completion: listing them is a plain
  # directory scan at TAB time instead of booting the whole framework
  printf 'typeset -ga _pj_recipe_dirs\n'
  printf '_pj_recipe_dirs=(\n'
  printf '    %s\n' "'$CUSTOM_RECIPES_PATH'"
  printf '    %s\n' "'$RECIPES_PATH'"
  printf ')\n\n'
cat <<'ZHEAD'
_pj() {
    local context state line
    typeset -A opt_args

    # Main command structure
    _arguments -C \
        '(-v --version)'{-v,--version}'[show command version]' \
        '1: :_pj_commands' \
        '*:: :->args' && return 0

    case $state in
        args)
            case $words[1] in
                help)
                    _pj_help_completion
                    ;;
ZHEAD
  # flagged commands get a dedicated arm wired to their generated function
  while IFS=: read -r name about completion hasflags index; do
    [ "$hasflags" = "1" ] || continue
    [ "$name" = "help" ] && continue
    printf '                %s)\n                    _pj_flags_%s\n                    ;;\n' "$name" "$name"
  done < "$MODULES_FILE"
  build_groups
  [ -n "$projects" ] && \
    printf '                %s)\n                    _pj_project_completion\n                    ;;\n' "$projects"
  [ -n "$recipes" ] && \
    printf '                %s)\n                    _pj_new_completion\n                    ;;\n' "$recipes"
  [ -n "$analysis" ] && \
    printf '                %s)\n                    _pj_project_analysis_completion\n                    ;;\n' "$analysis"
  cat <<'ZMID'
                *)
                    # Check if the command supports help
                    if [[ $words[-1] == "help" ]]; then
                        return 0
                    fi
                    ;;
            esac
            ;;
    esac

    return 1
}

# Complete main commands
_pj_commands() {
    local -a commands
    commands=(
ZMID
  while IFS=: read -r name about completion hasflags index; do
    printf "        '%s:%s'\n" "$name" "$about"
  done < "$MODULES_FILE"
  cat <<'ZCMD'
    )
    _describe 'commands' commands
}

# Complete help subcommands
_pj_help_completion() {
    local -a help_commands
    help_commands=(
ZCMD
  while IFS=: read -r name about completion hasflags index; do
    printf "        '%s:show help for %s command'\n" "$name" "$name"
  done < "$MODULES_FILE"
  cat <<'ZHELP'
    )
    _describe 'help commands' help_commands
}

# Project names straight from the projects directory — same thing
# `pj list` shows, without booting the framework on every TAB.
# Export PROJECTS_PATH in your shell if you override it in env.sh.
_pj_get_projects() {
    local dir="${PROJECTS_PATH:-$HOME/projects}"
    local -a projects
    [[ -d $dir ]] || return 0
    projects=(${(f)"$(command ls -1 "$dir" 2>/dev/null)"})
    if [[ ${#projects[@]} -gt 0 ]]; then
        printf '%s\n' "${projects[@]}"
    fi
}

# Recipe names straight from the recipe directories — same thing
# `pj new --names` shows, but without booting the framework on every TAB.
# Directories are baked in at generation time (see _pj_recipe_dirs above).
_pj_get_recipes() {
    local dir r
    local -A seen
    local -a recipes
    for dir in "${_pj_recipe_dirs[@]}"; do
        [[ -d $dir ]] || continue
        for r in "$dir"/*(N.); do
            [[ -x $r ]] || continue
            [[ -n ${seen[${r:t}]} ]] && continue
            seen[${r:t}]=1
            recipes+=("${r:t}")
        done
    done
    if [[ ${#recipes[@]} -gt 0 ]]; then
        printf '%s\n' "${(@o)recipes}"
    fi
}

# Complete project names for commands that operate on projects
_pj_project_completion() {
    local -a projects
    projects=(${(f)"$(_pj_get_projects)"})

    if [[ ${#projects[@]} -gt 0 ]]; then
        _describe 'projects' projects
    else
        _message 'no projects found (run pj refresh?)'
    fi

    # Also allow help completion
    if [[ $words[-1] != "help" ]]; then
        _arguments \
            ':: :->help_option'
        case $state in
            help_option)
                _values 'help' 'help[show command help]'
                ;;
        esac
    fi
}

# Complete for project analysis commands without their own flags
_pj_project_analysis_completion() {
    if [[ $words[-1] != "help" ]]; then
        _arguments \
            ':: :->help_option'
        case $state in
            help_option)
                _values 'help' 'help[show command help]'
                ;;
        esac
    fi
}

# Complete pj new command with recipes and options (no own @flag)
_pj_new_completion() {
    local -a recipes

    recipes=(${(f)"$(_pj_get_recipes)"})

    case $CURRENT in
        2)
            if [[ ${#recipes[@]} -gt 0 ]]; then
                _describe 'recipes' recipes
            else
                _message 'no recipes available (run pj new help to see recipes)'
            fi
            ;;
        3)
            _message 'project name'
            ;;
        *)
            _arguments \
                '(-o --overwrite)'{-o,--overwrite}'[overwrite project]' \
                ':: :->help_option'
            case $state in
                help_option)
                    if [[ $words[-1] != "help" ]]; then
                        _values 'help' 'help[show command help]'
                    fi
                    ;;
            esac
            ;;
    esac
}
ZHELP

  # one generated function per flagged command: a single _arguments call
  # carrying that command's flags plus its positional handling, so flags
  # and positionals complete together without a second _arguments pass.
  while IFS=: read -r name about completion hasflags index; do
    [ "$hasflags" = "1" ] || continue
    [ "$name" = "help" ] && continue
    printf '\n# Flags declared by @flag on the %s module\n' "$name"
    printf '_pj_flags_%s() {\n' "$name"
    if [ "$completion" = "recipes" ]; then
      # recipes commands also take a recipe then a project name; flags are
      # offered whenever the current word starts with "-"
      cat <<ZRECIPES
    local cur="\${words[CURRENT]}"
    if [[ \$cur == -* ]]; then
        local -a opts
        opts=(
            '-h:show help'
            '--help:show help'
ZRECIPES
      zsh_flag_opts "$index"
      cat <<'ZRECIPES2'
        )
        _describe 'options' opts
        return
    fi
    case $CURRENT in
        2)
            local -a recipes
            recipes=(${(f)"$(_pj_get_recipes)"})
            if [[ ${#recipes[@]} -gt 0 ]]; then
                _describe 'recipes' recipes
            else
                _message 'no recipes available (run pj new help to see recipes)'
            fi
            ;;
        3)
            _message 'project name'
            ;;
        *)
            _arguments \
                ':: :->help_option'
            case $state in
                help_option)
                    _values 'help' 'help[show command help]'
                    ;;
            esac
            ;;
    esac
}
ZRECIPES2
    else
      cat <<'ZGEN'
    _arguments \
        '(-h --help)'{-h,--help}'[show help]' \
ZGEN
      zsh_flag_specs "$index"
      cat <<'ZGEN2'
        ':: :->help_option'
    case $state in
        help_option)
            _values 'help' 'help[show command help]'
            ;;
    esac
}
ZGEN2
    fi
  done < "$MODULES_FILE"

  # Initialize completion
  printf '\n# Initialize completion\n_pj "$@"\n'
}

# -- bash --------------------------------------------------------------------

emit_bash() {
  # bake the recipe directories: listing them is a plain directory scan at
  # TAB time instead of booting the whole framework
  printf '_pj_recipe_dirs=(\n'
  printf '    %s\n' "'$CUSTOM_RECIPES_PATH'"
  printf '    %s\n' "'$RECIPES_PATH'"
  printf ')\n\n'
cat <<'BHEAD'
# bash completion for pj
# Generated by src/completion/generate.sh - do not edit

_pj() {
    local cur
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    local commands
    commands="
BHEAD
  _first=1
  while IFS=: read -r name about completion hasflags index; do
    [ -z "$name" ] && continue
    if [ "$_first" -eq 1 ]; then
      printf '%s' "$name"
      _first=0
    else
      printf ' %s' "$name"
    fi
  done < "$MODULES_FILE"
  printf '\n    "\n'
  cat <<'BMID'

    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
        return 0
    fi

    case "${COMP_WORDS[1]}" in
BMID
  # flagged commands: their flags (plus help); recipes commands also keep
  # recipe completion whenever the current word is not a flag
  while IFS=: read -r name about completion hasflags index; do
    [ "$hasflags" = "1" ] || continue
    _words=$(bash_flag_words "$index")
    if [ "$name" = "help" ]; then
      # help completes command names AND its own flags
      printf '        %s)\n            COMPREPLY=( $(compgen -W "$commands -h --help %s" -- "$cur") )\n            ;;\n' "$name" "$_words"
    elif [ "$completion" = "recipes" ]; then
      printf '        %s)\n            if [[ $cur == -* ]]; then\n                COMPREPLY=( $(compgen -W "%s" -- "$cur") )\n            else\n                _pj_complete_recipes\n            fi\n            ;;\n' "$name" "$_words"
    else
      printf '        %s)\n            COMPREPLY=( $(compgen -W "help -h --help %s" -- "$cur") )\n            ;;\n' "$name" "$_words"
    fi
  done < "$MODULES_FILE"
  build_groups
  [ -n "$projects" ] && \
    printf '        %s)\n            _pj_complete_projects\n            ;;\n' "$projects"
  [ -n "$recipes" ] && \
    printf '        %s)\n            _pj_complete_recipes\n            ;;\n' "$recipes"
  [ -n "$analysis" ] && \
    printf '        %s)\n            COMPREPLY=( $(compgen -W "help" -- "$cur") )\n            ;;\n' "$analysis"
  [ -n "$leaf" ] && \
    printf '        %s)\n            ;;\n' "$leaf"
  cat <<'BTAIL'
        *)
            COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
            ;;
    esac
}

# Complete project names for commands that operate on projects
_pj_complete_projects() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local dir="${PROJECTS_PATH:-$HOME/projects}"
    local IFS=$'\n'
    COMPREPLY=( $(compgen -W "$(command ls -1 "$dir" 2>/dev/null)" -- "$cur") )
}

# Complete recipe names for pj new — plain directory scan, no framework boot
_pj_complete_recipes() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local dir r
    local -a names
    for dir in "${_pj_recipe_dirs[@]}"; do
        [ -d "$dir" ] || continue
        for r in "$dir"/*; do
            [ -f "$r" ] && [ -x "$r" ] && names+=("${r##*/}")
        done
    done
    if [ ${#names[@]} -gt 0 ]; then
        COMPREPLY=( $(compgen -W "$(printf '%s\n' "${names[@]}" | sort -u)" -- "$cur") )
    fi
}

complete -F _pj pj
BTAIL
}

# -- main ---------------------------------------------------------------------

# user plugins override core modules of the same name: keep the last line
# per name, then sort for stable, deterministic output
collect_modules > "$MODULES_FILE"
awk -F: '
  !($1 in data) { order[++n] = $1 }
  { data[$1] = $0 }
  END { for (i = 1; i <= n; i++) print data[order[i]] }
' "$MODULES_FILE" > "$MODULES_FILE.tmp"
sort -o "$MODULES_FILE" "$MODULES_FILE.tmp"
rm -f "$MODULES_FILE.tmp"

case "$TARGET" in
  bash) emit_bash ;;
  *) emit_zsh ;;
esac
