#!/bin/sh
# --------
# summary: creates a project from a recipe
# completion: recipes
# --------
# @about   creates a project from a recipe, or scaffolds a script/module
# @usage   pj new <recipe> <project-name>
#          pj new --script <file.sh>
#          pj new --module <name>
# @flag    -o, --overwrite       overwrite an existing project, script or module
# @flag    --script=<file.sh>    scaffold a standalone script in the current directory
# @flag    --module=<name>       scaffold a user module under the plugins directory
# @flag    --names               list recipe names, one per line (used by completions)
# @arg     [<recipe>]            recipe name (see the documentation for built-in recipes)
# @arg     [<project-name>]      name of the project to create

# scaffold a standalone script from the built-in pragma template
scaffold_script() {
  target="$1"
  tmpl="$FRAMEWORK_PATH/src/module/new/script.tmpl"

  [ -n "$target" ] || {
    app_help
    panic "--script needs a file name, e.g. --script program.sh" "$ERROR_INVALID_OPTIONS"
  }

  [ -f "$tmpl" ] || panic "script template missing at $tmpl" "$ERROR_ILLEGAL_OP"

  [ -e "$target" ] && [ "$FLAG_OVERWRITE" -ne 1 ] && {
    panic "$target already exists (use -o to overwrite)" "$ERROR_PROJECT_EXISTS"
  }

  cp "$tmpl" "$target" && chmod +x "$target" || {
    panic "could not create $target" "$ERROR_ILLEGAL_OP"
  }

  success "Created $(green "$target")"
  inform "Edit the # @... block at the top to declare your CLI, then run: $target --help"
}

# scaffold a user module (plugin) from the built-in template
scaffold_module() {
  name="$1"
  tmpl="$FRAMEWORK_PATH/src/module/new/module.tmpl"

  [ -n "$name" ] || {
    app_help
    panic "--module needs a name, e.g. --module greet" "$ERROR_INVALID_OPTIONS"
  }

  case "$name" in
    -*|*/*|.|..|recipes|*[!A-Za-z0-9_-]*)
      panic "invalid module name: $name (letters, digits, - and _ only)" "$ERROR_INVALID_OPTIONS"
      ;;
  esac

  [ -f "$tmpl" ] || panic "module template missing at $tmpl" "$ERROR_ILLEGAL_OP"

  dir="$CUSTOM_PLUGINS_PATH/$name"
  target="$dir/index.sh"

  [ -e "$target" ] && [ "$FLAG_OVERWRITE" -ne 1 ] && {
    panic "$target already exists (use -o to overwrite)" "$ERROR_PROJECT_EXISTS"
  }

  mkdir -p "$dir" || {
    panic "could not create $dir" "$ERROR_ILLEGAL_OP"
  }

  sed "s/__NAME__/$name/g" "$tmpl" > "$target" || {
    panic "could not create $target" "$ERROR_ILLEGAL_OP"
  }

  success "Created module $(green "$name") at $dir"
  inform "Declare the CLI in the # @... block, then run: $FRAMEWORK_NAME $name"
}

# machine-readable recipe list for shell completions: user recipes first,
# then built-ins, deduped by name
list_recipes() {
  for dir in "$CUSTOM_RECIPES_PATH" "$RECIPES_PATH"; do
    [ -d "$dir" ] || continue
    for r in "$dir"/*; do
      [ -f "$r" ] && [ -x "$r" ] && printf '%s\n' "${r##*/}"
    done
  done | sort -u
}

parse_args() {
  plugin="$1"
  _project="$2"

  [ -z "$plugin" ] && {
    app_help
    panic "no input provided!" "$ERROR_INVALID_OPTIONS"
  }

  [ -e "$CUSTOM_RECIPES_PATH/$1" ] && plugin="$CUSTOM_RECIPES_PATH/$1" || plugin="$RECIPES_PATH/$1"

  if [ -x "$plugin" ]; then
    export PROJECT_PLUGIN="$plugin"
  elif [ -z "$_project" ]; then
    export PROJECT_PLUGIN="$RECIPES_PATH/base"
    _project="$1"
    inform "Using base recipe"
  else
    panic "Recipe $1 not found!" "$ERROR_UNKNOWN_PLUGIN"
  fi

  [ -z "$_project" ] && {
    app_help
    panic "project name not provided!" "$ERROR_UNKNOWN_PROJECT"
  } || {
    setup "$_project"
  }

  [ "$FLAG_OVERWRITE" -eq 1 ] && return 0

  [ -d "$PROJECT_PATH" ] && {
    panic "project $_project found under $PROJECTS_PATH" "$ERROR_PROJECT_EXISTS"
  }

  return 0
}

main() {
  # accept -o both as a global flag (pj -o new ...) and as a module flag
  # (pj new -o ...)
  [ -n "${OPT_OVERWRITE:-}" ] && export FLAG_OVERWRITE=1

  if [ -n "${OPT_NAMES:-}" ]; then
    list_recipes
    return $?
  fi

  if [ -n "${OPT_MODULE:-}" ]; then
    scaffold_module "$OPT_MODULE"
    return $?
  fi

  if [ -n "${OPT_SCRIPT:-}" ]; then
    scaffold_script "$OPT_SCRIPT"
    return $?
  fi

  parse_args "$@" && {
    warn_missing_deps "recipe $(basename "$PROJECT_PLUGIN")" "$PROJECT_PLUGIN"
    . "$PROJECT_PLUGIN"
  }
}

init() {
  app_start "$@"
}

init "$@"
