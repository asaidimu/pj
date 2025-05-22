set_flag() {
  case "$1" in
    -s|--silent)
      export FLAG_SILENT=1
      ;;
    -o|--overwrite)
      export FLAG_OVERWRITE=1
      ;;
    -h|--help)
      global_help
      ;;
    -v|--version)
      show_version
      ;;
    *)
      return $NOT_A_FLAG
      ;;
  esac
}
