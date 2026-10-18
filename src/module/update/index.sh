# --------
# summary: upgrades the framework
# requires: curl jq
# --------
# @about   upgrades the framework
# @usage   pj update

ERROR_MSG="Update failed! Check $(bold "$FRAMEWORK_LOGS") for details."

check_update() {
  sleep_frac 0.3
  repo=$(echo "$FRAMEWORK_URL" | sed -E "s/.*com.//g")
  json=$(curl -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$repo/releases/latest")

  if [ $? -ne 0 ]; then
      return 1
  fi

  next=$(echo "$json" | jq ".tag_name" | sed "s/\"//g")

  if [ "$next" = "$FRAMEWORK_VERSION" ]; then
    return 0
  else
    echo "$next" > "$FRAMEWORK_TMP/pj_upgrade"
    return 2
  fi
}

main() {
  sleep_frac 0.2
  banner

  check_update &
  pid=$!
  load "Checking for updates" "Network request complete" "$pid"
  wait $pid
  version=$?

  if [ "$version" -eq 0 ]; then
    success "Already at latest version"
  elif [ "$version" -eq 1 ]; then
    warn "Could not get latest version information."
    panic "$ERROR_MSG"
  else
    next=$(cat "$FRAMEWORK_TMP/pj_upgrade") && rm -f "$FRAMEWORK_TMP/pj_upgrade"

    script=$(mktemp "$FRAMEWORK_TMP/pj-update.XXXXXX")
    curl -fsL "$FRAMEWORK_URL/releases/download/${next}/install.sh" --output "$script" >/dev/null &
    pid=$!
    load "Downloading updates" "$pid"
    wait $pid
    dl_status=$?

    if [ "$dl_status" -ne 0 ] || [ ! -s "$script" ]; then
      rm -f "$script"
      warn "Could not update framework."
      panic "$ERROR_MSG"
    fi

    sh "$script" > /dev/null &
    pid=$!
    load "Installing updates" "$pid"
    wait $pid
    install_status=$?
    rm -f "$script"

    if [ "$install_status" -ne 0 ]; then
      warn "Could not update framework."
      panic "$ERROR_MSG"
    fi

    # patch the version stamp in the installed binary (portable in-place edit).
    # mktemp creates mode 600 and mv preserves it, so restore +x after the swap.
    _pj_bin=$(command -v pj) || panic "$ERROR_MSG"
    _patched=$(mktemp "$FRAMEWORK_TMP/pj-update.XXXXXX")
    sed -E "s/(VERSION=.)${FRAMEWORK_VERSION}(.)/\1${next}\2/g" "$_pj_bin" > "$_patched" \
      && mv "$_patched" "$_pj_bin" \
      || { rm -f "$_patched"; panic "$ERROR_MSG"; }
    chmod +x "$_pj_bin" 2>/dev/null || :
    success "Upgraded to $(bold "$next")"
  fi
}

init() {
  app_start "$@"
}

init "$@"
