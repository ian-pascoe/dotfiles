# Global AGENTS.md / CLAUDE.md best practices

Scope: a user-level instruction file that every coding-agent session loads, regardless of repository.
Method: primary sources only (vendor docs, the agents.md spec, pi's installed source and docs, arXiv papers). Every claim carries a source ID `[Sn]`; the full URL or local path is in the Sources section. Claims marked **(inference)** are my synthesis, not a source's statement.

Status of this machine (checked, not changed): no global instruction file is deployed for any harness. `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.config/opencode/AGENTS.md` and `~/.pi/agent/AGENTS.md` are all absent. The chezmoi source has `dot_pi/agent/AGENTS.md` (0 bytes, untracked), so it would deploy to `~/.pi/agent/AGENTS.md` on apply [S23]. Per the repo's own rules, deployment needs user approval [S23].

---

## 1. Summary: top 10 recommendations for a GLOBAL file

1. **Include only facts true in every repository you touch.** Personal preferences, working agreements, communication style, and environment facts belong globally. Build commands, architecture, and conventions belong in each project's file. Claude's own table puts "Personal preferences for all projects" in `~/.claude/CLAUDE.md` and "Project architecture, coding standards" in the project file [S2]. Codex's global example is three working agreements, not repo facts [S5].

2. **Keep it very short.** Claude's target is "under 200 lines per CLAUDE.md file" [S2]. Codex truncates combined instructions at `project_doc_max_bytes` (32 KiB default) [S5]. A global file is paid for in every session in every repo, so every line has a cost: "every line in it takes a little of Claude's attention on _every_ task, whether it's relevant or not" [S3]. (inference: aim for tens of lines, not hundreds.)

3. **Know each harness's global path, and never put a global-looking file in `$HOME`.** Pi reads `<agent-dir>` (default `~/.pi/agent`) and then every directory from the filesystem root down to the cwd [S11][S15]. Claude reads `CLAUDE.md` in "your working directory and every directory above it" [S2]. A stray `~/CLAUDE.md` or `~/AGENTS.md` would therefore load in every project under `$HOME` (inference from the walk-up logic; no harness documents this as a feature).

4. **Write one canonical file and fan it out.** Paths differ per harness (see §2), and only some harnesses read each other's names. Claude can pull in a home-directory file with `@~/...` [S2]. Keep the source in chezmoi and deploy it to each target. Chezmoi's own repo guidance warns that "managed copies change user-level behavior" [S23].

5. **Make rules concrete and checkable.** Claude's examples: "Use 2-space indentation" instead of "Format code properly"; "Run `npm test` before committing" instead of "Test your changes" [S2]. Codex's global example follows the same pattern: "Always run `npm test` after modifying JavaScript files" [S5].

6. **Use positive framing: say what to do.** Claude's prompting guide: "Tell Claude what to do instead of what not to do" [S4]. Its example turns "Do not use markdown in your response" into "Your response should be composed of smoothly flowing prose paragraphs" [S4].

7. **Give the reason in one clause.** Claude's guidance: "explaining to Claude why such behavior is important" helps, and "Claude can generalize from the explanation" [S4]. Its example replaces "NEVER use ellipses" with a sentence that says the text is read aloud by a TTS engine [S4].

8. **Do not use CRITICAL / MUST / IMPORTANT / ALL CAPS.** Current Claude models "over-apply" emphasized rules: "piling on emphasis mostly makes Claude over-apply the rule" [S3]. Anthropic's own fix for overtriggering is "Use this tool when..." in place of "CRITICAL: You MUST use this tool when..." [S4]. Note that OpenCode's documentation example itself uses "CRITICAL:" [S7].

9. **Move anything that must always happen into enforcement, not the global file.** CLAUDE.md is "context, not enforced configuration" [S2]. Use deny rules, hooks, or managed settings for hard rules [S2][S3]. Global guidance cannot stop a harness from running a command. Pi's docs add that context files "load regardless of project trust" and should be treated "as untrusted input" [S13]. So keep global text to things you would accept from any project-scoped file.

10. **Prune, verify it loads, and measure.** Confirm what loaded: Claude `/context all` [S2], Gemini `/memory show` [S8], Codex "list the instruction sources you loaded" [S5], pi `/reload` after edits [S11]. Audit for stale or conflicting content with Claude's `/doctor prompt-audit` [S2]. Recent controlled work finds context files usually do not raise task success and add cost [S18][S19], so every rule should earn its place.

---

## 2. How each harness loads global files

| Harness                    | Global path                                                                                                                                                                         | Merge / precedence                                                                                                                                                                                                                                                                                                                                                                                                 | Size limits (as documented)                                                                                                               |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| agents.md spec             | **Not defined.** The spec covers only project and nested files [S1].                                                                                                                | "The closest AGENTS.md to the edited file wins; explicit user chat prompts override everything." [S1]                                                                                                                                                                                                                                                                                                              | None. "No. AGENTS.md is just standard Markdown." [S1]                                                                                     |
| Claude Code                | `~/.claude/CLAUDE.md` (plus `~/.claude/rules/*.md`). Managed-policy file sits above it (`/Library/Application Support/ClaudeCode/CLAUDE.md` on macOS) [S2].                         | Order: managed → user → project → local [S2]. "All discovered files are concatenated into context rather than overriding each other." [S2] Claude reads `AGENTS.md` only when there is no `CLAUDE.md` in the working directory or above; "your `~/.claude/CLAUDE.md`" does not count toward that check [S2].                                                                                                       | Target under 200 lines per file [S2]. Files over 4 MiB are skipped entirely [S2]. Auto memory `MEMORY.md`: first 200 lines or 25 KB [S2]. |
| OpenAI Codex               | `$CODEX_HOME/AGENTS.override.md`, else `$CODEX_HOME/AGENTS.md`; `CODEX_HOME` defaults to `~/.codex` [S5].                                                                           | Global first. "Codex uses only the first non-empty file at this level." Project files walk from git root to cwd, one per directory; "Codex concatenates files from the root down, joining them with blank lines." Later files win by position [S5]. Fallback filenames (`project_doc_fallback_filenames`) apply to project scope only [S5].                                                                        | `project_doc_max_bytes`, 32 KiB default. Codex "stops adding files once the combined size reaches the limit" [S5].                        |
| pi (earendil coding agent) | `<agent-dir>/AGENTS.override.md`, `AGENTS.md`, `AGENTS.MD`, `CLAUDE.md`, or `CLAUDE.MD`, where `<agent-dir>` = `~/.pi/agent` (override with `PI_CODING_AGENT_DIR`) [S11][S12][S14]. | Loader: agent dir first, then each ancestor from root down to cwd; one file per directory (first match in that candidate order); exact-path dedupe [S15]. The global file is pushed first, ancestors are inserted root→cwd [S15]. Injected as `<project_instructions path="...">` blocks in the system prompt [S16]. Not gated by project trust [S11][S13]. `-nc` / `--no-context-files` disables all of it [S14]. | None found in the loader; `loadContextFileFromDir` reads the whole file [S15].                                                            |
| OpenCode                   | `~/.config/opencode/AGENTS.md`. Fallback: `~/.claude/CLAUDE.md` if the first does not exist [S7].                                                                                   | "The first matching file wins in each category." Order: local files walking up, then global `~/.config/opencode/AGENTS.md`, then `~/.claude/CLAUDE.md` [S7]. `OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1` disables the Claude fallback [S7].                                                                                                                                                                            | Not documented [S7].                                                                                                                      |
| Gemini CLI                 | `~/.gemini/GEMINI.md` [S8].                                                                                                                                                         | Global, then project root and ancestors (up to `.git`), then subdirectories. "concatenates the contents of all found files, and sends them to the model with every prompt" [S8]. `context.fileName` can list `AGENTS.md` and others [S8].                                                                                                                                                                          | Not documented [S8].                                                                                                                      |
| GitHub Copilot (personal)  | Set in the GitHub.com UI under "Personal instructions", not a file [S9].                                                                                                            | "Personal instructions take the highest priority. Repository instructions come next…" All sets are sent [S9]. Applies only to Copilot Chat on GitHub.com [S9].                                                                                                                                                                                                                                                     | Not documented [S9].                                                                                                                      |

Practical consequences:

- Claude and OpenCode can read a Claude-style file; Codex reads `AGENTS.md` at global scope and ignores `CLAUDE.md` unless you add it as a fallback name, which only applies to project scope [S5].
- Pi reads `AGENTS.md` or `CLAUDE.md` in its agent directory, so one canonical `AGENTS.md` can serve pi and others [S11][S15].
- Claude's `@path` imports resolve relative to the importing file, and a path outside the working directory triggers an approval prompt in project-level files. User-scope files such as `~/.claude/CLAUDE.md` load their imports without that prompt [S2].

---

## 3. What belongs in a global file vs project file vs skills

| Put it here                                            | Examples (sourced)                                                                                                                                                                                                                                                                                                                                                                                  |
| ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Global file** (cross-repo, personal)                 | Language and tone of responses ("Always respond in Spanish" is a Copilot example [S9]); package-manager preference, "Prefer `pnpm` when installing dependencies" [S5]; confirmation gates, "Ask for confirmation before adding new production dependencies" [S5]; personal workflow shortcuts and code-style defaults [S2]; environment facts you hold everywhere, such as OS or shell (inference). |
| **Project file** (team-shared, repo-specific)          | Build, test, lint commands; architecture that is not obvious from file names; conventions and gotchas. OpenCode's `/init` focuses on "build, lint, and test commands", "architecture and repo structure that are not obvious", and "operational gotchas" [S7]. Claude: "Keep it to facts Claude should hold in every session: build commands, conventions, project layout" [S2].                    |
| **Path-scoped rules** (`.claude/rules/` with `paths:`) | Instructions that only matter for some files, such as "API endpoints must include input validation" for `src/api/**/*.ts` [S2]. For user-level, `~/.claude/rules/` applies to every project [S2].                                                                                                                                                                                                   |
| **Skills** (load on demand)                            | Procedures and team knowledge: "a long release procedure sitting in a skill doesn't weigh on your unrelated bug fix the way it would in CLAUDE.md" [S3]. Claude sees only the name and description until it reads the full file [S3].                                                                                                                                                               |
| **Hooks / settings** (deterministic)                   | Anything with zero exceptions: "Never read .env", "Always run the formatter after editing" [S3]. Use a `PreToolUse` hook or a deny rule [S3].                                                                                                                                                                                                                                                       |

Global-specific test (inference from the above): a line belongs in the global file only if you would want it in a repo you have never seen. Example: chezmoi's rule "check whether chezmoi manages its target before editing another `AGENTS.md`" [S23] is project-specific to this repo, but a version of it is global if you routinely edit tool configs across repos.

Note on the interaction: a global line and a project line can conflict. Claude says "if a user rule and a project rule conflict, Claude may follow either one, so keep the two consistent" [S2]. Pi and Codex put project content later, so it wins by position [S5][S15] (inference that position decides precedence for the model).

---

## 4. What to leave out

- **No-ops and things the agent already does.** Claude: "Describe your architecture and file layout in CLAUDE.md" is on its "What you can stop doing" list, because "Claude reads the repo itself. Only write down what isn't in there." [S3]. Gloaguen et al. report that Claude Code's context-file generation prompt "advocates for a high-level overview only and warns against listing components that are easily discoverable" [S18].
- **Repository overviews.** Gloaguen et al. find that "repository overviews, although popular and recommended by model providers, are not helpful" [S18]. Developer-committed files with overviews did not speed agents toward relevant files [S18].
- **Generic process pep-talks.** Claude says lines like "Tell Claude to keep going, loop until done, don't be lazy" are "more likely to cause over-work than fix a stall" [S3]. Also "Always typecheck before you finish": it "works most of the time, not every time" [S3].
- **Things the harness already enforces or provides.** Use settings or hooks instead of prose for permissions and sandboxing [S2][S3].
- **Stale facts.** Claude's audit checks for "references to files or commands that don't exist" and "files that contradict each other" [S2]. Global files outlive projects, so they go stale faster than project files (inference).
- **Conflicts between files.** Claude: "if two instructions contradict each other, Claude may pick one arbitrarily" [S2].
- **Secrets and credentials.** Pi notes that its agent directory holds credentials, settings, and sessions, and that mounting it exposes them [S12]. Keep secrets out of any instruction file (inference: instruction files are sent to the model).
- **Maintainer notes that should not cost tokens.** Claude strips block-level HTML comments from CLAUDE.md before injection, but keeps comments inside code blocks [S2]. Use `<!-- ... -->` for private notes.
- **Long lists.** Claude's general guidance is that a longer file "consume[s] more context and reduce[s] adherence" [S2]. See §6 on instruction density.

---

## 5. Writing style guidance

**Length.** Claude: under 200 lines per file; "Files over 200 lines consume more context and may reduce adherence" [S2]. Codex: keep combined instructions under 32 KiB, or raise `project_doc_max_bytes` [S5]. For a global file, stay well below both (inference).

**Structure.** "group related instructions under markdown headers and bullets. Organized sections are easier for Claude to follow than dense paragraphs." [S2]. agents.md: "Use any headings you like" [S1].

**Concreteness.** Use verifiable statements: exact commands, exact names, exact thresholds [S2][S5].

**Positive framing.** "Tell Claude what to do instead of what not to do" [S4]. Negative rules still work when they are the point ("Never read .env"), but pair them with an action where possible, and use a hook if the rule has no exceptions [S3].

**Emphasis.** Avoid CRITICAL, MUST, NEVER, IMPORTANT, and ALL CAPS. Claude's guidance: "Current ones follow a plainly worded line" [S3]. Adding emphasis "mostly makes Claude over-apply the rule" [S3]. The fix for overtriggering is to soften the language: "Where you might have said 'CRITICAL: You MUST use this tool when...,' you can use more normal prompting such as 'Use this tool when...'" [S4]. Anthropic also says: "If you keep adding emphasis to a CLAUDE.md line and Claude still misses it, that's a sign the line belongs in a hook." [S3]

**Explain the why.** "Providing context or motivation behind your instructions... can give Claude more information about your goals" [S4]. Keep the reason to one clause.

**Position.** IFScale finds models "bias towards earlier instructions" [S20]. Put the most important global rules first (inference from that finding; the study is keyword-based, see §6).

**Density.** IFScale reports accuracy falling as instruction count rises: even the best models reach "68% accuracy at the max density of 500 instructions" [S20]. Fewer, higher-value rules beat a long checklist (inference).

**Tone.** Claude's prompting guide frames the model as "a brilliant but new employee who lacks context on your norms and workflows." Test: "Show your prompt to a colleague with minimal context on the task and ask them to follow it. If they'd be confused, Claude will be too." [S4]

**Modularity.** Use skills or path-scoped rules for long material. Claude's imports allow "a maximum depth of four hops", but imports "don't reduce [the] context cost, because imported files load together with the CLAUDE.md that imports them" [S2]. Skills and path-scoped rules are what reduce cost [S2][S3].

---

## 6. Empirical evidence

**A. Do context files help? (arXiv 2602.11988, Gloaguen, Mündler-Sasahara, Müller, Raychev, Vechev, Feb 2026, v3 Sep 2026) [S18]**

- Setting: CTXbench (138 instances from 12 repos with developer-committed AGENTS.md / CLAUDE.md, built from real GitHub issues) and SWE-bench tasks with LLM-generated context files. Agents: Claude Code + Sonnet-4.5; Codex + GPT-5.2 and GPT-5.1 mini; Qwen Code + Qwen3-30b-coder [S18].
- Headline: "providing context files does not generally improve task success rates, while increasing inference cost by over 20% on average" [S18].
- LLM-generated files: resolution change −0.5% (SWE-bench) and −2% (CTXbench), p = 87% and 37%, not significant; steps up 2.45 and 3.92; cost up 20% and 23% [S18].
- Developer-committed files: +2.4% on average (p = 21%, not significant); steps +3.34; cost up to 19% [S18]. Developer files beat LLM-generated ones by about 7% on average [S18].
- Mechanism: "instructions in the context files are well followed," which leads to "increased exploration, testing, and reasoning," and extra cost; overviews did not reduce steps to relevant files [S18].
- Recommendation: "Human-written context files should only include instructions required for coding agents that are not already present in the README (e.g., specific conventions or non-functional requirements)" [S18].
- Caveat: these are repository tasks, not personal global preferences. The study does not test global files.

**B. Context strategy ablation (arXiv 2607.27250, Khatri, submitted 28 Jul 2026) [S19]**

- Setting: 17 real tasks across 3 repos, 288 runs, Claude Code and Codex, three strategies: NONE, ALWAYS ON (full AGENTS.md in system prompt), SELECTIVE (topic files retrieved on demand) [S19].
- Finding: "Context strategy does not measurably move correctness on either agent (bounded to <=10-15pp via equivalence testing)." [S19]
- Failure triage: "agents fail on implementation skill... not missing repository knowledge that a context file could supply" [S19].
- Caveats: single author, small task set, independent researcher. Use as directional.

**C. Instruction density (arXiv 2507.11538, Jaroslawicz et al., Jul 2025) [S20]**

- IFScale: 500 keyword-inclusion instructions in a business-report task; 20 models across seven providers [S20].
- "even the best frontier models only achieve 68% accuracy at the max density of 500 instructions" [S20].
- Three degradation patterns: threshold decay (near-perfect until a critical density, e.g. gemini-2.5-pro and o3 "maintaining near-perfect performance through 150 or more instructions"), linear decay (gpt-4.1 and claude-3.7-sonnet in the text; claude-sonnet-4 in the figure legend), and exponential decay (gpt-4o, llama-4-scout) [S20].
- Primacy: error rates for later instructions rise, "peak around 150-200 instructions" [S20].
- Caveat: keyword inclusion is a proxy. The keywords are arbitrary; the paper does not test coding-agent behavior (inference from the task design). Models are 2025 generation.

**D. What real CLAUDE.md files contain (arXiv 2509.14744, Chatlatanagulchai et al., Sep 2025) [S21]**

- 253 CLAUDE.md files from 242 repos (filtered to repos with 20+ commits after adding the file) [S21].
- Structure: median one H1, five H2, nine H3 [S21].
- Content categories: Build & Run 77.1%, Implementation Details 71.9%, Architecture 64.8%, Testing 60.5% [S21]. This is descriptive: it shows what people write, not whether it helps.

**E. Cursor rules (arXiv 2512.18925, 2025) [S22]** (descriptive only): 401 repos; average 4.68 rule files per repo and 462.67 lines per file (SD 1,197) [S22]. Shows that real rule files are often long.

**F. Vendor claims vs. evidence.** Agent developers "strongly encourage" context files [S18][S19]. The evidence above does not support a blanket benefit. It supports the narrower claim in Gloaguen: "context files are useful for specifying non-standard coding practices" [S18]. For a global file, that points to the non-standard personal rules, not repo facts.

---

## 7. Open questions and conflicts between sources

1. **Vendor advice vs. measured effect.** Anthropic, OpenAI, and OpenCode all recommend writing repo overviews and commands into context files [S2][S5][S7]. Gloaguen and Khatri find overviews unhelpful and near-zero effect [S18][S19]. Resolution unknown; the studies are small and single-agent for some configs.
2. **Length limits differ by harness.** Claude targets under 200 lines [S2]; Codex's cap is 32 KiB [S5]; others document none [S7][S8][S9]. No source explains the basis for the 200-line figure.
3. **"Claude 4.x" guidance.** The Claude prompting page at the URL I fetched now covers Claude 5-series models and lists 4.x as model-specific notes [S4]. I did not find a separate 4.x-only page. The overtriggering guidance is attributed to Opus 4.5 and 4.6 [S4]; the emphasis guidance in Claude Code's docs is not tied to a model version [S3].
4. **Global `CLAUDE.md` vs `AGENTS.md` across harnesses.** Claude does not count `~/.claude/CLAUDE.md` when deciding whether to read `AGENTS.md` [S2]. OpenCode falls back to `~/.claude/CLAUDE.md` [S7]. Codex ignores `CLAUDE.md` by default [S5]. Pi ignores `~/.claude/` entirely (its agent dir is `~/.pi/agent`) [S11][S15]. No single file name is read by every harness at global scope.
5. **Codex project_doc section.** The Codex AGENTS.md guide links to `config-advanced#project-instructions-discovery` [S5], but the fetched config-advanced page did not contain a `project_doc_max_bytes` section (I could not confirm the anchor). The 32 KiB default is from the AGENTS.md guide [S5].
6. **Primacy vs. recency.** IFScale finds earlier instructions are better followed [S20]. Claude says user-level rules load first and project rules later, so project rules appear "later in Claude's context" [S2]. These do not directly conflict, but where to put a global rule is not settled by any source.
7. **IFScale generalization.** Keyword inclusion is not rule-following in coding. Its threshold numbers should not be applied to a global file without a local test (inference).
8. **Pi global path vs. local state.** Pi reads `~/.pi/agent/AGENTS.md` by default [S11], and chezmoi manages `dot_pi/agent/AGENTS.md` as an empty file [S23]. Deploying an empty file is harmless, but it would also replace any hand-written file that exists on the target. Verify before apply.
9. **Enforcement.** Claude says CLAUDE.md is advisory [S2][S3]. Pi says it loads "regardless of project trust" [S13]. Neither source says a global file can override harness permissions. Rely on settings for hard limits.

---

## 8. Sources

Local paths and URLs fetched or read during this research. Harness versions: pi 1.5.0 (installed package).

- **[S1]** agents.md spec, https://agents.md (fetched)
- **[S2]** Claude Code memory docs, "How Claude remembers your project", https://code.claude.com/docs/en/memory (fetched)
- **[S3]** Claude Code best practices, https://code.claude.com/docs/en/best-practices (fetched)
- **[S4]** Claude prompting best practices (the page at this URL covers Claude 5-series and 4.x notes), https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-4-best-practices (fetched)
- **[S5]** OpenAI Codex, "Custom instructions with AGENTS.md", https://developers.openai.com/codex/guides/agents-md (fetched). Related: https://developers.openai.com/codex/config-advanced (fetched; no `project_doc` section found)
- **[S7]** OpenCode, "Rules", https://opencode.ai/docs/rules/ (fetched)
- **[S8]** Gemini CLI, "Provide Context with GEMINI.md Files", https://google-gemini.github.io/gemini-cli/docs/cli/gemini-md.html (fetched)
- **[S9]** GitHub Docs, "Adding personal custom instructions for GitHub Copilot", https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-personal-instructions (fetched)
- **[S11]** pi docs, configuration, local: `/Users/ianpascoe/.local/share/mise/installs/npm-earendil-works-pi-coding-agent/1.5.0/node_modules/.mise/@earendil-works+pi-coding-agent@1.5.0_@aws-sdk+credential-provider-node@3.972.92_@smithy+signature-v4@5.7.5_ws@8.22.1/node_modules/@earendil-works/pi-coding-agent/docs/configuration.md`. Same package root for the rest of the pi paths below.
- **[S12]** pi docs, how-pi-works, `.../docs/how-pi-works.md`; and `.../docs/containerization.md` (for the credentials note)
- **[S13]** pi docs, security, `.../docs/security.md`
- **[S14]** pi docs, CLI flags, `.../docs/cli.md` (`-nc, --no-context-files`)
- **[S15]** pi source, context-file loader, `.../dist/core/resource-loader.js` (`loadContextFileFromDir`, `loadProjectContextFiles`)
- **[S16]** pi source, system prompt builder, `.../dist/core/system-prompt.js` (`renderProjectContext`)
- **[S18]** Gloaguen et al., "Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?", arXiv:2602.11988, https://arxiv.org/abs/2602.11988 and full text https://arxiv.org/html/2602.11988v3 (v3 submitted 29 Sep 2026)
- **[S19]** Khatri, "Do Context Files Help Coding Agents? A Two-Agent Ablation Study on Real Repositories", arXiv:2607.27250, https://arxiv.org/abs/2607.27250
- **[S20]** Jaroslawicz et al., "How Many Instructions Can LLMs Follow at Once?" (IFScale), arXiv:2507.11538, https://arxiv.org/abs/2507.11538 and full text https://arxiv.org/html/2507.11538
- **[S21]** Chatlatanagulchai et al., "On the Use of Agentic Coding Manifests: An Empirical Study of Claude Code", arXiv:2509.14744, https://arxiv.org/html/2509.14744
- **[S22]** "Beyond the Prompt: An Empirical Study of Cursor Rules", arXiv:2512.18925, https://arxiv.org/html/2512.18925v2
- **[S23]** chezmoi repo (local): `/Users/ianpascoe/.local/share/chezmoi/AGENTS.md` (repo rules, managed-copy warning, deploy approval); `/Users/ianpascoe/.local/share/chezmoi/dot_pi/agent/AGENTS.md` (0 bytes, untracked); `/Users/ianpascoe/.local/share/chezmoi/docs/research/` (empty before this file)

Not used, with reason: a Cursor blog post and an Arize blog on IFScale 2026 re-runs (not primary; not verified). Lost-in-the-middle (TACL 2024) was located but not read in full, so no claim relies on it.
