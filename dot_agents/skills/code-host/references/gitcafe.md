# GitCafe

- **Hosts:** `git.cafe`; self-hosted GitCafe is recognised by the remote matching `CAFE_HOST` (or `--host`). A GitHub-mirrored repo on GitCafe still uses `cafe`; GitHub's rules also apply and "Waiting on GitHub's conflict check" means pending.
- **Tool:** `cafe` 0.12.0, checked 2026-10-30
- **Exercised:** not yet
- **Sources:** https://git.cafe/docs/index.md, https://git.cafe/docs/reference/cli.md, https://git.cafe/docs/reference/api.md, https://git.cafe/docs/getting-started/cli.md, https://git.cafe/docs/pull-requests/merge.md, https://git.cafe/docs/repositories/repository-rulesets.md, https://git.cafe/docs/ci/actions.md, https://git.cafe/docs/ci/buildkite.md, https://git.cafe/docs/issues/issues.md, https://git.cafe/api/openapi/json
- **Placeholders:** `<n>` PR number, `<b>` PR branch, `<t>` target branch, `<sha>` reviewed head, `<ticket>` ticket number, `<owner>/<repo>` repo

Global flags: `--repo/-R <owner>/<repo>`, `--host`, `--json`, `--yes`, `--no-input`. Pass `--repo` outside a clone. With `--json`, results are in `.data`. Never use `cafe stack` commands: PRs are plain PRs with `--base`.

## Detect & auth

