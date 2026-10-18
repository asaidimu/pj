#!/usr/bin/env bun

import { resolve, join } from "path";
import { exec } from "child_process";
import { promisify } from "util";
import { readFile, writeFile } from "fs/promises";
import { parseArgs } from "util";
import { createPrompt } from "./prompts";

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

// Call Gemini API
async function callGeminiApi(prompt: string): Promise<string> {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error("Error: GEMINI_API_KEY not set");
    process.exit(1);
  }
  // respects the framework's env naming: PJ_GEMINI_MODEL (or <UPPER_FRAMEWORK_NAME>_GEMINI_MODEL)
  const framework = process.env.FRAMEWORK_NAME || "pj";
  const model = process.env[`${framework.toUpperCase()}_GEMINI_MODEL`] || "gemini-3.8-flash";

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
  const prompt = createPrompt(branch, diff, docsContent);
  const commitMessage = await callGeminiApi(prompt);
  await writeFile(join(targetDir, outputFile), commitMessage);
}

await main().catch((err) => {
  console.error(`Error: ${err.message}`);
  process.exit(1);
});
