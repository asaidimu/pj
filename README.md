# Project Juggler: A POSIX Terminal Project Manager Framework

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

PJ splits dependencies into two tiers:

**Required** — the kernel refuses to start without these. They are standard
POSIX userland tools present on any Unix system (authoritative list:
`src/utils/deps.sh`):

`sh`, `mkdir`, `ls`, `cat`, `date`, `sed`, `awk`, `grep`, `tr`, `wc`, `sleep`,
`find`, `xargs`, `sort`, `uniq`, `mktemp`, `mv`, `rm`, `cp`, `chmod`,
`basename`, `dirname`, `printf`, `echo`, `read`

**Module-specific** — each module declares the extra tools it needs with a
`# requires:` tag. Missing ones produce a warning at install time and again
when the command runs; they never block pj itself:

| Module | Extra tools |
|--------------|----------------------|
| `open` | `tmux`, `fzf`, `tree` |
| `archive` | `tar` |
| `update` | `curl`, `jq` |
| `analyze`, `document` | `bun` |
| `commit` | `bun`, `git` |

So `pj list`, `pj help`, and `pj new` work even on a machine without
tmux, fzf, or jq installed.

## Installation

Run the installation script:

```sh
sh <(curl -fsSL https://github.com/asaidimu/pj/releases/download/latest/install.sh)
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
- `pj env` – List or verify framework environment variables.
- `pj refresh` – Regenerate the project list.
- `pj update` – Update PJ to the latest version.
- `pj completion` – (Re)generate shell completions.
- `pj help` – Display help and available commands.
- `pj help --extended` – Full framework info: authorship, license, homepage,
  repository, release, and install paths (metadata resolves from the install
  stamp, git remote, or `FRAMEWORK_*` env overrides).

For detailed help on any command:

```sh
pj <command> help
```

### Shell Completions

PJ ships a completion generator (`src/completion/generate.sh`) that reads the
`# summary` (and optional `# completion:`) tags from every module and plugin
and emits tab-completion for both zsh and bash. Completions are generated and
installed automatically by the installer:

```
~/.local/share/zsh/site-functions/_pj
~/.local/share/bash-completion/completions/pj
```

To regenerate after adding or removing modules or plugins:

```sh
pj completion            # regenerate both shells
pj completion zsh        # zsh only
pj completion bash       # bash only
```

`# completion:` tells the generator which operand the command accepts:

| Tag                     | What it completes              |
|-------------------------|--------------------------------|
| (unset) / `none`        | no operand completion          |
| `projects`              | project names (`pj list`)      |
| `recipes`               | recipe names (`pj new help`)   |
| `analysis`              | analyze/commit/document style  |

### Quickstart Example

```sh
# Create a new project from the 'base' recipe
pj new base myproject

# Scaffold a standalone CLI script in the current directory
# (pragma-driven — describe flags/commands in the comment block, no parsing code)
pj new --script program.sh

# Scaffold a custom module (plugin) — immediately available as `pj <name>`
pj new --module greet

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

Every variable is declared once in `src/env.sh` with a name, kind
(`str`/`num`/`dir`/`file`), scope (`override`/`derived`/`fixed`) and
description — that single declaration is what lists and verifies it:

```sh
pj env           # every variable: value, description, kind, scope
pj env check     # verify all of them (exit code = number of issues)
```

Variables marked `override` in `pj env` are the ones your `env.sh` may
set; `derived` paths (`PROJECTS_DATA`, `ARCHIVE_PATH`, `PROJECTS_LIST`, …)
are computed *after* your `env.sh` is loaded, so overrides always take
effect. Runtime directories (including `PROJECTS_PATH`) are created on
first run. The startup environment check and `pj env check` run the same
verification, so adding a variable with `env_set` in `src/env.sh` makes
it listed and checked automatically — no other lists to update.

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

Recipes run inside the framework environment: `PROJECT_NAME`,
`PROJECT_PATH`, and the utils (`inform`, `question`, `extract_file`, …) are
available. A recipe may declare the tools it needs with a
`# REQUIRES : <tool ...>` header; pj warns when one is missing.

### Custom Project List Generator

To override the project list generation, place a script at:

```
~/.config/pj/plugins/generator
```

This script should output project paths (one per line).

### Using the io library in your own scripts

pj's terminal i/o layer — colors, labeled output, spinners, `question`,
`radio`/`multiselect` (scrolling choice menus), `panic`, `notify` — is
published as a standalone bundle at:

```
~/.local/share/pj/lib/io.sh
```

Source it from any script, no framework required:

```sh
#!/usr/bin/env sh
. "${FRAMEWORK_LIB:-$HOME/.local/share/pj/lib}/io.sh"

inform "checking target"
panic "something is wrong"        # exits 1
```

The bundle is self-sufficient:

- colors auto-disable when stdout is not a terminal (and `--no-color`
  semantics via `FLAG_COLORED_OUTPUT=0`)
- `log` writes to `/dev/null` unless `FRAMEWORK_LOGS` points somewhere
- `panic` exits with `1` unless you pass an error code as the second argument
- `FLAG_SILENT=1` quiets `notify`
- `QUESTION_PREFIX` (default `question`) prefixes every prompt — the
  typed `question()` line and both menus alike; set it once to rebrand a
  whole flow (e.g. `QUESTION_PREFIX="step 2"` before a wizard)

