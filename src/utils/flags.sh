set_flag(){
  case "$1" in
    --silent)
      export FLAG_SILENT=1
      ;;
    --overwrite)
      export FLAG_OVERWRITE=1
      ;;
    --no-color)
      export FLAG_COLORED_OUTPUT=1
      ;;
    * )
      return $ERROR_UNKNOWN_FLAG
      ;;
  esac
  return 0
}
