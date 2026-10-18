// src/utils/gemini.ts - shared runner for the Gemini-backed agent modules
//
// The agent modules (commit, analyze, document) are the same shell with
// custom hydration: parse args -> hydrate inputs -> render prompt ->
// call Gemini -> write output. This module holds the shared parts so each
// module's main.ts only keeps its hydration. User plugins can build their
// own Gemini-backed commands on the same pieces:
//
//   import { runAgent, collectFiles, generateCodebaseSummary }
//     from "$FRAMEWORK_PATH/src/utils/gemini";
//
// Prompts stay per-module plain-text templates (prompt.txt + prompts.ts,
// see src/utils/prompt.ts); hydrate renders one and runAgent sends it.
import { join, resolve } from "path";
import { statSync } from "fs";
import { readdir, readFile, stat, writeFile } from "fs/promises";
import { parseArgs } from "util";

// ---- Gemini API -------------------------------------------------------------

// Call Gemini with a fully rendered prompt. Reads GEMINI_API_KEY and the
// framework-named model override (PJ_GEMINI_MODEL, or <UPPER_NAME>_GEMINI_MODEL
// when the framework is renamed).
export async function callGeminiApi(prompt: string): Promise<string> {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error("Error: GEMINI_API_KEY not set");
    process.exit(1);
  }
  const framework = process.env.FRAMEWORK_NAME || "pj";
  const model =
    process.env[`${framework.toUpperCase()}_GEMINI_MODEL`] || "gemini-3.8-flash";

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
    },
  );

  const data = await response.json();
  if (data.error) {
    console.error(`Error: API request failed - ${data.error.message}`);
    process.exit(1);
  }

  const result = data.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!result) {
    console.error("Error: Could not extract result from API response");
    process.exit(1);
  }

  return result;
}

// ---- codebase walking (analyze/document) ------------------------------------

