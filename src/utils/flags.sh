set_flag(){
  case "$1" in
    --silent | -s)
      export FLAG_SILENT=1
      ;;
    --overwrite | -o )
      export FLAG_OVERWRITE=1
      ;;
    --help | -h )
        global_help
        exit
      ;;
    --version | -v )
        show_version
        exit
        ;;
    * )
      return $ERROR_UNKNOWN_FLAG
      ;;
  esac
  return 0
}
