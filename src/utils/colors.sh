bold(){
  [ $FLAG_COLORED_OUTPUT -eq 1 ] && { printf $@; return; }
  printf "\033[1;37;48m${@}\033[0m";
}
bold_blue(){
  [ $FLAG_COLORED_OUTPUT -eq 1 ] && { printf $@; return; }
  printf "\033[1;34;48m${@}\033[0m";
}
bold_cyan(){
  [ $FLAG_COLORED_OUTPUT -eq 1 ] && { printf $@; return; }
  printf "\033[1;36;48m${@}\033[0m";
}
bold_green(){
  [ $FLAG_COLORED_OUTPUT -eq 1 ] && { printf $@; return; }
  printf "\033[1;32;48m${@}\033[0m";
}
bold_grey(){
  [ $FLAG_COLORED_OUTPUT -eq 1 ] && { printf $@; return; }
  printf "\033[1;30;48m${@}\033[0m";
}
bold_red(){
  [ $FLAG_COLORED_OUTPUT -eq 1 ] && { printf $@; return; }
  printf "\033[1;31;48m${@}\033[0m";
}
bold_yellow(){
  [ $FLAG_COLORED_OUTPUT -eq 1 ] && { printf $@; return; }
  printf "\033[1;33;48m${@}\033[0m";
}
blue(){
  [ $FLAG_COLORED_OUTPUT -eq 1 ] && { printf $@; return; }
  printf "\033[0;34;48m${@}\033[0m";
}
cyan(){
  [ $FLAG_COLORED_OUTPUT -eq 1 ] && { printf $@; return; }
  printf "\033[0;36;48m${@}\033[0m";
}
green(){
  [ $FLAG_COLORED_OUTPUT -eq 1 ] && { printf $@; return; }
  printf "\033[0;32;48m${@}\033[0m";
}
grey(){
  [ $FLAG_COLORED_OUTPUT -eq 1 ] && { printf $@; return; }
  printf "\033[0;37;48m${@}\033[0m";
}
red(){
  [ $FLAG_COLORED_OUTPUT -eq 1 ] && { printf $@; return; }
  printf "\033[0;31;48m${@}\033[0m";
}
yellow(){
  [ $FLAG_COLORED_OUTPUT -eq 1 ] && { printf $@; return; }
  printf "\033[0;33;48m${@}\033[0m";
}
header(){
  [ $FLAG_COLORED_OUTPUT -eq 1 ] && { printf $@; return; }
  printf "\033[35m${@}\033[0m";
}
underline(){
  [ $FLAG_COLORED_OUTPUT -eq 1 ] && { printf $@; return; }
  printf "\033[4m${@}\033[0m";
}
