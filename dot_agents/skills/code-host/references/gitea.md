# Gitea

- **Hosts:** Gitea instances (gitea.com or self-hosted). `gitea.com` is known; other hostnames need the API probe (see Detect & auth). Forgejo and Codeberg are a different host: use `forgejo.md`.
- **Tool:** `gt` 0.2.0 on Gitea 28+; REST via curl with `GITEA_TOKEN` below 28, checked 2026-10-30
- **Exercised:** not yet
- **Sources:** https://gitea.com/gitea/cli, https://gitea.com/gitea/cli/src/branch/main/internal/app/, https://gitea.com/swagger.v1.json, https://docs.gitea.com/usage/access-control/protected-branches, https://docs.gitea.com/usage/automatically-linked-references
- **Placeholders:** `<n>` PR number, `<b>` PR branch, `<t>` target branch, `<sha>` reviewed head, `<ticket>` ticket number, `<owner>/<repo>` repo, `<host>` instance hostname

## Detect & auth

REST calls below send `-H "Authorization: token $GITEA_TOKEN"` and use base `https://<host>/api/v1`.

1. `curl -s -o /dev/null -w '%{http_code}' https://<host>/api/forgejo/v1/version`. `200` = Forgejo, not this host. `404` = Gitea, continue.
2. `curl -s https://<host>/api/v1/version` → `{"version":"29.0.0+dev-…"}`. Major = integer before the first `.`. Major 28 or higher: use `gt`. Lower (older Gitea reports `1.x`): use REST for every operation. **Unverified**: check the version string on a release build before first use (the research probed only a dev build). Do the Forgejo test first: Forgejo's own major (16, 17) would pass a naive `>= 28` test.
3. Auth status: `gt auth status --verify`; REST (below 28): `GET /user` (200 = ok). Log in: `gt auth login --host https://<host> --with-token < tokfile`. Global flags: `--host`, `--user`, `-R/--repo`, `--remote`. With several logins configured, pass `--host` so the wrong login isn't picked from the remote.
4. REST token: `GITEA_TOKEN`.
5. Push access: learned from the first push.

Run `gt <cmd> --help` once before relying on any flag below.

## Who am I

`gt api user` → `.login` (or `gt auth status`). REST (below 28): `GET /user` → `.login`.

## Default branch

`gt api /repos/{owner}/{repo}` → `.default_branch` (`gt api` expands `{owner}`/`{repo}`). REST (below 28): `GET /repos/<owner>/<repo>` → `.default_branch`.

## Find PRs

