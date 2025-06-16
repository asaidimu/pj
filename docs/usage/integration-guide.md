# Integration Guide

## Environment Requirements

PJ requires a POSIX-compliant shell (e.g., bash, dash, zsh in sh emulation mode, ksh) and a standard Unix-like operating system (Linux, macOS). It relies heavily on standard command-line utilities. User's `PATH` environment variable must include `~/.local/bin` for the `pj` executable to be found.

## Initialization Patterns

### Initial installation and setup of PJ framework.
```[DETECTED_LANGUAGE]
sh <(curl -fsSL https://github.com/asaidimu/pj/releases/download/latest/install.sh)
```

### Bootstrapping PJ runtime environment within a shell session (handled internally by `~/.local/bin/pj`).
```[DETECTED_LANGUAGE]
#!/usr/bin/env sh

# -- set framework path --
FRAMEWORK_NAME=${FRAMEWORK_NAME:-"pj"}
FRAMEWORK_PATH=${FRAMEWORK_PATH:-"$HOME/.local/share/pj"}
FRAMEWORK_RELEASE="main"
FRAMEWORK_URL=${FRAMEWORK_URL:-`{{url}}`}
FRAMEWORK_VERSION="{{version}}"

# -- bootstrap --
. "$FRAMEWORK_PATH/src/bootstrap.sh"
```

## Common Integration Pitfalls

- **Issue**: PJ command not found after installation.
  - **Solution**: Ensure `~/.local/bin` is in your shell's `PATH` environment variable. Add `export PATH="$HOME/.local/bin:$PATH"` to your shell's startup file (e.g., `~/.bashrc`, `~/.zshrc`) and restart your terminal or source the file.

- **Issue**: Custom plugins or recipes are not executable.
  - **Solution**: Verify that custom scripts in `~/.config/pj/plugins/` or `~/.config/pj/plugins/recipes/` have execute permissions. Run `chmod +x <path_to_script>`.

- **Issue**: Errors related to missing external commands (e.g., `fzf: command not found`).
  - **Solution**: Install the reported missing dependency using your operating system's package manager (e.g., `sudo apt install fzf` on Debian/Ubuntu, `brew install fzf` on macOS).

## Lifecycle Dependencies

PJ relies on a functional `tmux` server for session management. When `pj open` is executed, it either connects to an existing `tmux` server or starts a new one. Project-specific `.pj` or `.project` setup scripts are executed *after* the `tmux` session is initialized and the current working directory is set. Environment variables defined in `.env` files are loaded into the `tmux` session before any project setup script runs.



---
*Generated using Gemini AI on 6/16/2025, 8:30:37 PM. Review and refine as needed.*