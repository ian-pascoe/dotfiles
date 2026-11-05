---
name: plannotator-rex
description: Open a Markdown plan or document for the human to review and annotate in a Rex popup; their feedback arrives as your next message. Use inside Rex (REX_BLOCK is set) when you have written a plan, spec, or design document that needs human review before you act on it.
metadata:
  requires-env: REX_BLOCK
  requires-tool: bash|powershell
---

# plannotator-rex: hand a document to the human for review in Rex

Only when `REX_BLOCK` is set (you are running inside Rex). Inside Herdr (`HERDR_ENV=1`), use the
plannotator-tui skill instead. Otherwise tell the human where the file is and ask them to review it.

1. Write the document to a file. Do not paste it into chat as well.
2. Open it for review, from your own pane:

   ```bash
   rex-plannotator open docs/plans/auth.md
   ```

   plannotator-tui opens in a popup over your pane, already knowing that feedback comes back to
   this pane.
3. **End your turn.** Do not wait, poll, or read the popup. The review arrives as the next user
   message, as numbered feedback:

   ```
   ## Annotation 1 (line 12)
   Comment on: "Rotate the token on every…"
   > Rotation on every privilege change will log people out…
   ```

   Address every item, then continue.

When you need an explicit sign-off before you act, open it with `--gate`:

```bash
rex-plannotator open docs/plans/auth.md --gate
```

The human can then approve. An approval arrives as `The user approved.`, or as a message headed
`# Approved with Notes` whose notes are guidance, not a request to revise. Numbered feedback
still means revise; no message means they closed it without deciding.
