// Import protocol files as strings from the shared location
import CONTEXT_HANDLING from "../../agent/_protocols/context-handling.md";
import ERROR_HANDLING from "../../agent/_protocols/error-handling.md";
import ESCALATION from "../../agent/_protocols/escalation.md";
import PLAN_VERSIONING from "../../agent/_protocols/plan-versioning.md";

const PROTOCOLS: Record<string, string> = {
  "_protocols/context-handling.md": CONTEXT_HANDLING,
  "_protocols/error-handling.md": ERROR_HANDLING,
  "_protocols/escalation.md": ESCALATION,
  "_protocols/plan-versioning.md": PLAN_VERSIONING,
};

/**
 * Expands protocol references in a prompt string.
 * Replaces markdown links like [Protocol Name](_protocols/file.md)
 * with the full protocol content.
 */
export function expandProtocols(prompt: string): string {
  return prompt.replace(
    /\[([^\]]+)\]\((_protocols\/[^)]+\.md)\)/g,
    (match, name, path) => {
      const content = PROTOCOLS[path];
      if (!content) {
        throw new Error(`Unknown protocol: ${path}`);
      }
      // Return the full protocol content with a header
      return `\n\n---\n## ${name}\n\n${content}\n---\n`;
    },
  );
}
