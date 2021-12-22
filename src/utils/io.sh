time_stamp(){
  echo "$(bold_grey `date +%H:%M:%S`)"
}

log(){
  [ $FLAG_SILENT -eq 0 ] || return

  title=$(bold "$FRAMEWORK_NAME @ $FRAMEWORK_MODULE_NAME")
  stamp=$(time_stamp)

  out="$(bold '[')$title $stamp$(bold ']') $@"

  echo "$out"
}

inform(){  echo "$(bold_blue  info)" "${@}"; }
success(){ echo "$(bold_green  success)" "${@}";}
warn(){    echo "$(bold_yellow  warning)" "${@}";}

debug(){
  silent=$FLAG_SILENT
  export FLAG_SILENT=0
  log "$(bold_blue   debug)" "${@}";
  export FLAG_SILENT=$silent;
}

error(){
  export FLAG_SILENT=0
  [ -n "$1" ] && message=$1 || message="an unexpected error occured !"
  [ -n "$2" ] && error=$2 || error=$ERROR

  echo "$(bold_red error)" "${message}";
  exit $error
}

notify(){
  [ $FLAG_SILENT -eq 0 ] || return

  status=$?; success_msg="$1"; failure_msg="$2";

  [ $status -eq 0 ] && {
    success "$success_msg" && return
  } || {
    error "$failure_msg" "$status"
  }
}
