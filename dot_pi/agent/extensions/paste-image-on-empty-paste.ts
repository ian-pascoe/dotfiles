import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/** A bracketed paste with nothing in it. */
export const EMPTY_PASTE = "\x1b[200~\x1b[201~";
/** Ctrl+V, Pi's default `app.clipboard.pasteImage` key. */
export const CTRL_V = "\x16";

/**
 * Makes Cmd+V paste clipboard images. When the clipboard holds only an image,
 * macOS terminals such as Tern send an empty bracketed paste for Cmd+V. This
 * turns that into Ctrl+V, which runs Pi's own image paste.
 */
export default function pasteImageOnEmptyPaste(pi: ExtensionAPI) {
  let unsubscribe: (() => void) | undefined;

  pi.on("session_start", (_event, ctx) => {
    if (!ctx.hasUI) return;
    unsubscribe?.();
    unsubscribe = ctx.ui.onTerminalInput((data) =>
      data === EMPTY_PASTE ? { data: CTRL_V } : undefined,
    );
  });

  pi.on("session_shutdown", () => {
    unsubscribe?.();
    unsubscribe = undefined;
  });
}
