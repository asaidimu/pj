#!/usr/bin/env bun

import {
  runAgent,
  agentMain,
  collectFiles,
  generateCodebaseSummary,
  type AgentContext,
} from "../../utils/gemini";
import { createPrompt } from "./prompts";

// Hydration: walk the codebase (gitignore + defaults excluded) -> summary -> prompt
agentMain(
  runAgent({
    label: "Searching for files in",
    defaultOutput: ".analysis.md",
    options: {
      files: { type: "string", short: "f", multiple: true },
      exclude: { type: "string", short: "x", multiple: true },
    },
    note: ({ targetDir, values }: AgentContext) => {
      console.error(
        "Excluding: defaults (node_modules, vendor, dist, build, ...), .gitignore",
      );
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
      // sample the first 50 lines per file to keep the payload small
      const summary = await generateCodebaseSummary(files, 50);
      return createPrompt(summary);
    },
  }),
);
