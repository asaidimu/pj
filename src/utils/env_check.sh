[ -z $DEBUG ] && error '$DEBUG is not set!' 1
[ -z $DEBUG_MODULE_NAME ] && error '$DEBUG_MODULE_NAME is not set!' 1

[ -z $ERROR ] && error '$ERROR is not set!' 1
[ -z $ERROR_ILLEGAL_OP ] && error '$ERROR_ILLEGAL_OP is not set!' 1
[ -z $ERROR_INVALID_OPTIONS ] && error '$ERROR_INVALID_OPTIONS is not set!' 1
[ -z $ERROR_PROJECT_EXISTS ] && error '$ERROR_PROJECT_EXISTS is not set!' 1
[ -z $ERROR_PROJECT_NOT_EXISTS ] && error '$ERROR_PROJECT_NOT_EXISTS is not set!' 1
[ -z $ERROR_UNKNOWN_FLAG ] && error '$ERROR_UNKNOWN_FLAG is not set!' 1
[ -z $ERROR_UNKNOWN_PLUGIN ] && error '$ERROR_UNKNOWN_PLUGIN is not set!' 1
[ -z $ERROR_UNKNOWN_PROJECT ] && error '$ERROR_UNKNOWN_PROJECT is not set!' 1

[ -z $FLAG_COLORED_OUTPUT ] && error '$FLAG_COLORED_OUTPUT is not set!' 1
[ -z $FLAG_OVERWRITE ] && error '$FLAG_OVERWRITE is not set!' 1
[ -z $FLAG_SILENT ] && error '$FLAG_SILENT is not set!' 1

[ -z $FRAMEWORK_ARGUMENTS ] && error '$FRAMEWORK_ARGUMENTS is not set!' 1
[ -z $FRAMEWORK_BIN ] && error '$FRAMEWORK_BIN is not set!' 1
[ -z $FRAMEWORK_CONFIG_DIR ] && error '$FRAMEWORK_CONFIG_DIR is not set!' 1
[ -z $FRAMEWORK_CONFIG ] && error '$FRAMEWORK_CONFIG is not set!' 1
[ -z $FRAMEWORK_MODULE_NAME ] && error '$FRAMEWORK_MODULE_NAME is not set!' 1
[ -z $FRAMEWORK_NAME ] && error '$FRAMEWORK_NAME is not set!' 1
[ -z $FRAMEWORK_PATH ] && error '$FRAMEWORK_PATH is not set!' 1
[ -z $FRAMEWORK_ROUTE ] && error '$FRAMEWORK_ROUTE is not set!' 1
[ -z $FRAMEWORK_SOURCE_PATH ] && error '$FRAMEWORK_SOURCE_PATH is not set!' 1

[ -z $PLUGINS_PATH ] && error '$PLUGINS_PATH is not set!' 1
[ -z $RECIPES_PATH ] && error '$RECIPES_PATH is not set!' 1
[ -z $CUSTOM_PLUGINS_PATH ] && error '$CUSTOM_PLUGINS_PATH is not set!' 1
[ -z $CUSTOM_RECIPES_PATH ] && error '$CUSTOM_RECIPES_PATH is not set!' 1
[ -z $PROJECTS_DATA ] && error '$PROJECTS_DATA is not set!' 1
[ -z $PROJECTS_PATH ] && error '$PROJECTS_PATH is not set!' 1
[ -z $PROJECTS_LIST ] && error '$PROJECTS_LIST is not set!' 1
[ -z $UTILITIES_PATH ] && error '$UTILITIES_PATH is not set!' 1
[ -z $ARCHIVE_PATH ] && error '$ARCHIVE_PATH is not set!' 1
[ -z $ASSET_PATH ] && error '$ASSET_PATH is not set!' 1
[ -z $PROJECTS_LIST_GENERATOR ] && error '$PROJECTS_LIST_GENERATOR is not defined!'
[ -d $PROJECTS_PATH ] || error "$PROJECTS_PATH does not exist !"

[ -d $FRAMEWORK_CONFIG_DIR ] || mkdir -p "$FRAMEWORK_CONFIG_DIR"
[ -d $FRAMEWORK_TMP ] || mkdir -p "$FRAMEWORK_TMP"
[ -d $FRAMEWORK_DATA ] || mkdir -p "$FRAMEWORK_DATA"
[ -e $PROJECTS_LIST_GENERATOR ] || error "$PROJECT_LIST_GENERATOR does not exist !"
