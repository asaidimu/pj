// src/module/document/prompts.ts - README-generation prompt template wrapper
import { join } from "path";
import { loadTemplate, renderTemplate } from "../../utils/prompt";

const TEMPLATE = join(import.meta.dir, "prompt.txt");

// Slots: {{CODEBASE_SUMMARY}}
export function createPrompt(codebaseSummary: string): string {
  return renderTemplate(loadTemplate(TEMPLATE), {
    CODEBASE_SUMMARY: codebaseSummary,
  });
}
