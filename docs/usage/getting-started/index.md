# Getting Started

### Overview
PJ is a command-line utility that streamlines common project management tasks within the terminal. It helps you quickly open projects in dedicated tmux sessions, create new projects from customizable templates (recipes), and manage project lifecycles (archive, delete, list). PJ is designed to be lean, fast, and highly customizable through shell scripts and environment variables.

### Core Concepts
*   **Projects**: Any directory managed by PJ, typically located under `$PROJECTS_PATH`.
*   **Recipes**: Templates used by the `new` command to scaffold new projects.
*   **Plugins**: Custom commands or extensions that can be added to PJ.
*   **Tmux Sessions**: PJ leverages tmux to provide isolated and persistent terminal environments for each project, enhancing productivity.
*   **Fuzzy Selection**: Integrated with `fzf` for quick and intuitive selection of projects.

### Architecture
PJ follows a modular architecture. The core logic resides in POSIX-compliant shell scripts. Commands are implemented as modules, allowing for easy extension and overriding. Configuration and custom assets are stored in a user-specific directory (`~/.config/pj/`), ensuring no system files are modified during installation or operation.

### Quick Setup Guide
PJ is installed to your user directory without requiring root privileges. The installer script handles all necessary setup, including placing the `pj` binary in `~/.local/bin` and setting up required configuration directories.

#### Prerequisites
Before installation, ensure you have the following standard Unix tools installed. PJ will check for these and notify you if any are missing:

*   `sh` (POSIX shell)
*   `tmux`
*   `fzf`
*   `tree`
*   `awk`
*   `sed`
*   `grep`
*   `curl`
*   `tar`
*   `mkdir`
*   `ls`
*   `cat`
*   `date`
*   `read`
*   `printf`
*   `echo`
*   `jq`

#### Installation Steps
To install PJ, run the following command in your terminal. This script is idempotent, meaning you can run it multiple times without adverse effects.

```sh
sh <(curl -fsSL https://github.com/asaidimu/pj/releases/download/latest/install.sh)
```

Upon successful installation, PJ will be available as the `pj` command in your terminal, provided `~/.local/bin` is in your `PATH`.

### First Tasks with Decision Patterns

#### 1. Open an Existing Project
If you have an existing project directory, you can open it with PJ. PJ will attempt to find projects in `$HOME/projects` by default, or any path defined by `PROJECTS_PATH` in `~/.config/pj/env.sh`.

```sh
pj open
```

This command will open an interactive fuzzy finder. Select your project from the list, and PJ will create or attach to a `tmux` session for it. If a `.pj` or `.project` script exists in your project's root, it will be executed to set up the session.

#### 2. Create a New Project
To create a new project, use the `new` command with a recipe and your desired project name:

```sh
pj new base my-new-project
```

This command creates a new directory `my-new-project` inside your `PROJECTS_PATH` using the default 'base' recipe. Recipes are simple scripts that scaffold your project's initial structure.

---
### 🤖 AI Agent Guidance

```json
{
  "decisionPoints": [
    "IF user_goal == \"install_pj\" THEN execute_shell_command(\"sh <(curl -fsSL https://github.com/asaidimu/pj/releases/download/latest/install.sh)\") ELSE continue_to_manual_setup",
    "IF project_exists_locally THEN execute_command(\"pj open\") ELSE execute_command(\"pj new <recipe> <project-name>\")"
  ],
  "verificationSteps": [
    "Check: `command -v pj` → Expected: `pj` executable path",
    "Check: `pj help` → Expected: PJ help message",
    "Check: `tmux ls` after `pj open <project>` → Expected: `tmux` session named after project basename"
  ],
  "quickPatterns": [
    "Pattern: `sh <(curl -fsSL https://github.com/asaidimu/pj/releases/download/latest/install.sh)` - Install/Update PJ",
    "Pattern: `pj open` - Interactively open a project",
    "Pattern: `pj new base my-first-project` - Create a new project with 'base' recipe"
  ],
  "diagnosticPaths": [
    "Error: MissingDependency -> Symptom: Installation script fails with 'missing required dependencies' -> Check: `command -v <dependency>` for listed missing tools -> Fix: Install missing dependencies using system package manager (e.g., `sudo apt-get install tmux fzf`)"
  ]
}
```

---
*Generated using Gemini AI on 6/16/2025, 8:30:37 PM. Review and refine as needed.*