#!/usr/bin/env bun

import { join } from "path";
import { exec } from "child_process";
import { promisify } from "util";
import { readFile } from "fs/promises";
import { runAgent, agentMain, type AgentContext } from "../../utils/gemini";
import { createPrompt } from "./prompts";

// Hydration: git branch + diff (+ optional docs file) -> commit prompt
async function getGitDiff(
  dir: string,
  staged: boolean,
): Promise<{ diff: string; branch: string }> {
  const execAsync = promisify(exec);
  try {
    const { stdout: branch } = await execAsync("git branch --show-current", {
      cwd: dir,
    });
    if (!branch) {
      console.error("Error: Not in a git repository");
      process.exit(1);
    }

    const { stdout: diff } = await execAsync(
      staged ? "git diff --staged" : "git diff",
      { cwd: dir },
    );

    if (!diff) {
      console.error("Error: No changes found in git diff.");
      process.exit(1);
    }
    return { diff, branch };
  } catch {
    console.error(
      `Error: Failed to execute git diff in ${dir}. Ensure it is a git repository.`,
    );
    process.exit(1);
  }
}

async function readDocsFile(
  dir: string,
  docsPath: string,
): Promise<string | null> {
  const fullPath = join(dir, docsPath);
  try {
    const content = await readFile(fullPath, "utf8");
    if (!content) {
      console.error(`Warning: Documentation file '${fullPath}' is empty.`);
      return null;
    }
    return content;
  } catch {
    console.error(
      `Warning: Could not read documentation file '${fullPath}'. Skipping.`,
    );
    return null;
  }
}

agentMain(
  runAgent({
    label: "Generating commit message for changes in",
    defaultOutput: ".commit-message.md",
    options: {
      staged: { type: "boolean", short: "s" },
      type: { type: "string", short: "t" },
      docs: { type: "string", short: "d", default: "README.md" },
    },
    note: ({ values }: AgentContext) => {
      if (values.staged) console.error("Using staged changes");
      if (values.type) console.error(`Using commit type: ${values.type}`);
      console.error(`Using documentation file: ${values.docs ?? "README.md"}`);
    },
    hydrate: async ({ targetDir, values }: AgentContext) => {
      const { diff, branch } = await getGitDiff(targetDir, !!values.staged);
      const docsContent = await readDocsFile(
        targetDir,
        (values.docs as string) ?? "README.md",
      );
      return createPrompt(branch, diff, docsContent);
    },
  }),
);
