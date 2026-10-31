# Forgejo

- **Hosts:** Forgejo instances, including `codeberg.org` and `code.forgejo.org`. Self-hosted: recognised only by the version probe in Detect & auth, not by hostname.
- **Tool:** REST via curl (`FORGEJO_TOKEN`), checked 2026-10-30
- **Exercised:** not yet
- **Sources:** https://codeberg.org/swagger.v1.json, https://codeberg.org/forgejo/forgejo/raw/branch/forgejo/services/pull/check.go, https://codeberg.org/forgejo/forgejo (`routers/api/v1/repo/pull.go`, `models/git/protected_branch.go`), https://forgejo.org/docs/v9.0/user/versions, https://forgejo.org/docs/latest/user/actions/, https://forgejo.org/docs/latest/user/linked-references/
- **Placeholders:** `<n>` PR number, `<b>` PR branch, `<t>` target branch, `<sha>` reviewed head, `<ticket>` ticket number, `<owner>/<repo>` repo, `<host>` instance hostname

Every call below is `curl -sS -H "Authorization: token $FORGEJO_TOKEN" -H "Content-Type: application/json" "https://<host>/api/v1/<path>"`; shown as `API <path>`, with `-X <verb>` and `-d` added where stated. **Unverified**: check the token header form on the API page before first use.

## Detect & auth

- Forgejo, not Gitea: `curl -sS -o /dev/null -w '%{http_code}' https://<host>/api/forgejo/v1/version` returns `200`. A `404` means Gitea; use the `gitea` reference. Both endpoints return `{"version":"X.Y.Z+gitea-A.B.C"}` on Forgejo.
- Token: `FORGEJO_TOKEN`. If unset, stop and ask.
- Auth check: `API user` returns 200 with the login; 401 means a bad token.
- Push access: `API repos/<owner>/<repo>` and read `.permissions.push`. **Unverified**: check the API page before first use. Otherwise learned from the first push.

## Who am I

`API user` → `.login`.

## Default branch

`API repos/<owner>/<repo>` → `.default_branch`. **Unverified**: check the API page before first use.

## Find PRs

- Open PR for `<b>`: `API 'repos/<owner>/<repo>/pulls?state=open'`, then pick the entry whose `.head.ref` is `<b>`; read `.number`, `.user.login`, `.head.sha`, `.base.ref`. **Unverified**: check the API page before first use (query parameters, pagination).
- PRs that close `<ticket>`: no search by closing reference. List open PRs as above and search each `.body` for a closing keyword plus `#<ticket>` (keywords under Closing tickets).

## Open PR

`API repos/<owner>/<repo>/pulls -X POST -d @pr.json` where `pr.json` is `{"title": "...", "head": "<b>", "base": "<t>", "body": "..."}`. Build `pr.json` from the body file with `jq -n --rawfile body body.md --arg title "..." --arg head <b> --arg base <t> '{title:$title,head:$head,base:$base,body:$body}' > pr.json`. The response `.number` is `<n>`. **Unverified**: check the API page before first use.

## Edit PR body

`jq -n --rawfile body body.md '{body:$body}' | API repos/<owner>/<repo>/pulls/<n> -X PATCH -d @-`. `PATCH` takes `EditPullRequestOption`, which has `base` (confirmed) and is expected to have `body`. **Unverified**: check the API page before first use.

## Comment

`jq -n --rawfile body c.md '{body:$body}' | API repos/<owner>/<repo>/issues/<n>/comments -X POST -d @-` (a PR is an issue). This is a top-level comment, not a review thread, so it is never an open thread.

## List comments

`API repos/<owner>/<repo>/issues/<n>/comments` → each entry's `.user.login`, `.body`, `.created_at`. Order: **Unverified**: check the API page before first use; sort by `.created_at` yourself.

## Checks

