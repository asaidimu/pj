#!/bin/sh
# src/utils/colors.sh - ANSI color helpers
#
# Colors are controlled by FLAG_COLORED_OUTPUT (1 = colored, 0 = plain).
# It is auto-detected from the TTY in flags.sh; --no-color forces it off.
# When sourced outside the framework the same TTY detection applies here.

# TTY detection must NOT run inside command substitution ($( )) — there
# fd 1 is a pipe and -t is always false. Test at the current level.
[ -n "${FLAG_COLORED_OUTPUT+x}" ] || {
  if [ -t 1 ]; then
    FLAG_COLORED_OUTPUT=1
  else
    FLAG_COLORED_OUTPUT=0
  fi
}

bold(){
  [ "$FLAG_COLORED_OUTPUT" -eq 1 ] || { printf '%s' "${*}"; return; }
  printf "\033[1;37;48m%s\033[0m" "${*}";
}
bold_blue(){
  [ "$FLAG_COLORED_OUTPUT" -eq 1 ] || { printf '%s' "${*}"; return; }
  printf "\033[1;34;48m%s\033[0m" "${*}";
}
bold_cyan(){
  [ "$FLAG_COLORED_OUTPUT" -eq 1 ] || { printf '%s' "${*}"; return; }
  printf "\033[1;36;48m%s\033[0m" "${*}";
}
bold_green(){
  [ "$FLAG_COLORED_OUTPUT" -eq 1 ] || { printf '%s' "${*}"; return; }
  printf "\033[1;32;48m%s\033[0m" "${*}";
}
bold_grey(){
  [ "$FLAG_COLORED_OUTPUT" -eq 1 ] || { printf '%s' "${*}"; return; }
  printf "\033[1;30;48m%s\033[0m" "${*}";
}
bold_red(){
  [ "$FLAG_COLORED_OUTPUT" -eq 1 ] || { printf '%s' "${*}"; return; }
  printf "\033[1;31;48m%s\033[0m" "${*}";
}
bold_yellow(){
  [ "$FLAG_COLORED_OUTPUT" -eq 1 ] || { printf '%s' "${*}"; return; }
  printf "\033[1;33;48m%s\033[0m" "${*}";
}
blue(){
  [ "$FLAG_COLORED_OUTPUT" -eq 1 ] || { printf '%s' "${*}"; return; }
  printf "\033[0;34;48m%s\033[0m" "${*}";
}
cyan(){
  [ "$FLAG_COLORED_OUTPUT" -eq 1 ] || { printf '%s' "${*}"; return; }
  printf "\033[0;36;48m%s\033[0m" "${*}";
}
green(){
  [ "$FLAG_COLORED_OUTPUT" -eq 1 ] || { printf '%s' "${*}"; return; }
  printf "\033[0;32;48m%s\033[0m" "${*}";
}
grey(){
  [ "$FLAG_COLORED_OUTPUT" -eq 1 ] || { printf '%s' "${*}"; return; }
  printf "\033[0;37;48m%s\033[0m" "${*}";
}
red(){
  [ "$FLAG_COLORED_OUTPUT" -eq 1 ] || { printf '%s' "${*}"; return; }
  printf "\033[0;31;48m%s\033[0m" "${*}";
}
yellow(){
  [ "$FLAG_COLORED_OUTPUT" -eq 1 ] || { printf '%s' "${*}"; return; }
  printf "\033[0;33;48m%s\033[0m" "${*}";
}
header(){
  [ "$FLAG_COLORED_OUTPUT" -eq 1 ] || { printf '%s' "${*}"; return; }
  printf "\033[35m%s\033[0m" "${*}";
}
underline(){
  [ "$FLAG_COLORED_OUTPUT" -eq 1 ] || { printf '%s' "${*}"; return; }
  printf "\033[4m%s\033[0m" "${*}";
}
