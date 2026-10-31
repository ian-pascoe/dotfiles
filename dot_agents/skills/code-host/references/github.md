# GitHub

- **Hosts:** `github.com`, `*.ghe.com`, and any GitHub Enterprise Server hostname (read from `git remote get-url origin`).
- **Tool:** `gh` 2.103.3, checked 2026-10-30
- **Exercised:** partly: Open PR, Comment, Checks, and Merge by `landing` since 0.2.0; the read-only commands checked against `gh` 2.103.3 on 2026-10-30
- **Sources:** https://cli.github.com/manual, https://docs.github.com/en/graphql/reference/pulls, https://docs.github.com/en/rest/repos/rules, https://docs.github.com/en/rest/branches/branch-protection, https://docs.github.com/en/rest/issues/comments, https://docs.github.com/en/rest/pulls/comments, https://docs.github.com/en/rest/pulls/pulls, https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue, https://github.com/cli/cli
- **Placeholders:** `<n>` PR number, `<b>` PR branch, `<t>` target branch, `<sha>` reviewed head, `<ticket>` ticket number, `<owner>/<repo>` repo

## Detect & auth

- Remote host: `git remote get-url origin`. Token env var: `GH_TOKEN` (github.com, `*.ghe.com`), `GH_ENTERPRISE_TOKEN` (Enterprise Server).
- `GH_HOST` picks the host when the repo doesn't say; `GH_REPO=[HOST/]<owner>/<repo>` overrides the repo.
- Auth: `gh auth status [--hostname <host>] [--active]`. Exit 1 means an auth problem.
- Push access: `gh repo view --json viewerPermission`; `ADMIN`, `MAINTAIN`, or `WRITE` can push.

## Who am I

`gh api user --jq .login`

## Default branch

`gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`

## Find PRs

- Open PR for `<b>`: `gh pr list --head <b> --state open --json number,author,baseRefName,headRefOid,url`. `--head` does not accept `<owner>:<branch>`.
- Avoid bare `gh pr view` to find the PR: it may return a merged or closed PR for the branch. **Unverified**: check `gh pr view --help` before first use.
- PRs that close `<ticket>`: `gh pr list --state open --search "<ticket> in:body" --json number,title,body,baseRefName,closingIssuesReferences`, then keep those whose `closingIssuesReferences` has `<ticket>`, or whose body has a closing keyword + `#<ticket>`.

## Open PR

`gh pr create --base <t> --head <b> --title "<title>" --body-file body.md`

## Edit PR body

`gh pr edit <n> --body-file body.md`

## Comment

`gh pr comment <n> --body-file c.md`. This is an issue-level comment, not a review thread. Also `--edit-last`, `--create-if-none`.

## List comments

`gh pr view <n> --json comments`. `comments` holds issue-level comments only; review summaries are in `reviews[].body`, a different list.

REST: `gh api repos/<owner>/<repo>/issues/<n>/comments`. Ordered oldest first, so the latest is last.

## Checks

- Wait on the PR: `gh pr checks <n> --watch [--fail-fast] [--required] [--interval 10]`. Exit 8 = pending, 1 = failure.
- Read state without waiting: `gh pr checks <n> --json name,bucket,link,workflow`. `bucket` is `pass`, `fail`, `pending`, `skipping`, or `cancel`.
- Checks on the default branch's head: `gh run list --commit <sha> --json databaseId,name,status,conclusion` (Actions only); every check: `gh api repos/<owner>/<repo>/commits/<sha>/check-runs`.
- CI config paths: `.github/workflows/`. Other CI may report only through checks.
- Failing logs: get the run ID from the check `link` (`gh pr checks <n> --json name,link,workflow,bucket`) or `gh run list --commit <sha>`; then `gh run view <run-id> --log-failed` (or `--log --job <id>`).
- Rerun failed: `gh run rerun <run-id> --failed` (failed jobs plus dependencies). One job: `gh run rerun <run-id> --job <databaseId>`. Get `databaseId` from `gh run view <run-id> --json jobs --jq '.jobs[]|{name,databaseId}'`; it is not the number in the browser URL.

## Review threads

GraphQL through `gh api graphql`: `gh pr` has no thread subcommand, and REST has no resolve.

- List (keep `isResolved == false`; paginate with `pageInfo` past 100):
  `gh api graphql -f query='query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){pullRequest(number:$n){reviewThreads(first:100){nodes{id isResolved isOutdated comments(first:20){nodes{databaseId author{login} body path line}}}}}}}' -f o=<owner> -f r=<repo> -F n=<n>`
- Reply: GraphQL `addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$id, body:$b})`. REST alternative: `POST /repos/<owner>/<repo>/pulls/<n>/comments/<comment_id>/replies`, where `<comment_id>` must be a top-level review comment; replies to replies are unsupported.
- Resolve: GraphQL `resolveReviewThread(input:{threadId:$id})`.

## Blocking verdicts

