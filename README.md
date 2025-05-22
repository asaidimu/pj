# PJ: A POSIX Terminal Project Manager Framework

![banner](https://raw.githubusercontent.com/asaidimu/pj/main/banner.png?raw=true)

[![semantic-release: angular](https://img.shields.io/badge/semantic--release-angular-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)
![license](https://img.shields.io/github/license/asaidimu/pj)
![build](https://img.shields.io/github/actions/workflow/status/asaidimu/pj/release.yml?branch=main&style=flat-square)
![tag](https://img.shields.io/github/v/release/asaidimu/pj?display_name=tag&style=flat-square)

PJ is a modular, scriptable, and POSIX-compliant project management framework for the terminal. Designed for developers, sysadmins, and power users, it integrates with tools like tmux and fzf, adhering to the Unix philosophy of simplicity and extensibility.

## Features

- Open projects in tmux sessions with a single command.
- Fuzzy project selection using fzf for efficient navigation.
- Create projects from templates (recipes) quickly.
- Archive, delete, and list projects with intuitive commands.
- Extend functionality with custom plugins.
- Configure settings via environment variables or scripts.
- POSIX-compliant: Runs on any POSIX shell (dash, bash, zsh, ksh, etc.).
- Minimal dependencies: Uses standard Unix tools.

## Requirements

PJ requires the following standard Unix tools:

- `sh`, `tmux`, `fzf`, `tree`, `awk`, `sed`, `grep`, `curl`, `tar`, `mkdir`, `ls`, `cat`, `date`, `read`, `printf`, `echo`

### Installing Dependencies

- **Ubuntu/Debian**:
  ```sh
  sudo apt install tmux fzf tree awk sed grep curl tar coreutils
  ```
- **macOS (Homebrew)**:
  ```sh
  brew install tmux fzf tree gawk gnu-sed grep curl gnu-tar coreutils
  ```

PJ will notify you if any required tool is missing.

## Installation

To install PJ, clone the repository and run the installation script:

```sh
git clone https://github.com/asaidimu/pj.git
cd pj
./install.sh
```

This installs PJ to your user directory without requiring root access or modifying system files. The process is idempotent, so it’s safe to run multiple times.

## Usage

Run PJ commands with the following syntax:

```sh
pj <command> [options]
```

### Common Commands

- `pj open` – Open a project (fuzzy selection with fzf, opens in a tmux session).
- `pj new` – Create a new project from a recipe.
- `pj archive` – Archive a project.
- `pj delete` – Delete a project.
- `pj list` – List all projects.
- `pj refresh` – Regenerate the project list.
- `pj update` – Update PJ to the latest version.
- `pj help` – Display help and available commands.

For detailed help on any command:

```sh
pj <command> help
```

### Quickstart Example

```sh
# Create a new project from the 'base' recipe
pj new base myproject

# Open a project with fuzzy selection
pj open

# Archive a project
pj archive myproject

# List all projects
pj list

# Delete a project
pj delete myproject
```

## Configuration

PJ stores user-specific configurations in:

```
~/.config/pj/
```

### Configuration Directory Structure

```
~/.config/pj/
├── env.sh
├── plugins/
│   └── myplugin/
│       └── index.sh
├── plugins/recipes/
│   └── myrecipe
└── data/
```

- **`env.sh`**: Stores environment variable configurations.
- **`plugins/`**: Contains custom plugins (e.g., `myplugin/index.sh`).
- **`plugins/recipes/`**: Holds custom project template files (e.g., `myrecipe`, an executable file without an extension).
- **`data/`**: Stores project metadata and archives.

### Environment Variables

Override default settings by editing (or creating) `~/.config/pj/env.sh`:

```sh
# Example ~/.config/pj/env.sh
export PROJECTS_PATH="$HOME/my-projects"
```

Common environment variables:

| Variable            | Default                     | Description                        |
|---------------------|-----------------------------|------------------------------------|
| `PROJECTS_PATH`     | `$HOME/projects`            | Directory for storing projects     |
| `CUSTOM_PLUGINS_PATH` | `~/.config/pj/plugins`    | Directory for custom plugins       |
| `CUSTOM_RECIPES_PATH` | `~/.config/pj/plugins/recipes` | Directory for custom recipe files |

Changes to `env.sh` are applied automatically on the next PJ command run.

## Customization

### Adding Custom Plugins

To create a custom command:

1. Create a plugin directory:
   ```sh
   mkdir -p ~/.config/pj/plugins/myplugin
   ```
2. Add an `index.sh` file with your plugin logic:
   ```sh
   #!/bin/sh

   help() {
     echo "Usage: pj myplugin"
     echo "Prints Hello from my custom plugin!"
   }

   init() {
     case "$1" in
       help)
         help
         ;;
       *)
         echo "Hello from my custom plugin!"
         ;;
     esac
   }

   init "$@"
   ```
3. Make the script executable:
   ```sh
   chmod +x ~/.config/pj/plugins/myplugin/index.sh
   ```
4. Run your plugin:
   ```sh
   pj myplugin
   ```

User plugins take precedence over core commands with the same name.

### Adding Custom Recipes

To create a custom project template:

1. Create an executable recipe file (without an extension) in:
   ```
   ~/.config/pj/plugins/recipes/myrecipe
   ```
   Example:
   ```sh
   #!/bin/sh
   # ~/.config/pj/plugins/recipes/myrecipe
   mkdir -p "$1"
   echo "Created project $1" > "$1/README.md"
   ```
2. Make it executable:
   ```sh
   chmod +x ~/.config/pj/plugins/recipes/myrecipe
   ```
3. Use it with:
   ```sh
   pj new myrecipe myproject
   ```

### Custom Project List Generator

To override the project list generation, place a script at:

```
~/.config/pj/plugins/generator
```

This script should output project paths (one per line).

## Developer Documentation

### How PJ Works

1. Run `pj <command> [options]`.
2. PJ locates a matching core or user plugin and sources its `index.sh`.
3. The plugin executes in the current shell, using framework utilities and environment variables.
4. The command produces output (e.g., opens a tmux session, creates a project).

### Plugin Pattern

Each plugin is a directory (in `src/module/<plugin>/` or `~/.config/pj/plugins/<plugin>/`) containing an `index.sh` file. The `index.sh` must define an `init()` function and call it:

```sh
init() {
  # Plugin logic here
}
init "$@"
```

Plugins should:
- Be POSIX-compliant (no bashisms).
- Include a `help()` function for usage information.
- Handle arguments passed to `init()`.

#### Example Plugin

```sh
#!/bin/sh

help() {
  echo "Usage: pj hello"
  echo "Prints Hello, World!"
}

init() {
  case "$1" in
    help)
      help
      ;;
    *)
      echo "Hello, World!"
      ;;
  esac
}

init "$@"
```

### Command Lifecycle Hooks

PJ supports pre and post hooks for commands:

- **Pre-hook**: Runs before the command’s `index.sh` (`pre_hook.sh`).
- **Post-hook**: Runs after the command, even on failure (`post_hook.sh`).

Hooks are stored in the module directory and receive the same arguments and environment as the command.

#### Example: Auto-Refresh After Creating a Project

```sh
# src/module/new/post_hook.sh
#!/bin/sh
run_command refresh
```

## Troubleshooting

- **Missing Dependencies**: PJ alerts if a required tool is missing.
- **Permissions**: Ensure custom plugins and recipes are executable (`chmod +x`).
- **Logs**: Check `/tmp/$USER/pj/` for logs.

## Getting Help

- **GitHub Issues**: Report bugs or request features at [https://github.com/asaidimu/pj/issues](https://github.com/asaidimu/pj/issues).
- **Contributions**: Pull requests are welcome. Follow POSIX shell best practices.

## POSIX Compliance

PJ is POSIX-compliant and tested on:
- dash
- bash (POSIX mode)
- zsh (sh emulation)
- ksh

Report compatibility issues via GitHub.

## License

PJ is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for details.
