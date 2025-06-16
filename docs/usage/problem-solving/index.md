# Problem Solving

This section provides guidance on diagnosing and resolving common issues encountered while using PJ.

### General Troubleshooting Steps
1.  **Check Dependencies**: Ensure all [required dependencies](#dependencies) are installed and accessible in your `PATH`.
2.  **Verify Paths**: Double-check `PROJECTS_PATH` in `~/.config/pj/env.sh` and ensure project directories exist at expected locations.
3.  **Check Permissions**: Custom plugins, recipes, and the `pj` executable itself must have execute permissions (`chmod +x`).
4.  **Review Logs**: PJ generates detailed logs at `/tmp/$USER/pj/$(date +"%d_%m").log`. These logs often contain error messages or warnings that can pinpoint the issue.
5.  **Run with `DEBUG=1`**: Temporarily set `export DEBUG=1` in your shell before running a `pj` command to enable verbose debug output. This can reveal internal execution flow and variable states.

### Error Reference
PJ uses specific error codes for different failure conditions. Refer to the [Errors](#errors) section in the full reference for details on specific error types and their resolutions.

#### Common Issues & Solutions
*   **Command not found**: If `pj` command itself is not found, ensure `~/.local/bin` is in your shell's `PATH` environment variable. If it's not, you may need to add `export PATH="$HOME/.local/bin:$PATH"` to your `~/.bashrc`, `~/.zshrc`, or equivalent startup file.
*   **Project not found for `archive` or `delete`**: Ensure the project name you are providing exactly matches a directory name under your `PROJECTS_PATH`.
*   **`tmux` session not created**: Check if `tmux` is installed and running correctly. Also, verify if the project's `.pj` or `.project` script is interfering with session creation.
*   **Custom plugin/recipe not working**: Ensure the script file has `#!/bin/sh` as the first line, is executable (`chmod +x`), and is placed in the correct `~/.config/pj/plugins/` or `~/.config/pj/plugins/recipes/` directory.
*   **Update failed (`pj update`)**: Verify internet connectivity and ensure `curl` and `jq` are installed and working. Sometimes, a full reinstall (`sh <(curl...)`) might be necessary if the update mechanism itself is corrupted.

If you're still facing issues, consider reporting them on the [GitHub Issues page](https://github.com/asaidimu/pj/issues) with detailed reproduction steps and log output.

---
### 🤖 AI Agent Guidance

```json
{
  "decisionPoints": [
    "IF problem_identified THEN consult_reference_errors_section",
    "IF `pj` command not found THEN check_path_variable",
    "IF custom_script_failure THEN check_script_permissions",
    "IF debugging_complex_issue THEN enable_debug_mode_and_review_logs"
  ],
  "verificationSteps": [
    "Check: `echo $PATH` → Expected: `~/.local/bin` included",
    "Check: `chmod +x <script_path>` → Expected: File permissions updated",
    "Check: `cat /tmp/$USER/pj/$(date +\"%d_%m\").log` for `ERROR` or `WARN` messages",
    "Check: `DEBUG=1 pj <command>` output for verbose trace"
  ],
  "quickPatterns": [
    "Pattern: `export PATH=\"$HOME/.local/bin:$PATH\"` (for shell startup file)",
    "Pattern: `chmod +x ~/.config/pj/plugins/myplugin/index.sh`",
    "Pattern: `DEBUG=1 pj new base test-project`"
  ],
  "diagnosticPaths": [
    "Error: CommandExecutionFailure -> Symptom: `pj` command produces unexpected output or exits with non-zero status -> Check: Related log entries for `ERROR` or `WARN` messages; check specific command's `help` output for correct usage -> Fix: Correct command syntax, investigate script logic if custom, or report bug.",
    "Error: ProjectDataInconsistency -> Symptom: `pj list` doesn't show expected projects, `pj open` fails to find known projects -> Check: `PROJECTS_PATH` in `~/.config/pj/env.sh`; manually verify directory structure under `$PROJECTS_PATH` -> Fix: Adjust `PROJECTS_PATH`, run `pj refresh` if projects were moved or added manually."
  ]
}
```

---
*Generated using Gemini AI on 6/16/2025, 8:30:37 PM. Review and refine as needed.*