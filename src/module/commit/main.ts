#!/usr/bin/env bun

import { resolve, join } from "path";
import { exec } from "child_process";
import { promisify } from "util";
import { readFile, writeFile } from "fs/promises";
import { parseArgs } from "util";

// ANSI color utilities
const bold = (text: string) => `\x1b[1m${text}\x1b[0m`;
const blue = (text: string) => `\x1b[34m${text}\x1b[0m`;
const prompt = (text: string) => `\x1b[32m${text}\x1b[0m`;

// Interface for parsed arguments
interface Args {
  targetDir: string;
  staged: boolean;
  type: string | undefined;
  docs: string;
  outputFile: string | undefined;
}

// Parse command-line arguments
function parseArgsCustom(): Args {
  const { values, positionals } = parseArgs({
    args: Bun.argv.slice(2),
    options: {
      staged: { type: "boolean", short: "s" },
      type: { type: "string", short: "t" },
      docs: { type: "string", short: "d", default: "README.md" },
      output: { type: "string", short: "o" },
    },
    allowPositionals: true,
  });

  const targetDir = positionals[0] ?? process.cwd();
  const staged = !!values.staged;
  const type = values.type;
  const docs = values.docs;
  const outputFile = values.output ?? ".commit-message.md";

  if (positionals.length > 1) {
    console.error("Error: Multiple directory arguments provided.");
    process.exit(1);
  }

  if (!Bun.file(targetDir).exists()) {
    console.error(`Error: Directory '${targetDir}' is not valid.`);
    process.exit(1);
  }

  return { targetDir: resolve(targetDir), staged, type, docs, outputFile };
}

// Execute git diff
async function getGitDiff(dir: string, staged: boolean): Promise<Record<string, string>> {
  const execAsync = promisify(exec);
  try {

    const { stdout:branch } = await execAsync("git branch --show-current",{ cwd: dir }
    );
    if (!branch) {
      console.error("Error: Not in a git repository");
      process.exit(1);
    }

    const { stdout:diff } = await execAsync(
      staged ? "git diff --staged" : "git diff",
      { cwd: dir }
    );

    if (!diff) {
      console.error("Error: No changes found in git diff.");
      process.exit(1);
    }
    return { diff, branch};
  } catch (err) {
    console.error(`Error: Failed to execute git diff in ${dir}. Ensure it is a git repository.`);
    process.exit(1);
  }
}

// Read documentation file
async function readDocsFile(dir: string, docsPath: string): Promise<string | null> {
  const fullPath = join(dir, docsPath);
  try {
    const content = await readFile(fullPath, "utf8");
    if (!content) {
      console.error(`Warning: Documentation file '${fullPath}' is empty.`);
      return null;
    }
    return content;
  } catch (err) {
    console.error(`Warning: Could not read documentation file '${fullPath}'. Skipping.`);
    return null;
  }
}

