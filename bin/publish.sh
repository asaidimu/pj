#!/usr/bin/env sh

_set_up(){
  export VERSION=$(git describe --exact-match --abbrev=0 --tags 2>/dev/null)
  export SCRIPT="install.sh"
}

_commit_is_tagged () {
    tag=$(git describe --tags 2>&1)
    echo $tag | grep -E "fatal|\-g" 2>&1 > /dev/null && {
        return 1
    } || {
        return 0
    }
}

_release(){
  export GITHUB_TOKEN="${INPUT_GH_TOKEN}"
  gh release create "${VERSION}" --title "${VERSION}" "${SCRIPT}"
}

_build(){
  [ -e "./install.sh" ] || "./bin/build.sh"
}

_main(){
    if _commit_is_tagged; then
        _set_up
        _build
        _release
    else
        echo "commit not tagged, not releasing new document version"
        exit 0
    fi
}

_main
