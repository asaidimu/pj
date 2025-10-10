#!/usr/bin/env bun

import { join, resolve } from "path";
import { readdir, readFile, stat, writeFile } from "fs/promises";
import { parseArgs } from "util";

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
  const outputFile = values.output ?? ".readme.md";

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

    return sample;
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

// Gemini API prompt for README generation
function createPrompt(codebaseSummary: string): string {
  return `# README Generation Task

You are an expert technical writer and software architect. Generate a comprehensive, professional README.md file in markdown format based on the provided codebase snapshot. The README should be publication-ready for a public repository and follow modern documentation standards.

## Codebase Analysis
\`\`\`
${codebaseSummary}
\`\`\`

## Required Structure

Generate a **complete markdown document** with these sections in order:

### 1. Header Section
- **Project Title**: Clear, descriptive name (infer from package.json, directory structure, or main functionality)
- **Brief Description**: One-sentence overview of the project's primary purpose
- **Badges** (if applicable): Version, license, build status placeholders using shields.io format
- **Quick Links**: Table of contents for easy navigation

### 2. Overview & Features
- **Detailed Description**: 2-3 paragraphs explaining what the project does and why it exists
- **Key Features**: Bulleted list of main functionalities, inferred from:
  - CLI commands and options
  - API endpoints and methods
  - Plugin capabilities
  - Configuration options
  - File processing capabilities

### 3. Installation & Setup
- **Prerequisites**: Required software, versions, environment variables
- **Installation Steps**: Package manager commands, global vs local installation
- **Configuration**: Environment setup, config files, API keys
- **Verification**: How to confirm successful installation

### 4. Usage Documentation
- **Basic Usage**: Simple examples with expected output
- **CLI Commands**: Complete command reference with options and flags
- **API Usage**: Code examples for programmatic usage
- **Configuration Examples**: Sample config files with explanations
- **Common Use Cases**: Real-world scenarios with step-by-step instructions

### 5. Project Architecture
- **Core Components**: Brief explanation of main modules/classes. Do not mention filepaths as these may change.
- **Data Flow**: How components interact (if complex)
- **Extension Points**: Plugin system, hooks, or customization options

### 6. Development & Contributing
- **Development Setup**: How to set up for local development
- **Scripts**: Available npm/yarn scripts and their purposes
- **Testing**: How to run tests, coverage requirements
- **Contributing Guidelines**: PR process, coding standards, commit conventions
- **Issue Reporting**: How to report bugs or request features

### 7. Additional Information
- **Troubleshooting**: Common issues and solutions
- **FAQ**: Anticipated questions based on functionality
- **Changelog/Roadmap**: Link to changelog or future plans
- **License**: License type and link to full text
- **Acknowledgments**: Credits, inspirations, or related projects

## Content Guidelines

### Technical Accuracy
- Infer technology stack from dependencies, file extensions, and imports
- Identify framework patterns (Express, CLI tools, build systems, etc.)
- Recognize common conventions (TypeScript, ESLint, Prettier, etc.)
- Detect testing frameworks and build tools

### Writing Style
- Use active voice and present tense
- Write for developers of varying experience levels
- Include practical examples with realistic data
- Explain "why" not just "how" for complex features
- Use consistent terminology throughout

### Code Examples
- Provide brief, working, copy-pasteable examples.
- Use proper syntax highlighting with language tags
- Include error handling in examples where relevant

### Formatting Standards
- Use proper markdown hierarchy (# ## ### ####)
- Include code blocks with appropriate language tags
- Use tables for structured data (commands, options, etc.)
- Add horizontal rules to separate major sections
- Include emoji sparingly for visual breaks (📁 🚀 ⚡ etc.)

## Special Considerations

### For CLI Tools
- Document all commands, subcommands, and options
- Show help output and usage patterns
- Include installation verification steps
- Explain configuration file locations and formats

### For Libraries/APIs
- Provide import/require statements
- Show initialization and basic usage
- Document main classes, methods, and properties
- Include TypeScript definitions if applicable

### For Frameworks/Plugins
- Explain integration process
- Show configuration examples
- Document extension/plugin development
- Include compatibility information

## Output Requirements

- Generate **only** the markdown content (no meta-commentary)
- Ensure all sections are complete with realistic content
- Use proper markdown syntax throughout
- Include placeholder links that follow realistic patterns
- Make content specific to the analyzed codebase, not generic templates
- Ensure the README is immediately usable without further editing
- The README should always reflect the current codebase state. Do not regurgitate stale documentation.

---

**Generate the complete README.md content now:**`;
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

  const readmeContent = data.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!readmeContent) {
    console.error("Error: Could not extract README content from API response");
    process.exit(1);
  }

  return readmeContent;
}

// Main execution
async function main() {
  const { targetDir, filesPattern, excludePattern, outputFile } = parseArgsCustom();

  console.error(`Generating README for codebase in: ${targetDir}`);
  if (filesPattern.length)
    console.error(`File patterns: ${filesPattern.join(" ")}`);
  if (excludePattern.length)
    console.error(`Exclude patterns: ${excludePattern.join(" ")}`);

  const files = await collectFiles(targetDir, filesPattern, excludePattern);
  const codebaseSummary = await generateCodebaseSummary(files);
  const prompt = createPrompt(codebaseSummary);
  const readmeContent = await callGeminiApi(prompt);
  await writeFile(join(targetDir, outputFile), readmeContent);
}

await main().catch((err) => {
  console.error(`Error: ${err.message}`);
  process.exit(1);
});