// Convert glob pattern to a regex anchored at both ends
export function globToRegex(pattern: string): RegExp {
  const escaped = pattern
    .replace(/[-[\]{}()+?.,\\^$|#\s]/g, "\\$&")
    .replace(/\*/g, ".*")
    .replace(/\//g, "\\/");
  return new RegExp(`^${escaped}$`);
}

// Convert a gitignore-style pattern to a regex matching anywhere in the path
export function gitignoreToRegex(pattern: string): RegExp {
  const escaped = pattern
    .replace(/[-[\]{}()+?.,\\^$|#\s]/g, "\\$&")
    .replace(/\*\*/g, "\u0000")
    .replace(/\*/g, "[^/]*")
    .replace(/\u0000/g, ".*")
    .replace(/\//g, "\\/");
  return new RegExp(escaped);
}

// Sensible defaults: build/vendor dirs for Go, TypeScript/Node, and general junk
export const DEFAULT_EXCLUDES = [
  // Node.js / TypeScript
  "node_modules",
  "dist",
  "build",
  "out",
  "coverage",
  "*.min.js",
  "*.min.css",
  "*.map",
  // Go
  "vendor",
  "*.test",
  // General
  "__pycache__",
  ".cache",
  "*.log",
  "*.tmp",
];

// Parse .gitignore in the target directory into exclude regexes
export async function parseGitignore(dir: string): Promise<RegExp[]> {
  const gitignorePath = join(dir, ".gitignore");
  let content: string;
  try {
    content = await readFile(gitignorePath, "utf8");
  } catch {
    return [];
  }
  return content
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith("#") && !line.startsWith("!"))
    .map((line) => line.replace(/\/$/, "")) // strip trailing slash (dir-only marker)
    .map(gitignoreToRegex);
}

// Read a file if it is readable, non-empty, non-binary, and not too large.
// maxLines truncates the content (analyze samples the first 50 lines;
// omit it to read the whole file up to the 1MB cap).
export async function safeReadFile(
  filepath: string,
  maxLines?: number,
): Promise<string | null> {
  try {
    const stats = await stat(filepath);
    if (!stats.isFile() || stats.size === 0 || stats.size > 1048576) {
      return null;
    }

    const content = await readFile(filepath, { encoding: "utf8", flag: "r" });
    if (content.includes("\0")) {
      return null;
    }

    if (maxLines === undefined) return content;
    return content.split("\n").slice(0, maxLines).join("\n");
  } catch {
    return null;
  }
}

// Collect files under dir matching include patterns, excluding user
// patterns, DEFAULT_EXCLUDES, and the directory's .gitignore. Skips
// hidden files/dirs; caps at 100 files.
export async function collectFiles(
  dir: string,
  includePatterns: string[],
  excludePatterns: string[],
): Promise<string[]> {
  const includeRegexes = includePatterns.length
    ? includePatterns.map(globToRegex)
    : [/.*/];

  const gitignoreRegexes = await parseGitignore(dir);
  const excludeRegexes = [
    ...excludePatterns.map(gitignoreToRegex),
    ...DEFAULT_EXCLUDES.map(gitignoreToRegex),
    ...gitignoreRegexes,
  ];

  const files: string[] = [];

  async function traverse(currentDir: string) {
    const entries = await readdir(currentDir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = join(currentDir, entry.name);
      if (entry.name.startsWith(".")) continue; // Skip hidden files

      if (entry.isDirectory()) {
        if (!excludeRegexes.some((regex) => regex.test(fullPath))) {
          await traverse(fullPath);
        }
      } else if (
        includeRegexes.some((regex) => regex.test(fullPath)) &&
        !excludeRegexes.some((regex) => regex.test(fullPath))
      ) {
        files.push(fullPath);
      }
    }
  }

  await traverse(dir);
  return files.slice(0, 100);
}

// Concatenate processed files into a single summary blob. maxLines is
// passed through to safeReadFile. Exits if nothing was processable.
export async function generateCodebaseSummary(
  files: string[],
  maxLines?: number,
): Promise<string> {
  let summary = "";
  let fileCount = 0;

  for (const filepath of files) {
    const content = await safeReadFile(filepath, maxLines);
    if (content) {
      console.log(`Processing: ${filepath}`);
      summary += `--- start of file ${filepath} ---\n${content}\n--- end of file ${filepath} ---\n\n`;
      fileCount++;
    } else {
      console.error(`Skipped (not processable): ${filepath}`);
    }
  }

  console.log(`Total files found: ${files.length}, processed: ${fileCount}`);
  if (fileCount === 0) {
    console.error("Error: No processable files found.");
    process.exit(1);
  }

  return summary;
}

// ---- agent runner -----------------------------------------------------------

// Values parseArgs produced: module-specific options are string, boolean,
// or string[] depending on the spec.
export type AgentValues = Record<
  string,
  string | boolean | string[] | undefined
>;

export interface AgentContext {
  targetDir: string;
  values: AgentValues;
  positionals: string[];
}

export interface AgentSpec {
  // stderr progress line printed before hydration
  label: string;
  // output file when --output is not passed (e.g. ".commit-message.md")
  defaultOutput: string;
  // module-specific CLI options merged with the common --output
  options?: Record<string, { type: "string" | "boolean"; short?: string; multiple?: boolean; default?: string | boolean }>;
  // extra stderr lines after the label (file patterns, staged mode, ...)
  note?: (ctx: AgentContext) => void;
  // the module's custom part: gather inputs and return the rendered prompt
  hydrate: (ctx: AgentContext) => Promise<string>;
}

// The extracted agent pattern: parse args, validate the target directory,
// run the module's hydration, send the prompt to Gemini, and write the
// result to the output file in the current working directory (where the
// module's shell wrapper looks for it).
export async function runAgent(spec: AgentSpec): Promise<void> {
  const { values, positionals } = parseArgs({
    args: Bun.argv.slice(2),
    options: {
      output: { type: "string", short: "o" },
      ...spec.options,
    },
    allowPositionals: true,
  });

  const targetDir = positionals[0] ?? process.cwd();

  if (positionals.length > 1) {
    console.error("Error: Multiple directory arguments provided.");
    process.exit(1);
  }

  try {
    statSync(targetDir);
  } catch {
    console.error(`Error: Directory '${targetDir}' is not valid.`);
    process.exit(1);
  }

  const resolvedDir = resolve(targetDir);
  const outputFile = (values.output as string) ?? spec.defaultOutput;
  const ctx: AgentContext = { targetDir: resolvedDir, values, positionals };

  console.error(`${spec.label}: ${resolvedDir}`);
  spec.note?.(ctx);

  const prompt = await spec.hydrate(ctx);
  const result = await callGeminiApi(prompt);
  await writeFile(resolve(outputFile), result);
}

// Common epilogue for agent main.ts entry points
export function agentMain(promise: Promise<void>): void {
  promise.catch((err) => {
    console.error(`Error: ${err.message}`);
    process.exit(1);
  });
}
