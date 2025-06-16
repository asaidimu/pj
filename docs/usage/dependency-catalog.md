# Dependency Catalog

## External Dependencies

### sh
- **Purpose**: Primary shell interpreter for all PJ scripts; POSIX compliance is critical.
- **Installation**: `Built-in on most Unix-like systems (e.g., `/bin/sh`). Often symlinked to Bash or Dash.`
- **Version Compatibility**: `POSIX.1-2017 compatible shell`

### tmux
- **Purpose**: Terminal multiplexer for creating and managing persistent project sessions.
  - **Required Interfaces**:
    - `tmux commands`: PJ uses tmux commands to create, attach to, and manage sessions/windows/panes.
      - **Methods**:
        - `new-session`
          - **Signature**: `tmux new-session [-ds] <session-name> [-c <path>] [-e <VAR=VAL>]`
          - **Parameters**: `-d`: detached; `-s`: session name; `-c`: start directory; `-e`: environment variables.
          - **Returns**: Exits 0 on success, non-zero on failure. Creates a new tmux session.
        - `has-session`
          - **Signature**: `tmux has-session -t <session-name>`
          - **Parameters**: `-t`: target session name.
          - **Returns**: Exits 0 if session exists, 1 if not.
        - `switch-client`
          - **Signature**: `tmux switch-client -t <session-name>`
          - **Parameters**: `-t`: target session name.
          - **Returns**: Exits 0 on success. Switches client to specified session.
        - `attach-session`
          - **Signature**: `tmux attach-session -t <session-name>`
          - **Parameters**: `-t`: target session name.
          - **Returns**: Exits 0 on success. Attaches client to specified session.
        - `send-keys`
          - **Signature**: `tmux send-keys -t <target> <keys> <Enter>`
          - **Parameters**: `-t`: target pane; `<keys>`: keys to send; `<Enter>`: send Enter key.
          - **Returns**: Exits 0 on success. Sends key strokes to a pane.
- **Installation**: `[PACKAGE_MANAGER_INSTALL] tmux`
- **Version Compatibility**: `>=1.8 (for modern features)`

### fzf
- **Purpose**: General-purpose command-line fuzzy finder for interactive selection of projects.
  - **Required Interfaces**:
    - `fzf command`: Used to filter and select items from stdin, outputting the selected item to stdout.
      - **Methods**:
        - `fzf`
          - **Signature**: `fzf [options]`
          - **Parameters**: Options like `--border`, `--preview`, `--margin`, `--color`, `--with-nth`, `--delimiter` are used to configure appearance and parsing.
          - **Returns**: The selected line from stdin, or empty string if aborted. Exits 0 on selection, 130 on SIGINT (Ctrl+C), 1 on error.
- **Installation**: `[PACKAGE_MANAGER_INSTALL] fzf`
- **Version Compatibility**: `>=0.20.0`

### tree
- **Purpose**: Lists contents of directories in a tree-like format, used for fuzzy finder previews.
  - **Required Interfaces**:
    - `tree command`: Outputs a tree representation of directory contents.
      - **Methods**:
        - `tree`
          - **Signature**: `tree [-L <level>] [-C] [--dirsfirst] <path>`
          - **Parameters**: `-L`: max display level; `-C`: colorized output; `--dirsfirst`: list directories before files.
          - **Returns**: Tree-formatted directory listing.
- **Installation**: `[PACKAGE_MANAGER_INSTALL] tree`
- **Version Compatibility**: `Any stable version`

### awk
- **Purpose**: Pattern scanning and processing language, used for formatting output in utilities and help messages.
- **Installation**: `[PACKAGE_MANAGER_INSTALL] awk`
- **Version Compatibility**: `Any stable version (GNU Awk recommended)`

### sed
- **Purpose**: Stream editor for filtering and transforming text, used for string manipulation.
- **Installation**: `[PACKAGE_MANAGER_INSTALL] sed`
- **Version Compatibility**: `Any stable version`

### grep
- **Purpose**: Text search utility, used for parsing configuration files and log output.
- **Installation**: `[PACKAGE_MANAGER_INSTALL] grep`
- **Version Compatibility**: `Any stable version`

### curl
- **Purpose**: Command-line tool for transferring data with URLs, used for downloading installation scripts and checking updates.
- **Installation**: `[PACKAGE_MANAGER_INSTALL] curl`
- **Version Compatibility**: `Any stable version`

### tar
- **Purpose**: Archiver utility, used for compressing and decompressing project archives.
- **Installation**: `[PACKAGE_MANAGER_INSTALL] tar`
- **Version Compatibility**: `Any stable version (GNU Tar recommended for .xz support)`

### mkdir
- **Purpose**: Creates directories.
- **Installation**: `Built-in on most Unix-like systems.`
- **Version Compatibility**: `Any stable version`

### ls
- **Purpose**: Lists directory contents.
- **Installation**: `Built-in on most Unix-like systems.`
- **Version Compatibility**: `Any stable version`

### cat
- **Purpose**: Concatenates files and prints on the standard output.
- **Installation**: `Built-in on most Unix-like systems.`
- **Version Compatibility**: `Any stable version`

### date
- **Purpose**: Prints or sets the system date and time.
- **Installation**: `Built-in on most Unix-like systems.`
- **Version Compatibility**: `Any stable version`

### read
- **Purpose**: Reads a line from standard input.
- **Installation**: `Built-in shell command.`
- **Version Compatibility**: `Any stable version`

### printf
- **Purpose**: Formats and prints data.
- **Installation**: `Built-in shell command.`
- **Version Compatibility**: `Any stable version`

### echo
- **Purpose**: Displays a line of text.
- **Installation**: `Built-in shell command.`
- **Version Compatibility**: `Any stable version`

### jq
- **Purpose**: Lightweight and flexible command-line JSON processor, used for parsing GitHub API responses during updates.
- **Installation**: `[PACKAGE_MANAGER_INSTALL] jq`
- **Version Compatibility**: `>=1.5`



---
*Generated using Gemini AI on 6/16/2025, 8:30:37 PM. Review and refine as needed.*