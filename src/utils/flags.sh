parse_flag() {
  case "$1" in
    -s|--silent)
      export FLAG_SILENT=1
      return 0
      ;;
    -o|--overwrite)
      export FLAG_OVERWRITE=1
      return 0
      ;;
    -h|--help)
      global_help
      exit
      ;;
    -v|--version)
      show_version
      exit
      ;;
    *)
      return $NOT_A_FLAG
      ;;
  esac
}
