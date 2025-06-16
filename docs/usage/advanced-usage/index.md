# Advanced Usage

This section covers more advanced features of PJ, including its extensibility mechanisms.

### Custom Plugins (Commands)
PJ's modular design allows you to create your own commands that integrate seamlessly with the framework.

#### Structure
Custom plugins are simple shell scripts placed in `~/.config/pj/plugins/<your-command-name>/index.sh`. They must be executable.

**Example**: `~/.config/pj/plugins/hello/index.sh`
```sh
#!/bin/sh

# summary: Says hello from custom plugin

help() {
  cat <<EOF
$(bold "COMMAND"): $(blue hello)
    Says hello from your custom plugin.

$(bold USAGE)
    pj hello
EOF
}

init() {
  case "$1" in
    help)
      help
      ;;
    *)
      printf "Hello from custom plugin!\n"
      ;;
  esac
}

init "$@"
```

After creating the file, make it executable:
```sh
chmod +x ~/.config/pj/plugins/hello/index.sh
```
Now you can run it:
```sh
pj hello
```

#### Plugin Precedence
If a custom plugin has the same name as a core PJ command (e.g., `pj open`), the custom plugin in `~/.config/pj/plugins/` will take precedence.

### Custom Recipes
Extend the `pj new` command's capabilities by adding your own project templates. Recipes are just executable shell scripts.

#### Structure
Custom recipes are executable files (without extensions) located in `~/.config/pj/plugins/recipes/`.

**Example**: `~/.config/pj/plugins/recipes/python-flask`
```sh
#!/bin/sh
# summary: Creates a basic Python Flask project

PROJECT_PATH="$1"

mkdir -p "$PROJECT_PATH"
cd "$PROJECT_PATH"

echo "# My Flask Project" > README.md

cat <<EOL > app.py
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello, World!'

if __name__ == '__main__':
    app.run(debug=True)
EOL

python3 -m venv venv
success "Python Flask project created at $PROJECT_PATH"
```

Make the recipe executable:
```sh
chmod +x ~/.config/pj/plugins/recipes/python-flask
```
Then use it:
```sh
pj new python-flask my-flask-app
```

### Custom Project List Generator
You can override how PJ discovers projects by providing your own `generator` script.

#### Structure
Place an executable script at `~/.config/pj/plugins/generator`.

**Example**: `~/.config/pj/plugins/generator`
```sh
#!/bin/sh
# Outputs project paths, one per line

find "$HOME/personal-code" -maxdepth 1 -type d -name "*proj" >> "$PROJECTS_LIST"
find "$HOME/work/client-projects" -maxdepth 1 -type d -name "*" >> "$PROJECTS_LIST"
```

Make it executable:
```sh
chmod +x ~/.config/pj/plugins/generator
```
PJ will now use this script when `pj open` or `pj refresh` is called.

### Command Lifecycle Hooks
PJ provides `pre_hook.sh` and `post_hook.sh` scripts that can be executed before and after a command's main `index.sh` script, respectively.

#### `pre_hook.sh`
Runs before the main command logic. Useful for pre-checks, logging, or modifying arguments.

**Location**: `src/module/<command>/pre_hook.sh` or `~/.config/pj/plugins/<command>/pre_hook.sh`.
**Arguments**: Receives all arguments passed to the main command.

#### `post_hook.sh`
Runs after the main command logic, regardless of success or failure. Useful for cleanup, logging, or triggering subsequent actions.

**Location**: `src/module/<command>/post_hook.sh` or `~/.config/pj/plugins/<command>/post_hook.sh`.
**Arguments**: Receives all original arguments passed to the main command.

**Example**: Auto-refreshing project list after `pj new` (from `src/module/new/post_hook.sh`)
```sh
#!/bin/sh
run_command refresh
exit 0
```
This ensures that newly created projects are immediately available for fuzzy selection without manual `pj refresh`.

### Environment Variables
Beyond `PROJECTS_PATH`, you can override many internal PJ variables by setting them in `~/.config/pj/env.sh`.

**Common variables to override:**
*   `PLUGINS_PATH`, `RECIPES_PATH`: Change where PJ looks for core plugins/recipes (advanced use).
*   `FRAMEWORK_LOGS`: Customize the log file path.
*   `FLAG_COLORED_OUTPUT`: Disable colored output by setting to `1`.

**Example `~/.config/pj/env.sh`**:
```sh
export PROJECTS_PATH="$HOME/my_dev_projects"
export FRAMEWORK_LOGS="$HOME/pj_activity.log"
export FLAG_COLORED_OUTPUT=1 # Disables colors in output
```

---
### 🤖 AI Agent Guidance

```json
{
  "decisionPoints": [
    "IF extending_command_behavior THEN create_file(\"~/.config/pj/plugins/<command>/pre_hook.sh\") OR create_file(\"~/.config/pj/plugins/<command>/post_hook.sh\")",
    "IF overriding_project_discovery THEN create_executable_script(\"~/.config/pj/plugins/generator\") that_outputs_paths",
    "IF global_config_change_required THEN edit_file(\"~/.config/pj/env.sh\")"
  ],
  "verificationSteps": [
    "Check: `pj hello` after creating custom plugin → Expected: \"Hello from custom plugin!\"",
    "Check: `ls $PROJECTS_PATH/my-flask-app/app.py` after `pj new python-flask my-flask-app` → Expected: File exists with Flask code",
    "Check: `pj open` list contains projects from custom generator paths → Expected: Projects from `find \"$HOME/personal-code\"` are listed.",
    "Check: `cat /tmp/$USER/pj/<date>.log` after hook execution → Expected: Log entries from hook script"
  ],
  "quickPatterns": [
    "Pattern: Custom Plugin: `mkdir -p ~/.config/pj/plugins/mycmd && echo '#!/bin/sh\\ninit(){ printf \"Hello\\n\"; }\\ninit \"$@\"' > ~/.config/pj/plugins/mycmd/index.sh && chmod +x ~/.config/pj/plugins/mycmd/index.sh`",
    "Pattern: Custom Recipe: `echo '#!/bin/sh\\nmkdir \"$1\"' > ~/.config/pj/plugins/recipes/myrecipe && chmod +x ~/.config/pj/plugins/recipes/myrecipe`",
    "Pattern: Set Env Var: `echo 'export MY_VAR=\"value\"' >> ~/.config/pj/env.sh`"
  ],
  "diagnosticPaths": [
    "Error: HookNotExecuting -> Symptom: Hook script not running -> Check: Hook file path, execute permissions, `_run_hook` call in `src/index.sh` -> Fix: Correct path, `chmod +x`, verify `_run_hook` logic.",
    "Error: CustomGeneratorNotUsed -> Symptom: `pj open` lists default paths -> Check: `~/.config/pj/plugins/generator` existence and execute permissions -> Fix: Ensure file exists and is executable."
  ]
}
```

---
*Generated using Gemini AI on 6/16/2025, 8:30:37 PM. Review and refine as needed.*