`gh pr view <n> --json reviewDecision,latestReviews`. `reviewDecision` is `APPROVED`, `CHANGES_REQUESTED`, or `REVIEW_REQUIRED`. `CHANGES_REQUESTED` blocks. `latestReviews` gives each reviewer's latest verdict.

## Approvals & readiness

- Required approvals: classic protection `gh api repos/<owner>/<repo>/branches/<t>/protection` → `required_pull_request_reviews.required_approving_review_count` (needs admin). Rulesets: the `pull_request` rule in `gh api repos/<owner>/<repo>/rules/branches/<t>`; read the rule's `parameters` and look for the approval count. **Unverified**: check the rules API page before first use (the parameter name).
- Current approvals: `latestReviews` with `state == APPROVED` from `gh pr view <n> --json latestReviews`.
- Mergeable now: `gh pr view <n> --json mergeStateStatus,mergeable,reviewDecision,latestReviews,statusCheckRollup,isDraft`.
- `mergeStateStatus`: `CLEAN`, `HAS_HOOKS`, `UNSTABLE` (non-passing non-required status), `BLOCKED`, `BEHIND`, `DIRTY`, `DRAFT`, `UNKNOWN`.
  - `CLEAN`, `HAS_HOOKS`, `UNSTABLE` are mergeable now. `UNSTABLE` still merges: only required checks gate.
  - `BLOCKED` gives no reason. Diagnose from `reviewDecision`, `gh pr checks <n> --required`, and the rules.
  - `BEHIND`, `DIRTY`, `DRAFT`, `UNKNOWN`: hold.

## Bypass check

- `gh api graphql` on `PullRequest.viewerCanMergeAsAdmin`: true means this identity can bypass branch protections and merge immediately.
- Rulesets: `gh api repos/<owner>/<repo>/rulesets/<id>` → `current_user_can_bypass` (`always`, `pull_requests_only`, `never`, `exempt`) and `bypass_actors[]`. List active rules for a branch with `gh api repos/<owner>/<repo>/rules/branches/<t>` (excludes `evaluate`/`disabled` rulesets).
- Classic protection: `gh api repos/<owner>/<repo>/branches/<t>/protection` → `enforce_admins.enabled` (needs admin).
- `gh pr merge` refuses `BLOCKED`/`BEHIND` unless `--admin`. Raw REST or GraphQL merges have no such guard.

## Merge methods & merge queue

- Allowed methods: `gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed`.
- Map: `--squash` = squash, `--merge` = merge commit, `--rebase` = rebase.
- Merge queue required: GraphQL `PullRequest.isMergeQueueEnabled` (also `isInMergeQueue`, `mergeQueueEntry`); none of these are in `gh pr view --json`. A `merge_queue` rule in `gh api repos/<owner>/<repo>/rules/branches/<t>` may also show it. **Unverified**: check `gh api --help` (or the rules API page) before first use.

## Merge

`gh pr merge <n> --squash --delete-branch --match-head-commit <sha>`

Other methods: `--merge`, `--rebase`. Subject and body: `-t`, `-b` or `-F`.

Never pass:

- `--admin`: bypasses unmet requirements, and with a merge queue skips the queue.
- `--auto`: merges later, once requirements are met.

With a required merge queue, a plain `gh pr merge` enqueues instead of merging: with no strategy needed, it enables auto-merge if required checks haven't passed, or adds the PR to the queue if they have. Read back; don't assume merged.

## Read back

`gh pr view <n> --json state,mergedAt,mergeCommit,autoMergeRequest`

- Merged: `state == MERGED`.
- Auto-merge on: `autoMergeRequest != null`.
- In a merge queue: GraphQL `isInMergeQueue` / `mergeQueueEntry` (not in `gh pr view --json`).
- Still open with `autoMergeRequest == null` and not in the queue: in progress or blocked; re-read.
- Cancel auto-merge: `gh pr merge <n> --disable-auto`.
- Leave the queue: GraphQL `dequeuePullRequest` (no `gh` subcommand found).

## Delete branch

Done by `--delete-branch` on merge. It also deletes the local branch. Already gone counts as deleted.

## Retarget

`gh pr edit <n> --base <t>`

## Closing tickets

- Keywords: `close`/`closes`/`closed`, `fix`/`fixes`/`fixed`, `resolve`/`resolves`/`resolved`. Forms: `Closes #<ticket>`, `Fixes <owner>/<repo>#<ticket>`. Works in the PR body or a commit message.
- Fires only when the PR targets the default branch. Otherwise ignored, with no link made.

## Quirks

- `gh pr checks` exits 1 when the PR has no checks at all. Right after a push checks may not be registered yet; tell "no checks reported" apart from "failed".
- `gh run watch` fails with fine-grained PATs (needs `checks:read`). Use `gh pr checks --watch`.
- Don't merge via REST `PUT /pulls/<n>/merge`: it doesn't support merge queues or stacked PRs. Use `gh pr merge`.
- Stacked PRs (`gh stack`): `gh stack merge` is all-or-nothing, can't bypass requirements, and queues when a merge queue is on, ignoring method flags. Its maturity: **Unverified**: check `gh stack --help` before first use.
