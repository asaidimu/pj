#!/usr/bin/env sh

_set_up(){
  export VERSION=$(git describe --exact-match --abbrev=0 --tags 2>/dev/null)
  export SCRIPT="install.sh"
  export SCRIPT_URL="https://github.com/${GITHUB_REPOSITORY}"
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

_update_template(){
  template_file="$1"; shift;

  for opt in $@; do
    key=$(echo $opt | sed -E "s/(\w+*):.*$/\\\{\\\{\1\\\}\\\}/g");
    val=$(echo $opt | sed -E "s/\w+*:(.*$)/\1/g");
    sed -E "s|${key}|${val}|g" -i $template_file
  done
}

_build(){
   cp assets/template.sh install.sh
  _update_template install.sh $(cat <<EOF
version:$VERSION
url:$SCRIPT_URL
EOF
)
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
