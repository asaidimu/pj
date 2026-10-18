#!/usr/bin/env bun

import {
  runAgent,
  agentMain,
  collectFiles,
  generateCodebaseSummary,
  type AgentContext,
} from "../../utils/gemini";
import { createPrompt } from "./prompts";

// Hydration: walk the codebase (gitignore + defaults excluded) -> full
// summary -> README prompt
agentMain(
  runAgent({
    label: "Generating README for codebase in",
    defaultOutput: ".readme.md",
    options: {
      files: { type: "string", short: "f", multiple: true },
      exclude: { type: "string", short: "x", multiple: true },
    },
    note: ({ values }: AgentContext) => {
      const files = values.files as string[] | undefined;
      const exclude = values.exclude as string[] | undefined;
      if (files?.length) console.error(`File patterns: ${files.join(" ")}`);
      if (exclude?.length)
        console.error(`Additional excludes: ${exclude.join(" ")}`);
    },
    hydrate: async ({ targetDir, values }: AgentContext) => {
      const files = await collectFiles(
        targetDir,
        (values.files as string[]) ?? [],
        (values.exclude as string[]) ?? [],
      );
      // full file contents (1MB cap) for richer README context
      const summary = await generateCodebaseSummary(files);
      return createPrompt(summary);
    },
  }),
);
