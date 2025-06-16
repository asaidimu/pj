# Task-Based Guide

This guide provides practical steps for common tasks you'll perform with PJ.

### 1. Managing Projects

#### Creating a New Project
To start a new project, use the `new` command with a recipe. The `base` recipe is a good starting point.

**Steps**:
1.  Decide on your project name (e.g., `my-cool-project`).
2.  Choose a recipe. If unsure, use `base`.
3.  Execute the command:
    ```sh
    pj new base my-cool-project
    ```

#### Opening a Project in Tmux
PJ makes it easy to jump into your project's environment.

**Steps**:
1.  Simply run the `open` command:
    ```sh
    pj open
    ```
2.  An interactive `fzf` menu will appear. Start typing to filter projects.
3.  Select your project using `Tab` or `Arrow` keys and press `Enter`.
4.  PJ will open (or attach to) a `tmux` session for that project.

#### Archiving a Project
When a project is no longer active but you want to keep a backup, archive it.

**Steps**:
1.  Identify the project you wish to archive (e.g., `old-legacy-app`).
2.  Run the `archive` command:
    ```sh
    pj archive old-legacy-app
    ```
3.  The project will be compressed and moved to `$HOME/projects/.pj/archives/` (or your custom `PROJECTS_DATA/archives`).

#### Deleting a Project
Use extreme caution with this command as it permanently removes your project.

**Steps**:
1.  Identify the project to delete (e.g., `temp-scratchpad`).
2.  Run the `delete` command:
    ```sh
    pj delete temp-scratchpad
    ```
3.  PJ will ask for a confirmation keyword. Carefully read the prompt and type the exact keyword to proceed.
4.  If confirmed, the project directory is deleted.

### 2. Customizing PJ

#### Setting a Custom Projects Path
By default, PJ looks for projects in `~/projects`. You can change this.

**Steps**:
1.  Create or edit `~/.config/pj/env.sh`.
2.  Add or modify the `PROJECTS_PATH` variable:
    ```sh
    # ~/.config/pj/env.sh
    export PROJECTS_PATH="$HOME/dev/my-workspaces"
    ```
3.  Save the file. The change takes effect on the next `pj` command run.

#### Creating a Custom Recipe
Recipes are powerful for quickly scaffolding new projects with specific structures or boilerplate.

**Steps**:
1.  Create a new executable file (without an extension) in `~/.config/pj/plugins/recipes/`. For example, create `~/.config/pj/plugins/recipes/my-web-app`.
2.  Add your shell script logic to this file. The script will receive the project path as its first argument (`$1`).
    ```sh
    #!/bin/sh
    # ~/.config/pj/plugins/recipes/my-web-app
    PROJECT_PATH="$1"
    mkdir -p "$PROJECT_PATH/src"
    mkdir -p "$PROJECT_PATH/public"
    echo "# My Web App" > "$PROJECT_PATH/README.md"
    echo "<!DOCTYPE html>\n<html><head><title>Hello</title></head><body><h1>Hello, World!</h1></body></html>" > "$PROJECT_PATH/public/index.html"
    ```
3.  Make the recipe executable:
    ```sh
    chmod +x ~/.config/pj/plugins/recipes/my-web-app
    ```
4.  Now, use your custom recipe:
    ```sh
    pj new my-web-app my-new-website
    ```

### 3. Troubleshooting

#### Missing Required Dependencies
If PJ reports missing dependencies during installation or runtime, you'll need to install them using your system's package manager.

**Steps**:
1.  Note the missing dependency reported by PJ (e.g., `fzf`).
2.  Use your OS's package manager to install it:
    *   **Debian/Ubuntu**: `sudo apt install <dependency>`
    *   **Fedora/RHEL**: `sudo dnf install <dependency>`
    *   **macOS (Homebrew)**: `brew install <dependency>`
3.  Retry the PJ command.

#### Permissions Issues
If your custom plugins or recipes aren't working, ensure they have execute permissions.

**Steps**:
1.  Navigate to the directory of your custom plugin or recipe (e.g., `~/.config/pj/plugins/myplugin/index.sh` or `~/.config/pj/plugins/recipes/myrecipe`).
2.  Grant execute permissions:
    ```sh
    chmod +x <path_to_script>
    ```

#### Checking Logs
PJ writes verbose logs to a temporary directory, which can be helpful for debugging.

**Steps**:
1.  Check the log file located at `/tmp/$USER/pj/<current_date>.log`.
    ```sh
    cat /tmp/$USER/pj/$(date +"%d_%m").log
    ```
2.  Look for `ERROR` or `WARN` messages that might indicate the cause of the issue.

---
### 🤖 AI Agent Guidance

```json
{
  "decisionPoints": [
    "IF task == \"create_project\" THEN prompt_user(\"Enter project name and recipe (e.g., base)\") AND execute_command(\"pj new <recipe> <project-name>\")",
    "IF task == \"open_project\" THEN execute_command(\"pj open\") AND monitor_fzf_selection",
    "IF task == \"customize_projects_path\" THEN create_or_edit_file(\"~/.config/pj/env.sh\", \"export PROJECTS_PATH=\\\"/path/to/projects\\\"\")",
    "IF task == \"create_custom_recipe\" THEN create_file(\"~/.config/pj/plugins/recipes/<recipe-name>\") AND chmod_plus_x(\"~/.config/pj/plugins/recipes/<recipe-name>\")"
  ],
  "verificationSteps": [
    "Check: `ls $PROJECTS_PATH/<new-project-name>` after creation → Expected: Directory exists with recipe content",
    "Check: `tmux has-session -t <project-basename>` after `pj open` → Expected: Exit code 0 (session exists)",
    "Check: `ls -l ~/.config/pj/plugins/recipes/my-recipe` permissions → Expected: `rwx` for owner",
    "Check: `cat /tmp/$USER/pj/$(date +\"%d_%m\").log | grep ERROR` → Expected: No errors for successful operations"
  ],
  "quickPatterns": [
    "Pattern: `pj new base my-project`",
    "Pattern: `pj open`",
    "Pattern: `export PROJECTS_PATH=\"$HOME/dev/projects\"` in `~/.config/pj/env.sh`",
    "Pattern: `chmod +x ~/.config/pj/plugins/recipes/my-recipe`"
  ],
  "diagnosticPaths": [
    "Error: ProjectCreationFailure -> Symptom: `pj new` fails, project directory not created -> Check: Recipe script content for errors, permissions of recipe file -> Fix: Debug recipe script, ensure it's executable and correct."
  ]
}
```

---
*Generated using Gemini AI on 6/16/2025, 8:30:37 PM. Review and refine as needed.*