- Wait on the PR's checks: **Unsupported** as a watch command → poll `API repos/<owner>/<repo>/commits/<sha>/status` and read `.state`. Pending states mean wait; `success` is pass; `failure` or `error` is fail. **Unverified**: check the API page for the exact state values before first use.
- Checks on a commit (default branch head): `API repos/<owner>/<repo>/commits/<sha>/status`.
- CI config paths: **Unverified**: check the Forgejo Actions docs (https://forgejo.org/docs/latest/user/actions/) before first use. Check `.forgejo/workflows` and `.github/workflows`.
- Failing job logs: `API repos/<owner>/<repo>/actions/runs/<run_id>/jobs` to find the job, then `API repos/<owner>/<repo>/actions/jobs/<job_id>/logs`.
- Rerun failed: **Unsupported** → no rerun endpoint exists (the swagger has only `cancel`, `logs`, `jobs`, `runs`, `tasks`). A new run (a new commit, or `workflow_dispatch` for workflows that allow it) may not report to the PR's check. Treat a flake as a real failure.

## Review threads

- List unresolved: `API repos/<owner>/<repo>/pulls/<n>/reviews` for review ids, then `API repos/<owner>/<repo>/pulls/<n>/reviews/<id>/comments` for each. A comment with a non-empty `.resolver` is resolved. **Unverified**: check the API page for how comments group into threads before first use.
- Reply: **Unsupported** → post a top-level comment (see Comment) that links the thread's comment (`.html_url`).
- Resolve: **Unsupported** → same linking comment. A thread counts as cleared once this identity's linking comment is newer than the thread's last comment by anyone else.

## Blocking verdicts

`API repos/<owner>/<repo>/pulls/<n>/reviews`: each entry has `.state` (`APPROVED`, `PENDING`, `COMMENT`, `REQUEST_CHANGES`, `REQUEST_REVIEW`), `.user.login`, `.official`, `.stale`, `.dismissed`. A `REQUEST_CHANGES` entry that is not `.dismissed` blocks. Take each reviewer's latest entry.

## Approvals & readiness

- Required approvals: `API repos/<owner>/<repo>/branch_protections/<t>` → `.required_approvals`. Also read `.enable_status_check`, `.status_check_contexts`, `.block_on_rejected_reviews`, `.enable_merge_whitelist`, `.apply_to_admins`. This may need admin rights; on 403 or 404, **Unverified**: check the API page, and treat the rule as unknown.
- Current approvals: count `.state == "APPROVED"` entries in `API repos/<owner>/<repo>/pulls/<n>/reviews` where `.official` is true, `.stale` and `.dismissed` are false, one per reviewer.
- Mergeable now: `API repos/<owner>/<repo>/pulls/<n>` → `.mergeable`. It reflects merge state (conflicts) only, not CI or approvals. Combine it with the commit status (Checks) and the approval count above.

## Bypass check

The only way to skip protections is `force_merge: true` on the merge call. Admins are gated unless `force_merge` is sent: an instance admin always skips with it, and a repo admin skips unless the rule has `apply_to_admins`. Read `.apply_to_admins` from `API repos/<owner>/<repo>/branch_protections/<t>` to see whether this identity's admin rights could matter. No other bypass read exists in the sources.

## Merge methods & merge queue

- Methods (`Do` values): `merge` = merge commit; `squash` = squash; `rebase` and `rebase-merge` = rebase; `fast-forward-only` = rebase. `manually-merged` marks the PR merged without merging.
- Which are allowed: **Unverified**: check `API repos/<owner>/<repo>` for `allow_merge_commits`, `allow_squash_merge`, `allow_rebase`, `allow_rebase_explicit`, `allow_fast_forward_only_merge` (API page) before first use.
- Merge queue: **Unsupported** → none in the sources. `merge_when_checks_succeed` schedules a later merge; it is not a queue.

## Merge

`jq -n --arg sha <sha> '{Do:"squash",head_commit_id:$sha,delete_branch_after_merge:true}' | API repos/<owner>/<repo>/pulls/<n>/merge -X POST -d @-`

- `Do` is capitalised in the swagger. Always set it. Methods: see Merge methods & merge queue.
- `head_commit_id` is honoured server-side as the head pin.
- Omitting `Do` is not an option; the default is the repo's main merge style.

Never pass:

- `force_merge`: skips branch protections.
- `merge_when_checks_succeed`: schedules a merge for later (auto-merge).
- `Do: "manually-merged"`: marks the PR merged without merging.

## Read back

- Merge response: `200` = merged; `201` = auto-merge scheduled (not merged yet).
- `API repos/<owner>/<repo>/pulls/<n>/merge` with `-w '%{http_code}'`: `204` = merged, `404` = not merged.
- `API repos/<owner>/<repo>/pulls/<n>` → `.merged`, `.merge_commit_sha`.
- Scheduled auto-merge: **Unsupported** → only the `201` on the POST says so. Queue state: **Unsupported** → none exists.
- Cancel a scheduled auto-merge: `API repos/<owner>/<repo>/pulls/<n>/merge -X DELETE`.

## Delete branch

Done by the merge call (`delete_branch_after_merge: true`). Afterwards: `API repos/<owner>/<repo>/branches/<b> -X DELETE`; a 404 means already gone, which counts as deleted. Branch names with `/` need URL-encoding in the path.

## Retarget

`jq -n --arg base <t> '{base:$base}' | API repos/<owner>/<repo>/pulls/<n> -X PATCH -d @-`

## Closing tickets

- Keywords: `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved`, followed by `#<ticket>`. Reopening keywords (`reopen`, `reopens`, `reopened`) exist. Admins can customise the list.
- In a PR description, the ticket closes only if the person who merges has permission to close it.
- Whether it fires only for PRs targeting the default branch: **Unverified**: check https://forgejo.org/docs/latest/user/linked-references/ before first use. Do not rely on it for non-default targets.

## Quirks

- Codeberg's swagger reports `16.0.0-dev+gitea-1.22.0`: the `+gitea-` suffix is Forgejo's compatible Gitea version, not a Gitea release.
