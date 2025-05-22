[ -z "$DEBUG" ] && panic '4$DEBUG is not set!' 1
[ -z "$DEBUG_MODULE_NAME" ] && panic '$DEBUG_MODULE_NAME is not set!' 1

[ -z "$ERROR" ] && panic '$ERROR is not set!' 1
[ -z "$ERROR_ILLEGAL_OP" ] && panic '$ERROR_ILLEGAL_OP is not set!' 1
[ -z "$ERROR_INVALID_OPTIONS" ] && panic '$ERROR_INVALID_OPTIONS is not set!' 1
[ -z "$ERROR_PROJECT_EXISTS" ] && panic '$ERROR_PROJECT_EXISTS is not set!' 1
[ -z "$ERROR_PROJECT_NOT_EXISTS" ] && panic '$ERROR_PROJECT_NOT_EXISTS is not set!' 1
[ -z "$ERROR_UNKNOWN_FLAG" ] && panic '$ERROR_UNKNOWN_FLAG is not set!' 1
[ -z "$ERROR_UNKNOWN_PLUGIN" ] && panic '$ERROR_UNKNOWN_PLUGIN is not set!' 1
[ -z "$ERROR_UNKNOWN_PROJECT" ] && panic '$ERROR_UNKNOWN_PROJECT is not set!' 1

[ -z "$FLAG_COLORED_OUTPUT" ] && panic '$FLAG_COLORED_OUTPUT is not set!' 1
[ -z "$FLAG_OVERWRITE" ] && panic '$FLAG_OVERWRITE is not set!' 1
[ -z "$FLAG_SILENT" ] && panic '$FLAG_SILENT is not set!' 1

[ -z "$FRAMEWORK_ARGUMENTS" ] && panic '$FRAMEWORK_ARGUMENTS is not set!' 1
[ -z "$FRAMEWORK_BIN" ] && panic '$FRAMEWORK_BIN is not set!' 1
[ -z "$FRAMEWORK_CONFIG_DIR" ] && panic '$FRAMEWORK_CONFIG_DIR is not set!' 1
[ -z "$FRAMEWORK_CONFIG" ] && panic '$FRAMEWORK_CONFIG is not set!' 1
[ -z "$FRAMEWORK_MODULE_NAME" ] && panic '$FRAMEWORK_MODULE_NAME is not set!' 1
[ -z "$FRAMEWORK_NAME" ] && panic '$FRAMEWORK_NAME is not set!' 1
[ -z "$FRAMEWORK_PATH" ] && panic '$FRAMEWORK_PATH is not set!' 1
[ -z "$FRAMEWORK_ROUTE" ] && panic '$FRAMEWORK_ROUTE is not set!' 1
[ -z "$FRAMEWORK_SOURCE_PATH" ] && panic '$FRAMEWORK_SOURCE_PATH is not set!' 1

[ -z "$PLUGINS_PATH" ] && panic '$PLUGINS_PATH is not set!' 1
[ -z "$RECIPES_PATH" ] && panic '$RECIPES_PATH is not set!' 1
[ -z "$CUSTOM_PLUGINS_PATH" ] && panic '$CUSTOM_PLUGINS_PATH is not set!' 1
[ -z "$CUSTOM_RECIPES_PATH" ] && panic '$CUSTOM_RECIPES_PATH is not set!' 1
[ -z "$PROJECTS_DATA" ] && panic '$PROJECTS_DATA is not set!' 1
[ -z "$PROJECTS_PATH" ] && panic '$PROJECTS_PATH is not set!' 1
[ -z "$PROJECTS_LIST" ] && panic '$PROJECTS_LIST is not set!' 1
[ -z "$UTILITIES_PATH" ] && panic '$UTILITIES_PATH is not set!' 1
[ -z "$ARCHIVE_PATH" ] && panic '$ARCHIVE_PATH is not set!' 1
[ -z "$ASSET_PATH" ] && panic '$ASSET_PATH is not set!' 1
[ -z "$PROJECTS_LIST_GENERATOR" ] && panic '$PROJECTS_LIST_GENERATOR is not defined!' 1
[ ! -d "$PROJECTS_PATH" ] && panic "$PROJECTS_PATH does not exist !" 1

[ ! -d "$FRAMEWORK_CONFIG_DIR" ] && mkdir -p "$FRAMEWORK_CONFIG_DIR"
[ ! -d "$FRAMEWORK_TMP" ] && mkdir -p "$FRAMEWORK_TMP"
[ ! -d "$FRAMEWORK_DATA" ] && mkdir -p "$FRAMEWORK_DATA"
[ ! -e "$PROJECTS_LIST_GENERATOR" ] && panic "$PROJECT_LIST_GENERATOR does not exist !" 1

# -- COMMAND CHECKS --
REQUIRED_COMMANDS="sh tmux fzf tree awk sed grep curl tar mkdir ls cat date read printf echo"
for cmd in $REQUIRED_COMMANDS; do
  check_command "$cmd"
  [ $? -eq 0 ] || panic "$cmd is required but not installed!" 1
done
