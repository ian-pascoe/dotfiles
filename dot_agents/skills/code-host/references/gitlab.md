# GitLab

- **Hosts:** gitlab.com and self-managed GitLab at any hostname (repo paths can be `group/sub/project`). `glab` resolves the instance from `git remote`, `GITLAB_HOST`, or its config. GitLab calls a PR a merge request (MR); `<n>` is its iid.
- **Tool:** `glab` (docs for GitLab 19.x; latest release seen v1.126.0), falling back to `glab api`; checked 2026-10-30
- **Exercised:** not yet
- **Sources:** https://docs.gitlab.com/cli/, https://gitlab.com/gitlab-org/cli, https://docs.gitlab.com/api/merge_requests/, https://docs.gitlab.com/api/projects/, https://docs.gitlab.com/api/discussions/, https://docs.gitlab.com/api/notes/, https://docs.gitlab.com/api/merge_request_approvals/, https://docs.gitlab.com/ci/pipelines/merge_trains/, https://docs.gitlab.com/user/project/issues/managing_issues/
- **Placeholders:** `<n>` PR number, `<b>` PR branch, `<t>` target branch, `<sha>` reviewed head, `<ticket>` ticket number, `<owner>/<repo>` repo

`glab api` accepts `:id` (current project) and `:fullpath` placeholders.

## Detect & auth

- Any remote hostname can be GitLab: confirm with `glab auth status --hostname <host>` (`--all`, `-F json`). Not logged in → stop.
- Push access: no confirmed permission query; learned from the first push.

## Who am I

`glab api user --jq .username`

## Default branch

`glab api projects/:id --jq .default_branch`

## Find PRs

- Open PR for `<b>`: `glab mr list --source-branch <b> -F json` (open by default). Number = `.iid`, author = `.author.username`, head SHA = `.sha`, base = `.target_branch`.
- `glab mr view <b> -F json` also takes a branch.
- PRs that close `<ticket>`: **Unverified**: check `glab mr list --help` (or the API page) before first use. Fallback: `glab mr list --all -F json` and search each `.description` for a closing keyword + `<ticket>`.

## Open PR

Push first: `git push -u origin <b>` (`--push` defaults true only with `--fill`).

`glab mr create --source-branch <b> --target-branch <t> --title "T" --description-file body.md --remove-source-branch --squash-before-merge --yes`

## Edit PR body

`glab mr update <n> --description "$(cat body.md)"`. **Unverified**: check `glab mr update --help` (a `--description-file` flag was not confirmed) before first use.

## Comment

Not counted as an open thread: `glab mr note create <n> -m "text" --resolvable=false`, or `glab mr note create <n> --resolvable=false < c.md`.

Without `--resolvable=false` the note is a resolvable thread and blocks merge under "All threads must be resolved".

