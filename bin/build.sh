#!/usr/bin/env sh

origin=$(git remote get-url origin | sed -E "s|^.*\.com:(.*)\..*$|\1|g")
GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-"${origin}"}
export VERSION=$(git describe --exact-match --abbrev=0 --tags 2>/dev/null)
export SCRIPT_URL="https://github.com/${GITHUB_REPOSITORY}"

_update_template(){
  template_file="$1"; shift;

  for opt in $@; do
    key=$(echo "$opt" | sed -E "s/(\w+*):.*$/\\\{\\\{\1\\\}\\\}/g");
    val=$(echo "$opt" | sed -E "s/\w+*:(.*$)/\1/g");
    sed -E "s|${key}|${val}|g" -i $template_file
  done
}

_build(){
   cp assets/installer.sh install.sh
   tar --exclude="./package.json" --exclude="./yarn.lock" -Jcf pj.tar.xz ./*
   _update_template "./install.sh" "version:$VERSION" "url:$SCRIPT_URL"
   echo "export SOURCE=\$(cat <<EOF" >> "./install.sh"
    base64 "./pj.tar.xz" >> "./install.sh"
   cat >> "./install.sh" <<END
EOF
)

_main \$@
END

    rm -rf pj.tar.xz
}

_build