- Detect: remote host is `git.cafe`, or equals `CAFE_HOST`.
- Auth: `cafe auth status`. `AUTHENTICATION_REQUIRED` → ask the user to run `cafe auth login` (don't run it). `NETWORK_ERROR` is not "logged out".
- Headless: `CAFE_TOKEN` (a PAT from the "Agent / CLI" template) overrides the stored login. Push access alone doesn't allow `cafe pr create`.
- Push access: no permission query documented; learned from the first push.

## Who am I

`cafe auth status` (prints identity and host). REST: `cafe api /auth/principal`.

## Default branch

`cafe api "/repos/<owner>/<repo>"` → `defaultBranch`.

**Unverified**: check `cafe repo view <owner>/<repo> --json` before relying on it (field path likely `.data.resource.defaultBranch`).

## Find PRs

- Open PR for `<b>`: `cafe pr list --head <b> --state open --json`. Fields: `number`, `author`, `headOid` (head SHA), `targetBranch` (base), `sourceBranch`, `state`, `draft`, `version`.
- `--state` is `all|open|merged|closed|draft`; `--base <t>` filters by base.
- PRs that close `<ticket>`: **Unverified**: check `cafe pr list --help` for a search flag before first use. Fallback: list `--state all --json` and search PR bodies for a closing keyword plus `<ticket>`.

## Open PR

`cafe pr create --title "<title>" --body-file <file> --base <t> [--head <b>] --submission-key <key>`

- Push the branch first.
- `--json` gives `.data.number` and `.data.url`.
- `--submission-key` makes a retry idempotent. `--draft` opens a draft; leave it off.

## Edit PR body

`cafe pr edit <n> --body-file <file>`

**Unverified**: check `cafe pr edit --help` for the body flag before first use. Fallback: REST `PATCH /repos/<owner>/<repo>/pulls/<n>` via `cafe api`.

## Comment

`cafe pr comment <n> --body-file <file>`

A standalone comment, not part of a review and not an open thread. Use it for the review report.

## List comments

`cafe pr comments <n> --filter general --json`

- Items carry `createdAt`, `author`, `body`, `threadId`.
- Paginate with `--cursor`.
- Order is not stated in the docs; sort by `createdAt` client-side.

## Checks

- Wait on the PR: `cafe pr checks <n>` has no watch flag, so loop on its exit code: `0` pass, `8` pending, `1` failed.
- Blocking per run: `cafe ci status --pr <n>` to get run IDs, then `cafe ci watch <run-id> [--interval 5] [--timeout 120]` (timeout in minutes; exits nonzero unless the run succeeded).
- Checks on the default branch's head: `cafe ci status` for the branch. **Unverified**: check `cafe ci status --help` for a branch or commit flag before first use.
- CI config in the repo: `.github/workflows/` (GitHub Actions YAML). Actions are off by default per repo (`cafe ci enable`). Buildkite pipelines are defined in Buildkite, so they have no repo file; treat Buildkite as CI only if `cafe ci pipeline` or `cafe integration` shows it. "Has no CI" needs both checked.
- Failing job logs: `cafe ci jobs <run>`, then `cafe ci logs <run> [job] --tail 200` (or `--full`, `--output <file>`).
- Rerun: `cafe ci rerun <run-id>` (Actions runs). Buildkite builds: **Unsupported** → rerun from the Buildkite UI; hand that to the user.

## Review threads

Inline comments carry `id`, `threadId`, `resolvedAt` (null = unresolved), `resolvedBy`.

- List unresolved: `cafe pr comments <n> --filter inline --json`, then keep items with `resolvedAt` null. No `--unresolved` flag.
- Reply: `cafe pr comment <n> --reply-to <comment-id> --body "<text>"`. A resolved thread must be unresolved first (`cafe pr unresolve <n> <comment-id>`).
- Resolve: `cafe pr resolve <n> <comment-id>`.
- REST: `POST /api/repos/<owner>/<repo>/pulls/<n>/comments/<comment-id>/resolve` with `{expectedVersion}`; replies at `…/replies`.
- `cafe pr comment --path/--line` inline comments don't belong to a review.

## Blocking verdicts

`cafe pr reviews <n>`: each reviewer's latest review counts; the author's own doesn't. A latest "changes requested" blocks. `cafe pr status <n> --json` shows it as the `changes-requested` reason in `.merge.reasons`.

## Approvals & readiness

Compute readiness yourself. Do not trust `cafe pr ready <n>` (it prints "Mergeable", "Waiting on <checks>", "Blocked: …" or "Merged", but it may count a bypass). It is merge-readiness, not "mark ready for review" (that is `cafe pr undraft`).

1. Required approvals: the "Require pull request" rule in `cafe repo ruleset effective <t> --json`.
2. Current approvals: `cafe pr reviews <n>`.
3. Checks: `cafe pr checks <n>`.
4. All other rules: every rule in `cafe repo ruleset effective <t> --json` must be met by the PR, not only approvals and checks. Any unmet rule → hold.
5. Why blocked: `cafe pr status <n> --json` → `.merge`: `state` (`blocked|requires-native-check`), `permitted`, `strategies[]`, `conflicts` (`unknown|pending|none|conflicting`), `blockers[{code,message}]`, `reasons[]` (e.g. `draft`, `changes-requested`, `merge-permission-required`, `native-operation-pending`, `provider-merge-pending`, `head-unobserved`), `verdict`. `conflicts` of `unknown` or `pending` = wait. Treat `.merge.permitted: false` or any `blockers` as not ready.

## Bypass check

`cafe repo ruleset effective <t> --json`. The evaluated rules tell any reader whether they may bypass. Bypass actors with mode `always` or `pull_request` skip every rule on `cafe pr merge`, silently, and `pr merge` has no flag to refuse that. So every rule in that output must be met by the PR, not only approvals and checks; any unmet rule → hold.

**Unverified**: check the output of `cafe repo ruleset effective <t> --json` before first use; the field that signals "you may bypass" is not confirmed (the schema lists `bypassActors`, visible to admins). If it says you can bypass, check every rule in the effective set against the PR yourself (Approvals & readiness); the server won't.

## Merge methods & merge queue

- Allowed methods: `strategies[]` in `cafe pr status <n> --json` → `.merge`.
- Names: `squash` = `squash`; `merge commit` = `merge`; `rebase` = `rebase` or `fast-forward`.
- Merge queue: none documented in the sources. `.merge.waiting` values `provider-admission-required` and `provider-authority-required` and the reason `stack-land-required` appear in the API schema. **Unverified**: check `cafe pr merge --help` and the merge docs before first use.

## Merge

`cafe pr merge <n> --strategy squash`

- Always pass `--strategy` (`merge|squash|rebase|fast-forward`). Without it the first method the PR status allows is used.
- Head pin: implicit. The API body is `{requestId, expectedVersion, headOid, baseOid, strategy}`; the CLI stops with a CONFLICT if head or target changed.
- Merges are async. `pr merge` waits 30 s, then reports an operation ID. Don't blind-retry (`MERGE_IN_PROGRESS`); follow it: `cafe pr merge <n> --operation <id> --wait`.
- `pr merge` has no bypass or auto-merge flag; its only flags are `--strategy`, `--operation`, `--wait`.
- A bypass actor skips rules on this call (see Bypass check).

## Read back

`cafe pr merge <n> --operation <id>` → state:

| State       | Meaning                                                                                                                                                           |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `completed` | merged; `resultOid` is the merge commit                                                                                                                           |
| `accepted`  | still in progress; `waiting` of `provider-admission-required` or `provider-authority-required` means waiting on the provider                                      |
| `failed`    | read `reason`: `rejected`, `merge-precondition-changed`, `native-conflict`, `native-failure`, `native-cancelled`, `reconciliation-required`, `already-up-to-date` |

Also `cafe pr view <n>` → `state` is `merged`. No auto-merge exists, so there is nothing to cancel. A retry reuses the same `requestId`.

## Delete branch

**Unsupported** on `pr merge` → the repo setting "Automatically delete head branches" deletes it on merge. If the setting is off, delete it after merge via the API. **Unverified**: check https://git.cafe/api/openapi/json for the branch-delete endpoint before first use. Already gone counts as deleted.

## Retarget

`cafe pr edit <n> --base <t>`. REST: `PATCH /repos/<owner>/<repo>/pulls/<n>` with `targetBranch`. Doesn't apply to stack members.

## Closing tickets

- Keywords: `close(s/d)`, `fix(es/ed)`, `resolve(s/d)`, any case, in a commit or the PR description.
- Fires when the change reaches the default branch, not on merge into another branch.
- Same-repo issues only, and only if the pusher or merger has at least the triage role.

## Quirks

- Output is results only; use `--json` only when you need IDs or OIDs.
- 401 → relay the login request to the user; 403 → missing scope or role; retry only when `retryable: true`.
- Destructive commands need `--yes`, and only when the user asked.
- Attachment uploads need the `repo attachments/write` token scope.