`mr note` commands are experimental. If missing or the flags differ, use `glab api -X POST projects/:id/merge_requests/<n>/notes -f body="text"`. **Unverified**: check the notes API page (https://docs.gitlab.com/api/notes/) for how to make it non-resolvable.

## List comments

`glab mr note list <n> --type general -F json` (`--type all|general|diff|system`; experimental).

Fallback: `glab api projects/:id/merge_requests/<n>/notes`. REST default is `sort=desc`, newest first. Add `-f order_by=created_at -f sort=asc` for oldest first. Fields: `.author.username`, `.body`, `.created_at`.

## Checks

- Wait: `glab ci status --wait` (blocks, no prompt; incompatible with JSON output). It follows the branch, not the PR's head pipeline. Exit code on failure: **Unverified**: check `glab ci status --help` before first use.
- PR's head pipeline: `glab ci get --merge-request <n> -F json`, then poll `.status`. Use this for PR, detached, or fork pipelines.
- Default branch head: `glab ci get --branch <t> -F json`.
- CI config in the repo: `.gitlab-ci.yml`. **Unverified**: check the GitLab CI docs (or the API page) before first use.
- Failing jobs: `glab ci get --merge-request <n> --status failed --with-job-details`. Logs: `glab ci trace <job-id|job-name> [-p <pipeline-id>]`.
- Rerun failed: one job `glab ci retry <job-id|name> [-p <pipeline-id>]`. Whole pipeline's failed jobs: `glab api -X POST projects/:id/pipelines/<pipeline-id>/retry` (verify path on https://docs.gitlab.com/api/pipelines/).

## Review threads

- List unresolved: `glab mr note list <n> --state unresolved -F json` (discussion `id` is the full ID; the text view shows an 8-char prefix), or `glab mr view <n> --unresolved`. Experimental.
- Reply: `glab mr note create <n> --reply <discussion-id|8+char-prefix> -m "text"`.
- Resolve: `glab mr note resolve <n> <discussion-id|note-id>` (experimental).
- REST fallback: list `glab api projects/:id/merge_requests/<n>/discussions`; resolve `glab api -X PUT projects/:id/merge_requests/<n>/discussions/<discussion-id> -f resolved=true` (needs Developer+ or the PR author). https://docs.gitlab.com/api/discussions/

## Blocking verdicts

`glab mr view <n> -F json | jq .detailed_merge_status`: `requested_changes` means a reviewer's changes-requested verdict is blocking. Per-reviewer verdicts: **Unverified**: check `glab mr approvers --help` (or the approvals API page) before first use.

## Approvals & readiness

- Required approvals and current approvals: `glab api projects/:id/merge_requests/<n>/approval_state` (rules, and whether received approvals satisfy them). CE returns only `approved`, `approved_by`, `user_can_approve`, `user_has_approved`. Per-field names beyond those: **Unverified**: check the API page before first use.
- Mergeable now: `glab mr view <n> -F json | jq .detailed_merge_status`. `mergeable` = ok; `ci_still_running` = checks pending; anything else blocks. Values: `not_approved`, `ci_must_pass`, `ci_still_running`, `discussions_not_resolved`, `draft_status`, `conflict`, `need_rebase`, `requested_changes`, `status_checks_must_pass`, `merge_request_blocked`, `security_policy_violations`, `merge_time`, `checking`, `unchecked`, `preparing` (the last three = wait and re-read), `not_open`, `approvals_syncing`, `commits_status`, `jira_association_missing`, `locked_paths`, `locked_lfs_files`, `title_regex`, `security_policy_pipeline_check`.
- Project gates: `glab api projects/:id --jq '{p:.only_allow_merge_if_pipeline_succeeds,d:.only_allow_merge_if_all_discussions_are_resolved,s:.allow_merge_on_skipped_pipeline}'`.

## Bypass check

- The merge API has no skip or bypass parameter; it runs the UI's mergeability checks. Who may merge is the protected branch's "Allowed to merge" list; `glab mr merge` pre-checks `mr.user.can_merge`.
- Two weak spots to read:
  - `merge_train_enforcement` in `glab api projects/:id` (`allow_bypass`, `enforce_for_all_users`, `enforce_with_owner_override`; 19.3+). With trains on, skipping the train is the bypass, so the train is required under every value (see Merge methods & merge queue).
  - If approval-rule overrides are allowed, PR-level approval rules can be edited: re-read the PR's rules just before merging.
- Instance admins skipping checks via this API: **Unverified**: check the API page before first use.

## Merge methods & merge queue

- Methods: `--squash` = `squash`; default (no flag) = `merge commit`; `--rebase` = `rebase` (rebases first; mutually exclusive with `--squash` and with `--sha`).
- The project's merge method (merge commit, semi-linear, fast-forward) may constrain these. **Unverified**: check the Projects API page (and how it interacts with `--squash`/`--rebase`) before first use.
- Merge train: `glab api projects/:id --jq '{t:.merge_trains_enabled,e:.merge_train_enforcement,p:.only_allow_merge_if_pipeline_succeeds}'`. Trains on = `t` true. Whenever trains are on, the train counts as required, whatever `e` is: `allow_bypass`, `enforce_for_all_users`, `enforce_with_owner_override`, or absent (before 19.3). Skipping the train is the bypass. So with trains on, always `--auto-merge` after review and checks pass.

## Merge

Only after `detailed_merge_status == mergeable`.

- Trains off: `glab mr merge <n> --squash --remove-source-branch --auto-merge=false --sha <sha> --yes`
- Trains on: `glab mr merge <n> --squash --remove-source-branch --auto-merge --sha <sha> --yes` (joins the train, or merges when checks pass; the PR merges later, not at call time).
- Self-managed below 19.1 with merge trains on: an `auto_merge` request may skip the train. **Unverified (merge path)**: hold before merging and escalate.
- Change `--squash` for `--rebase` (drop `--sha`) or nothing (merge commit) as the method requires.

`--auto-merge` defaults to **true**: with a running pipeline, a bare `glab mr merge` queues "merge when pipeline succeeds". Trains off → always pass `--auto-merge=false`. In a TTY with neither flag, glab prompts "Set auto-merge?"; always pass `--yes` and an explicit `--auto-merge` form.

Never pass:

- `--auto-merge=false` on a trains-on project: rejected (405) under `enforce_for_all_users` and `enforce_with_owner_override`; otherwise it merges immediately, skips the train, and cancels other train pipelines.
- `--when-pipeline-succeeds` (deprecated alias): also defaults true.
- API `skip_merge_train`: bypasses the train.

## Read back

`glab mr view <n> -F json | jq '{state,merged_at,merge_commit_sha,merge_when_pipeline_succeeds,detailed_merge_status}'`

- Merged: `state == merged`.
- Queued or auto-merge on: `merge_when_pipeline_succeeds == true` (`state` still `opened`). glab prints "Auto-merge enabled" vs "Merged!".
- Still in progress: `state == opened`, no auto-merge; read `detailed_merge_status`.
- Cancel auto-merge (also removes the PR from a train): `glab api -X POST projects/:id/merge_requests/<n>/cancel_auto_merge` (GitLab 19.5+). Older: `cancel_merge_when_pipeline_succeeds` (deprecated; returns a status hash, check `status`; HTTP 201 either way). No glab subcommand.

## Delete branch

With the merge: `--remove-source-branch`. Already gone counts as deleted.

## Retarget

`glab mr update <n> --target-branch <t>`

## Closing tickets

- Keywords (any case): `Close/Closes/Closed/Closing`, `Fix…`, `Resolve…`, `Implement…`. Refs: `#123`, `group/project#123`, or a full URL. Self-managed admins can change the pattern.
- Fires when the commit is pushed to, or the PR is merged into, the **default branch** only.

## Quirks

- **"Pipelines must succeed" off** (`only_allow_merge_if_pipeline_succeeds` false): with `--auto-merge=false` the API ignores CI and merges immediately, even with a running or failed pipeline. glab's own guard only trips on `ci_must_pass`, or on the auto-merge path with a non-`success` pipeline. Wait for CI yourself and require `mergeable` first. Approvals and thread resolution are separate checks and still apply.
- A group or instance setting can make `--sha` mandatory on the merge API (19.2+).
- `glab mr create --remove-source-branch` and `--squash-before-merge` set the PR's options; omitting them uses project settings.
