// src/utils/prompt.ts - shared prompt-template loader for the agent modules
//
// The Gemini-backed modules (commit, analyze, document) keep their prompts
// as plain-text templates with {{PLACEHOLDER}} slots so any script can reuse
// them — including non-bun agent scripts. From the shell:
//
//   tpl="$FRAMEWORK_PATH/src/module/commit/prompt.txt"
//   rendered=$(awk '{ gsub(/\{\{DIFF\}\}/, diff); print }' "$tpl")   # etc.
//
// From bun/TypeScript use renderTemplate/loadTemplate below (this is what
// each module's prompts.ts does).
import { readFileSync } from "fs";

// Fill {{NAME}} slots; unknown slots render as empty strings.
export function renderTemplate(
  template: string,
  vars: Record<string, string>,
): string {
  return template.replace(/\{\{(\w+)\}\}/g, (_match, key: string) => vars[key] ?? "");
}

export function loadTemplate(path: string): string {
  return readFileSync(path, "utf8");
}
