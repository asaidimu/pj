#!/usr/bin/env bun

import { join, resolve } from "path";
import { readdir, readFile, stat, writeFile, mkdir } from "fs/promises";
import { homedir } from "os";
import { parseArgs } from "util";
import { createPrompt } from "./prompts"

// Framework metadata
const FRAMEWORK_NAME = "pj";
const FRAMEWORK_VERSION = "1.0.0";

// ANSI color utilities
const bold = (text: string) => `\x1b[1m${text}\x1b[0m`;
const blue = (text: string) => `\x1b[34m${text}\x1b[0m`;
const prompt = (text: string) => `\x1b[32m${text}\x1b[0m`;

// Interface for parsed arguments
interface Args {
  targetDir: string;
  filesPattern: string[];
  excludePattern: string[];
  outputFile: string | undefined;
}

// Parse command-line arguments
function parseArgsCustom(): Args {
  const { values, positionals } = parseArgs({
    args: Bun.argv.slice(2),
    options: {
      files: { type: "string", short: "f", multiple: true },
      exclude: { type: "string", short: "x", multiple: true },
      output: { type: "string", short: "o" },
    },
    allowPositionals: true,
  });


  const targetDir = positionals[0] ?? process.cwd();
  const filesPattern = values.files ?? [];
  const excludePattern = values.exclude ?? [];
  const outputFile = values.output;

  if (positionals.length > 1) {
    console.error("Error: Multiple directory arguments provided.");
    process.exit(1);
  }

  if (!Bun.file(targetDir).exists()) {
    console.error(`Error: Directory '${targetDir}' is not valid.`);
    process.exit(1);
  }

  return {
    targetDir: resolve(targetDir),
    filesPattern,
    excludePattern,
    outputFile,
  };
}

// Convert glob pattern to regex
function globToRegex(pattern: string): RegExp {
  const escaped = pattern
    .replace(/[-[\]{}()+?.,\\^$|#\s]/g, "\\$&")
    .replace(/\*/g, ".*")
    .replace(/\//g, "\\/");
  return new RegExp(`^${escaped}$`);
}

// Check if file is readable, non-empty, non-binary, and not too large
async function safeReadFile(filepath: string): Promise<string | null> {
  try {
    const stats = await stat(filepath);
    if (!stats.isFile() || stats.size === 0 || stats.size > 1048576) {
      return null;
    }

    const sample = await readFile(filepath, { encoding: "utf8", flag: "r" });
    if (sample.includes("\0")) {
      return null;
    }

    const lines = sample.split("\n").slice(0, 50).join("\n");
    return lines;
  } catch {
    return null;
  }
}

// Collect files matching patterns
async function collectFiles(
  dir: string,
  includePatterns: string[],
  excludePatterns: string[],
): Promise<string[]> {
  const includeRegexes = includePatterns.length
    ? includePatterns.map(globToRegex)
    : [/.*/];
  const excludeRegexes = excludePatterns.map(globToRegex);
  const files: string[] = [];

  async function traverse(currentDir: string) {
    const entries = await readdir(currentDir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = join(currentDir, entry.name);
      if (entry.name.startsWith(".")) continue; // Skip hidden files

      if (entry.isDirectory()) {
        if (!excludePatterns.some((p) => fullPath.includes(p))) {
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

// Generate codebase summary
async function generateCodebaseSummary(files: string[]): Promise<string> {
  let summary = "";
  let fileCount = 0;

  for (const filepath of files) {
    const content = await safeReadFile(filepath);
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
    },
  );

  const data = await response.json();
  if (data.error) {
    console.error(`Error: API request failed - ${data.error.message}`);
    process.exit(1);
  }

  const analysis = data.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!analysis) {
    console.error("Error: Could not extract analysis from API response");
    process.exit(1);
  }

  return analysis;
}

// Main execution
async function main() {
  const { targetDir, filesPattern, excludePattern, outputFile } =
    parseArgsCustom();

  if (!outputFile) {
    console.error("Error: No output file specified");
    process.exit(1);
  }

  console.error(`Searching for files in: ${targetDir}`);
  if (filesPattern.length)
    console.error(`File patterns: ${filesPattern.join(" ")}`);
  if (excludePattern.length)
    console.error(`Exclude patterns: ${excludePattern.join(" ")}`);

  const files = await collectFiles(targetDir, filesPattern, excludePattern);
  const codebaseSummary = await generateCodebaseSummary(files);
  const prompt = createPrompt(codebaseSummary);
  const analysis = await callGeminiApi(prompt);
  await writeFile(outputFile, analysis);
}

await main().catch((err) => {
  console.error(`Error: ${err.message}`);
  process.exit(1);
});

