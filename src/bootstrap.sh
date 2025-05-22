export FRAMEWORK_CONFIG_DIR="$HOME/.config/$FRAMEWORK_NAME"
export FRAMEWORK_CONFIG="$FRAMEWORK_CONFIG_DIR/env.sh"

export FRAMEWORK_SOURCE_PATH="$FRAMEWORK_PATH/src"
export UTILITIES_PATH="$FRAMEWORK_SOURCE_PATH/utils"

# load utilities
. "$UTILITIES_PATH/index.sh"

# -- set up framework env --
. "$FRAMEWORK_PATH/src/env.sh"

# -- start --
. "$FRAMEWORK_PATH/src/index.sh"