export function stripMarkdown(markdown: string): string {
  return markdown
    // Remove code blocks ```...```
    .replace(/```[\s\S]*?```/g, '')
    // Remove inline code `...`
    .replace(/`([^`]+)`/g, '$1')
    // Remove bold and italic **...** or __...__ or *...* or _..._
    .replace(/(\*\*|__)(.*?)\1/g, '$2')
    .replace(/(\*|_)(.*?)\1/g, '$2')
    // Remove headers #####
    .replace(/^#{1,6}\s*/gm, '')
    // Remove unordered list markers (-, *, +) at line start
    .replace(/^\s*([-*+])\s+/gm, '')
    // Remove ordered list numbers (1., 2., etc) at line start
    .replace(/^\s*\d+\.\s+/gm, '')
    // Remove blockquotes '>' at line start
    .replace(/^\s*>\s?/gm, '')
    // Remove horizontal rules ---
    .replace(/^-{3,}\s*$/gm, '')
    // Remove extra spaces
    .replace(/\s+$/gm, '')
    .trim();
}

// Gemini API prompt for conventional commit
function createPrompt(branch:string, diff: string, docsContent: string | null, commitType?: string): string {
    const prompt = `You are a senior software engineer and release manager. Your task is to generate a single, complete Conventional Commit message based on the Git diff provided below. This message will be used in an automated release pipeline powered by semantic-release (https://github.com/semantic-release/semantic-release) and must strictly follow the Conventional Commits specification.

---
### Project Documentation
${docsContent ? `
The following is the full content of the project's documentation file (e.g., README.md) to provide context about the project's purpose, structure, or features:

\`\`\`markdown
${docsContent}
\`\`\`
` : "No documentation file provided or available."}

### Git branch
${branch}
### Git Diff

\`\`\`diff
${diff}
\`\`\`

---

### IMPORTANT: OUTPUT FORMAT MUST BE PLAIN TEXT ONLY

- Your response **MUST BE ONLY PLAIN TEXT**.
- **Do NOT include any markdown syntax** such as backticks, code blocks, asterisks, underscores, or other formatting.
- The commit message must be exactly as it would appear in a git commit, readable in any terminal or tool.
- Any markdown formatting in your output WILL BREAK downstream tooling like semantic-release and changelog generators.
- Treat this as a strict requirement, not a suggestion.
- The master branch for release is 'main'. DO NOT INDICATE BREAKING CHANGES ON BRANCHES THAT ARE NOT MAIN. EVEN IF THEY ARE BREAKING CHANGES

---

### Instructions

1. Purpose

Each commit message contributes directly to automated versioning and changelog generation. A correct commit message:
- Determines the semantic version bump (major, minor, patch)
- Signals whether a release should occur
- Is parsed by semantic-release to automate changelogs and GitHub releases

If the change affects functionality visible to users (CLI flags, public API behavior, configuration options), ensure README.md or relevant documentation is updated accordingly.

No change is too small to commit. Every commit affects the release outcome, however be aware of the branch you are on.


2. Analyze the Change

From the diff, determine:
- What was changed? (feature, bug fix, refactor, formatting, etc.)
- Why was it changed? (to add, improve, fix, restructure)
- Is the change breaking? (affects backward compatibility or contract)
- Should the change be visible in the changelog?
- Is README.md or other documentation out of sync?

3. Determine Commit Components

- Type: Infer the type from:
  - feat: new feature
  - fix: bug fix
  - docs: documentation only (e.g., README.md)
  - style: formatting or whitespace only (no behavior change)
  - refactor: code change without behavior change
  - perf: performance improvement
  - test: tests only
  - build: build system or dependencies
  - ci: CI/CD config
  - chore: misc maintenance
  - revert: reverts previous commit

- Scope: short lowercase keyword for affected module or feature (auth, api, cli, config, deps)

- Description:
  - Use imperative mood (add, fix, refactor, not adds or fixed)
  - Limit to 50–72 characters
  - Focus on primary intent or outcome

- Breaking Changes:
  - Append ! after scope if breaking
  - Add a BREAKING CHANGE: footer with impact and migration instructions

- Extended Body (optional):
  - Use to clarify complex changes, rationale, or migration notes

4. Output Format

Return exactly one valid commit message as plain text **without any markdown formatting**.

Accepted formats:

Standard (summary only):
<type>(<scope>): <short summary>

With body:
<type>(<scope>): <short summary>

<detailed explanation or list of changes>

With breaking change:
<type>(<scope>)!: <short summary>

BREAKING CHANGE: <impact, motivation, migration instructions>

5. Additional Notes

- The commit message directly affects automated releases via semantic-release.
- If the change impacts user-facing behavior or public API, README.md or relevant documentation must be updated.
- Under no circumstances include markdown formatting.
- If no meaningful change is detected, return an error message explaining why.

---

### Examples

Simple fix:
fix(auth): correct token expiration logic

Multiple related changes:
feat(api): support pagination in search endpoint

- Add page and limit query parameters
- Update swagger docs to reflect API change

Breaking refactor:
refactor(config)!: remove deprecated env variables

BREAKING CHANGE: The following environment variables are no longer supported:
- APP_SECRET
- ENABLE_DEBUG

Use CONFIG_SECRET and LOG_LEVEL instead. See migration guide.

README update related to release:
docs(readme): document new CLI --dry-run flag

---

Summary:

- Write exactly one valid Conventional Commit message in **plain text only**
- No markdown anywhere in your output
- The message must be compatible with semantic-release
- Be precise, consistent, and deliberate
`;

    return prompt
}

// Call Gemini API
async function callGeminiApi(prompt: string): Promise<string> {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error("Error: GEMINI_API_KEY not set");
    process.exit(1);
  }
  const model = "gemini-2.5-flash-preview-05-20";

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
    }
  );

  const data = await response.json();
  if (data.error) {
    console.error(`Error: API request failed - ${data.error.message}`);
    process.exit(1);
  }

  const commitMessage = data.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!commitMessage) {
    console.error("Error: Could not extract commit message from API response");
    process.exit(1);
  }

  return commitMessage;
}

// Main execution
async function main() {
  const { targetDir, staged, type, docs, outputFile } = parseArgsCustom();

  console.error(`Generating commit message for changes in: ${targetDir}`);
  if (staged) console.error("Using staged changes");
  if (type) console.error(`Using commit type: ${type}`);
  console.error(`Using documentation file: ${docs}`);

  const {diff, branch} = await getGitDiff(targetDir, staged);
  const docsContent = await readDocsFile(targetDir, docs);
  const prompt = createPrompt(branch, diff, docsContent, type);
  const commitMessage = await callGeminiApi(prompt);
  await writeFile(join(targetDir, outputFile), commitMessage);
}

await main().catch((err) => {
  console.error(`Error: ${err.message}`);
  process.exit(1);
});
