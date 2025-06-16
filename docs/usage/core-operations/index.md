# Core Operations

This section details the primary commands for managing your projects with PJ.

### `pj open`
**Description**: Initializes the environment for a project. It allows you to select a project using a fuzzy finder (`fzf`) and then creates or attaches to a dedicated `tmux` session for that project. It can also execute project-specific setup scripts.

**Usage**: `pj open [refresh|help]`

**Arguments**:
*   `refresh`: Regenerates the list of available projects before opening the fuzzy selector.
*   `help`: Displays help for the `open` command.

**Workflow**:
1.  If `refresh` is specified, the project list is regenerated.
2.  A fuzzy selector (powered by `fzf`) is presented, listing project paths. You select a project.
3.  PJ determines a `tmux` session name from the selected project's basename.
4.  If a `tmux` session with that name does not exist, a new one is created in the project directory.
5.  If present, a `.pj` or (deprecated) `.project` executable script in the project root is run inside the `tmux` session to perform custom setup.
6.  If present, a `.env` file in the project root (key-value pairs) is sourced to set environment variables for the session.
7.  You are attached to (or switched to, if already in `tmux`) the project's `tmux` session.

**Example**:
```sh
pj open
# (Interactive fuzzy selection)

pj open refresh
```

### `pj new`
**Description**: Creates a new project folder from a specified recipe (template) in your projects directory (`$PROJECTS_PATH`).

**Usage**: `pj new <recipe> <project-name> [-o|--overwrite]`

**Arguments**:
*   `<recipe>` (Required): The name of the recipe to use (e.g., `base`). Recipes are executable scripts that define the project structure.
*   `<project-name>` (Required): The name of the new project directory.
*   `-o`, `--overwrite` (Optional): If provided, PJ will overwrite an existing project with the same name.

**Workflow**:
1.  PJ checks for the existence of the specified recipe (first in custom recipes, then in inbuilt ones).
2.  If `<recipe>` is omitted but `<project-name>` is given, the `base` recipe is used by default.
3.  If a project with `<project-name>` already exists and `-o` is not used, an error is triggered.
4.  The selected recipe script is executed, creating the new project directory and its initial contents.
5.  A post-hook (`src/module/new/post_hook.sh`) is automatically run to refresh the project list.

**Example**:
```sh
pj new base my-new-app
pj new my-custom-recipe another-project -o
```

### `pj archive`
**Description**: Compresses a specified project folder into a `.tar.xz` archive and saves it to the PJ archives directory (`$PROJECTS_PATH/.pj/archives`).

**Usage**: `pj archive <project-name>`

**Arguments**:
*   `<project-name>` (Required): The name of the project to archive.

**Workflow**:
1.  PJ verifies that the specified project exists.
2.  A timestamped `.tar.xz` archive of the project directory is created.
3.  The archive is saved under `$PROJECTS_PATH/.pj/archives/`.

**Example**:
```sh
pj archive old-project
```

### `pj delete`
**Description**: Permanently deletes a project folder from your projects directory. This action is irreversible and requires confirmation.

**Usage**: `pj delete <project-name>`

**Arguments**:
*   `<project-name>` (Required): The name of the project to delete.

**Workflow**:
1.  PJ verifies that the specified project exists.
2.  A warning is displayed, and you are prompted to type a randomly generated keyword for confirmation.
3.  If the keyword matches, the project directory and all its contents are recursively deleted.

**Example**:
```sh
pj delete temp-project
# (You will be prompted to confirm deletion)
```

### `pj list`
**Description**: Lists all active project folders located under your configured projects path (`$PROJECTS_PATH`).

**Usage**: `pj list`

**Example**:
```sh
pj list
# Expected Output:
# project1
# project2
# my-new-app
```

### `pj refresh`
**Description**: Regenerates the internal list of projects. This is useful if you manually add or remove projects from `$PROJECTS_PATH` outside of PJ's `new` or `delete` commands.

**Usage**: `pj refresh`

**Example**:
```sh
pj refresh
```

### `pj update`
**Description**: Upgrades PJ to the latest available version by downloading and running the latest installer script from the GitHub releases.

**Usage**: `pj update`

**Workflow**:
1.  PJ checks for the latest release on GitHub.
2.  If a newer version is available, the latest installation script is downloaded.
3.  The downloaded script is executed to update PJ's core files.
4.  The version string in the main `pj` executable is updated.

**Example**:
```sh
pj update
```

---
### 🤖 AI Agent Guidance

```json
{
  "decisionPoints": [
    "IF command == \"open\" AND arg == \"refresh\" THEN call_method(\"_generate_list\") ELSE continue",
    "IF command == \"new\" AND project_exists(project_name) AND overwrite_flag_not_set THEN throw_error(\"ERROR_PROJECT_EXISTS\") ELSE continue",
    "IF command == \"delete\" AND user_confirmation_matches(keyword) THEN call_method(\"rm -rf project_path\") ELSE inform_user(\"incorrect input, aborted\")"
  ],
  "verificationSteps": [
    "Check: `pj open` prompts with fzf selection → Expected: Interactive list of projects",
    "Check: `ls $PROJECTS_PATH/my-new-app` after `pj new base my-new-app` → Expected: Directory exists",
    "Check: `ls $PROJECTS_PATH/.pj/archives/` after `pj archive old-project` → Expected: `.tar.xz` archive file exists",
    "Check: `pj list` → Expected: Shows currently managed project names",
    "Check: `pj update` output → Expected: \"Upgraded to <new_version>\" or \"Already at latest version\""
  ],
  "quickPatterns": [
    "Pattern: `pj open`",
    "Pattern: `pj new base my-project`",
    "Pattern: `pj archive my-old-project`",
    "Pattern: `pj delete my-temp-project`",
    "Pattern: `pj list`",
    "Pattern: `pj update`"
  ],
  "diagnosticPaths": [
    "Error: CommandNotFound -> Symptom: Shell reports 'command not found' -> Check: `command -v pj` and `echo $PATH` -> Fix: Ensure `~/.local/bin` is in PATH, reinstall PJ if necessary.",
    "Error: ProjectNotFound -> Symptom: `pj archive` or `pj delete` fails with 'project not found' -> Check: `ls $PROJECTS_PATH/<project-name>` -> Fix: Provide correct project name or verify project existence.",
    "Error: UpdateFailed -> Symptom: `pj update` reports 'could not update framework' -> Check: Network connectivity, `curl` and `jq` installation -> Fix: Resolve network issues, ensure dependencies are installed, or try manual installation."
  ]
}
```

---
*Generated using Gemini AI on 6/16/2025, 8:30:37 PM. Review and refine as needed.*