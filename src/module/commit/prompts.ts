// src/module/commit/prompts.ts - commit-message prompt template wrapper
import { join } from "path";
import { loadTemplate, renderTemplate } from "../../utils/prompt";

const TEMPLATE = join(import.meta.dir, "prompt.txt");

// Build the documentation section: the template always has a slot, the
// surrounding prose depends on whether a docs file was readable.
function docsSection(docsContent: string | null): string {
  if (!docsContent) {
    return "No documentation file provided or available.";
  }
  return `The following is the full content of the project's documentation file (e.g., README.md) to provide context about the project's purpose, structure, or features:

\`\`\`markdown
${docsContent}
\`\`\``;
}

// Slots: {{DOCS}} {{BRANCH}} {{DIFF}}
export function createPrompt(
  branch: string,
  diff: string,
  docsContent: string | null,
): string {
  return renderTemplate(loadTemplate(TEMPLATE), {
    DOCS: docsSection(docsContent),
    BRANCH: branch,
    DIFF: diff,
  });
}