- Open PR for `<b>`: `gt pr view <b> --json` (reads `head_sha` and the PR's base and author fields; check the JSON keys). With no argument it selects the current branch's PR.
- REST (below 28): `GET /repos/<owner>/<repo>/pulls?state=open`, then filter client-side on `.head.ref`; read `.number`, `.user.login`, `.head.sha`, `.base.ref`.
- `gt pr list` filter flags: **Unverified**: check `gt pr list --help` (or the API page) before first use.
- PRs that close `<ticket>`: list open PRs (`gt pr list --json` or the REST call above) and search their bodies for a closing keyword plus `#<ticket>`.

## Open PR

`gt pr create --base <t> --head <b> --title "<title>" --body-file body.md`

REST (below 28): `POST /repos/<owner>/<repo>/pulls` with JSON `{"base":"<t>","head":"<b>","title":"…","body":"…"}`. Build the JSON from the file: `jq -n --rawfile body body.md '{base:"<t>",head:"<b>",title:"…",body:$body}' | curl -X POST -d @- …`.

## Edit PR body

`gt pr edit <n> --body-file body.md`: **Unverified**: check `gt pr edit --help` before first use.

REST (below 28): `PATCH /repos/<owner>/<repo>/pulls/<n>` with `{"body":"…"}`.

## Comment

Top-level comment (a PR is an issue; this is not a review thread):

`gt pr comment <n> --body-file c.md` (`--edit-last` edits your last one).

REST (below 28): `POST /repos/<owner>/<repo>/issues/<n>/comments` with `{"body":"…"}`.

## List comments

`gt pr view <n> --comments` (comments and reviews).

REST (below 28): `GET /repos/<owner>/<repo>/issues/<n>/comments`. Order: **Unverified**: check the API page (assume nothing; sort by `created_at`).

## Checks

- Wait on the PR: `gt pr checks <n> --watch [--interval 5s] [--timeout 1h]`. Waits until every check finishes or one fails; tolerates an outage of up to 5 minutes. Exit `0` = pass, `8` = pending, `1` = failed.
- Poll without watching: `gt pr checks <n>`, same exit codes.
- REST (below 28): poll `GET /repos/<owner>/<repo>/commits/<sha>/status` and read `.state`: `success` is pass, `failure` or `error` is fail, `pending` means wait. **Unverified**: check the API page for the exact state values before first use.
- On a commit (default branch head): `gt run list --commit <sha>`. REST (below 28): `GET /repos/<owner>/<repo>/commits/<sha>/status`.
- CI config paths: **Unverified**: check the Gitea Actions docs for the workflow directories before concluding "has no CI".
- Failing job logs: `gt run logs <run-id> --failed [--tail N]`. Follow a run: `gt run watch <run-id>`. REST (below 28): `GET /repos/<owner>/<repo>/actions/runs/<run>/jobs`, then `GET /repos/<owner>/<repo>/actions/jobs/<job_id>/logs`. **Unverified**: check the API page before first use.
- Rerun failed: `gt run rerun <run-id> --failed` (or `--job <name|id>`). REST (below 28): `POST /repos/<owner>/<repo>/actions/runs/<run>/rerun-failed-jobs` (also `…/runs/<run>/rerun`, `…/jobs/<job_id>/rerun`).

## Review threads

- List: `gt pr review comments <n>` (has a `Resolved` column; `--json` to filter unresolved; `--review <id>`). REST (below 28): `GET /repos/<owner>/<repo>/pulls/<n>/reviews` for review ids, then `GET /repos/<owner>/<repo>/pulls/<n>/reviews/<id>/comments` for each; a comment with a non-empty `.resolver` is resolved. **Unverified**: check the API page before first use (the research read this on Forgejo).
- Reply: `gt pr review reply <n> <comment-id> -b "…"`. REST (below 28): `POST /repos/<owner>/<repo>/pulls/<n>/comments/<id>/replies`. **Unverified**: check the API page before first use; if missing, **Unsupported** → a top-level comment linking the thread.
- Resolve: `gt pr review resolve <n> <comment-id>` (`unresolve` reverses). REST (below 28): `POST /repos/<owner>/<repo>/pulls/comments/<id>/resolve`. **Unverified**: check the API page before first use; if missing, **Unsupported** → reply and leave it open; the thread counts as cleared once this identity's reply is newer than the thread's last comment by anyone else.

## Blocking verdicts

`gt pr view <n> --json` → `review_decision`: `approved` | `changes_requested` | `review_required`. `changes_requested` blocks.

REST (below 28): `GET /repos/<owner>/<repo>/pulls/<n>/reviews`; `state` is `APPROVED`, `PENDING`, `COMMENT`, `REQUEST_CHANGES` or `REQUEST_REVIEW`. Ignore entries with `stale` or `dismissed` true; `official` marks reviews that count.

## Approvals & readiness

- Required approvals: `GET /repos/<owner>/<repo>/branch_protections/<t>` → `required_approvals` (also `enable_status_check`, `status_check_contexts`, `block_on_rejected_reviews`). May need admin. On 403 or 404, **Unverified**: check the API page before first use, and treat the count as unknown.
- Current approvals: count `APPROVED` reviews (not stale, not dismissed) from the reviews REST call, or read `review_decision`.
- Mergeable now: `gt pr view <n> --json` → `mergeable`, `merged`, `draft`, `review_decision`, `head_sha`. `mergeable` only reflects merge state (conflicts), **not** CI or approvals. Also require `gt pr checks <n>` exit `0` and `review_decision` of `approved` (or the required count met).
- REST (below 28): `GET /repos/<owner>/<repo>/pulls/<n>` → `.mergeable`, `.merged`; `GET /repos/<owner>/<repo>/commits/<sha>/status` for CI; reviews as above for approvals. Ready = `.mergeable` true, status `success`, approvals met.

## Bypass check

The only way to skip protections is `force_merge: true` on the merge API call. `gt` never sends it, so an admin token is still gated through `gt`.

- Instance admin always skips when `force_merge` is sent. Repo admin skips unless the rule has `apply_to_admins` (default `false`; the setting "Administrators must follow branch protection rules"). Read it: `GET /repos/<owner>/<repo>/branch_protections/<t>` (see Approvals & readiness for access caveat).
- Whether this identity is an admin: **Unverified**: check `gt api user` output (REST below 28: `GET /user`) or the API page before first use.
- Gitea's dev API also has `enable_bypass_allowlist` with `bypass_allowlist_usernames/teams`; **Unverified**: check the API page before first use (the semantics).

## Merge methods & merge queue

- Allowed methods: **Unverified**: check `GET /repos/<owner>/<repo>` (or the API page) before first use for the repo's allowed merge styles.
- `gt` flags: `--squash`, `--merge`, `--rebase` (or `--method <m>`). REST `Do` values: `squash`, `merge`, `rebase`, `rebase-merge`, `fast-forward-only`, `manually-merged`.

| Landing method | Gitea `Do`                                      |
| -------------- | ----------------------------------------------- |
| squash         | `squash`                                        |
| merge commit   | `merge`                                         |
| rebase         | `rebase` (also `fast-forward-only`)             |
| (never)        | `manually-merged` (marks merged, no real merge) |

- Merge queue: **Unsupported** → none found in the sources; nothing to detect.

## Merge

`gt pr merge <n> --squash --delete-branch`: the head SHA is pinned implicitly (`gt` sends `HeadSHA`). Always pass a method; without one `gt` uses the repo default or prompts on a TTY.

REST: `POST /repos/<owner>/<repo>/pulls/<n>/merge` with `{"Do":"squash","head_commit_id":"<sha>","delete_branch_after_merge":true}` (the field is `Do`, capital D).

Never pass:

- `gt pr merge --auto` / REST `merge_when_checks_succeed`: schedules a merge for later. Default off.
- REST `force_merge`: the admin override. `gt` never sends it.
- `--method manually-merged` / `Do: manually-merged`: marks the PR merged by a commit without merging or checking it.
- Omitting the method: falls back to the repo default (may be a merge commit).

## Read back

- Merge call status: `200` = merged. `201` = auto-merge scheduled, not merged.
- `GET /repos/<owner>/<repo>/pulls/<n>/merge`: `204` = merged, `404` = not merged.
- `gt pr view <n> --json` → `merged`, `merge_commit_sha`. REST (below 28): `GET /repos/<owner>/<repo>/pulls/<n>` → `.merged`, `.merge_commit_sha`.
- Auto-merge on: **Unsupported** → only the `201` on the merge call says so.
- Cancel a scheduled auto-merge: `gt api -X DELETE /repos/{owner}/{repo}/pulls/<n>/merge` (no `gt pr` flag). REST: `DELETE /repos/<owner>/<repo>/pulls/<n>/merge`.
- Required merge queue: **Unsupported** → none; nothing to read.

## Delete branch

With the merge: `--delete-branch` / `delete_branch_after_merge: true`. Afterwards: `DELETE /repos/<owner>/<repo>/branches/<b>` (`gt api -X DELETE …`). Already gone counts as deleted.

## Retarget

`gt pr edit <n> --base <t>`. REST: `PATCH /repos/<owner>/<repo>/pulls/<n>` with `{"base":"<t>"}`.

## Closing tickets

Keywords: `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved` (admins can customise). Write `Closes #<ticket>` in the PR description. The issue closes only if the **merger** has permission to close it. (`reopen`, `reopens`, `reopened` reopen.)

Whether keywords fire only when the PR targets the default branch: **Unverified**: check the linked-references docs; don't rely on closing when `<t>` isn't the default branch.

## Quirks

- `tea`, the legacy CLI, is being archived; `gt` and REST replace it.
