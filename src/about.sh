#!/bin/sh
# src/about.sh - framework identity metadata (pj help, pj help --extended)
#
# Resolution per field: environment -> build-time stamp
# ($FRAMEWORK_PATH/src/about.local.sh, written by bin/build.sh) ->
# discovery (git remote, for dev checkouts) -> defaults below.
# Displayed lazily by the help module, so the git lookup only runs when
# help is actually shown.

[ -f "$FRAMEWORK_PATH/src/about.local.sh" ] && . "$FRAMEWORK_PATH/src/about.local.sh"

about_resolve() {
  : "${FRAMEWORK_DESCRIPTION:=Terminal Project Manager}"
  : "${FRAMEWORK_AUTHOR:=Lolokile Saidimu}"
  : "${FRAMEWORK_LICENSE:=MIT}"

  if [ -z "${FRAMEWORK_REPOSITORY:-}" ]; then
    FRAMEWORK_REPOSITORY=$(git -C "$FRAMEWORK_PATH" config --get remote.origin.url 2>/dev/null)
  fi
  case "$FRAMEWORK_REPOSITORY" in
    git@*:*) FRAMEWORK_REPOSITORY="https://github.com/${FRAMEWORK_REPOSITORY##*:}";;
    ssh://git@*/*) FRAMEWORK_REPOSITORY="https://${FRAMEWORK_REPOSITORY#ssh://git@}";;
  esac
  FRAMEWORK_REPOSITORY="${FRAMEWORK_REPOSITORY%.git}"
  : "${FRAMEWORK_REPOSITORY:=https://github.com/asaidimu/pj}"
  : "${FRAMEWORK_HOMEPAGE:=$FRAMEWORK_REPOSITORY}"

  export FRAMEWORK_DESCRIPTION FRAMEWORK_AUTHOR FRAMEWORK_LICENSE \
         FRAMEWORK_REPOSITORY FRAMEWORK_HOMEPAGE
}

about_short() {
  about_resolve
  cat <<EOF_ABOUT_SHORT
    NAME        : $FRAMEWORK_NAME
    VERSION     : $FRAMEWORK_VERSION
    DESCRIPTION : $FRAMEWORK_DESCRIPTION
    REQUIRES    : $FRAMEWORK_REQUIRED_DEPS
EOF_ABOUT_SHORT
}

about_full() {
  about_resolve
  bold ABOUT
  printf "\n"
  about_short
  printf "\n"
  bold "AUTHORSHIP & LICENSE"
  printf "\n    AUTHOR      : %s" "$FRAMEWORK_AUTHOR"
  printf "\n    LICENSE     : %s\n" "$FRAMEWORK_LICENSE"
  bold SOURCE
  printf "\n    HOMEPAGE    : %s" "$FRAMEWORK_HOMEPAGE"
  printf "\n    REPOSITORY  : %s" "$FRAMEWORK_REPOSITORY"
  printf "\n    RELEASE     : %s\n" "${FRAMEWORK_RELEASE:-development}"
  bold INSTALL
  printf "\n    PATH        : %s" "$FRAMEWORK_PATH"
  printf "\n    CONFIG      : %s" "$FRAMEWORK_CONFIG"
  printf "\n    PROJECTS    : %s\n" "$PROJECTS_PATH"
}