`radio`/`multiselect` share one menu model: **space chooses** (marks the
current item — radio: one ●, multiselect: ☑ toggles), **enter continues**
with whatever is chosen. If nothing is chosen and no default was given,
enter refuses with an in-menu hint instead of aborting the caller — a
long form can never lose its place to an accidental enter. Pass
`-d <choice>` (`multiselect -d "a,b"` for several) to pre-choose defaults
that plain enter accepts; numbers 1-9 jump to and choose an item; `q`
cancels with rc 1.

Set `FRAMEWORK_LIB` to use a relocated pj. The bundle is rebuilt from
`src/utils/{colors,io,app}.sh` on every install and `pj update`.

### Pragma-driven apps

The bundle also ships a reflective app layer: declare your CLI in `# @...`
comment pragmas and call `app_start` — flag parsing, command routing,
dependency checks and `--help` output are derived from the block, so
scaffolded scripts never need parsing code edited by hand.

```sh
#!/usr/bin/env sh
# @about     Builds a factorio plugin zip
# @usage     build.sh [options] <path>
# @requires  jq zip
# @flag      -o, --output=<dir>    where to write the zip (default: dist)
# @arg       path                  plugin folder to bundle

. "${FRAMEWORK_LIB:-$HOME/.local/share/pj/lib}/io.sh"

main(){
  plugin="$1"          # positionals arrive quoted, flags stripped
  ...
}

app_start "$@"
```

Pragma reference:

| pragma | effect |
|---|---|
| `# @about <text>` | one-line description in help |
| `# @usage <text>` | usage line (default: `$SCRIPT_NAME [options]`) |
| `# @version <text>` | enables `-v`/`--version` |
| `# @requires <cmd>...` | checked before dispatch (after `--help`) |
| `# @flag -x, --xx=<val> <help> [=> VAR]` | flag dispatch; value flags support `--xx=v` and `--xx v`; sets `OPT_XX` (or `VAR`); booleans set it to `1` |
| `# @route <name> <help>` | command routing; calls `name()` |
| `# @default <name>` | route used when none is given (omit to require a command) |
| `# @arg <name> <help>` | required positional (arity-checked, named in errors) |
| `# @arg [<name>] <help>` | optional positional |

Built-ins: `-h/--help` (rendered from the same block), `--` end-of-flags,
unknown-flag panics that list the valid flags, and quoted positionals all
the way to `main`/your route function. Scripts without any pragma keep
working: everything is passed to `main "$@"` as before. Set `APP_SOURCE`
to reflect over a different file than the caller (needed only in exotic
sourcing setups). Kernel modules (`src/module/*/index.sh`) use this same
layer: their pragmas render `pj <command> help`, and the dispatcher sets
`APP_SOURCE`/`APP_MODULE` for them automatically.

## Developer Documentation

### How PJ Works

1. Run `pj <command> [options]`.
2. PJ locates a matching core or user plugin and sources its `index.sh`.
3. The plugin executes in the current shell, using framework utilities and environment variables.
4. The command produces output (e.g., opens a tmux session, creates a project).

### Plugin Pattern

Scaffold a ready-to-run module with `pj new --module <name>` — it lands in
`~/.config/pj/plugins/<name>/index.sh`, pragma-driven like scripts, with a
delete-me how-to block at the bottom. It shows up in `pj help` and shell
completions immediately; add `pre_hook.sh`/`post_hook.sh` beside it for
before/after behavior.

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

Modules declare a `# summary: <one-liner>` tag at the top of their
`index.sh`; it feeds `pj help` and the shell completion generator. An
optional `# completion: <type>` tag tells the generator which operands to
complete (see [Shell Completions](#shell-completions)), and an optional
`# requires: <tool ...>` tag lists the extra commands the module needs —
missing ones only warn, at install and at runtime:

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

## Testing

PJ ships a POSIX test harness that runs the framework across every available
shell in an isolated sandbox:

```sh
sh tests/run.sh                 # every available shell (sh, bash, zsh, dash, ksh)
sh tests/run.sh bash zsh        # a specific subset
```

The suite covers project creation, listing, archiving, deletion errors, flag
parsing, the project-list generator, and default path handling. It is also
wired into CI (`.github/workflows/test.yml`) across all five shells.

## Troubleshooting

- **Missing Dependencies**: PJ alerts if a required tool is missing.
- **Permissions**: Ensure custom plugins and recipes are executable (`chmod +x`).
- **Logs**: Check `/tmp/$USER/pj/` for logs.

## Getting Help

- **GitHub Issues**: Report bugs or request features at [https://github.com/asaidimu/pj/issues](https://github.com/asaidimu/pj/issues).
- **Contributions**: Pull requests are welcome. Follow POSIX shell best practices.

## POSIX Compliance

PJ is POSIX-compliant and tested against:
- dash
- bash (POSIX mode)
- zsh (sh emulation)
- ksh
- sh

Every commit runs `tests/run.sh` across all five shells in CI
(`.github/workflows/test.yml`). Report compatibility issues via GitHub.

## License

PJ is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for details.
