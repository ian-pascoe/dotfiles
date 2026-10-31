# Azure DevOps

- **Hosts:** Azure DevOps Services only: `dev.azure.com`, legacy `<org>.visualstudio.com`, SSH `ssh.dev.azure.com`. The remote URL shapes are in Detect & auth. Azure DevOps Server (on-premises) is not covered: an `/_git/` remote on any other host is a host no reference covers.
- **Tool:** `az repos` (azure-devops extension, GA) plus `az devops invoke` for REST; CLI version not shown on the docs page; checked 2026-10-30
- **Exercised:** not yet
- **Sources:** https://learn.microsoft.com/en-us/cli/azure/repos/pr?view=azure-cli-latest, https://learn.microsoft.com/en-us/cli/azure/devops?view=azure-cli-latest#az-devops-invoke, https://learn.microsoft.com/en-us/azure/devops/cli/log-in-via-pat, https://learn.microsoft.com/en-us/azure/devops/cli/?view=azure-devops, https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pull-requests/update?view=azure-devops-rest-7.1, https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pull-requests/get-pull-request?view=azure-devops-rest-7.1, https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pull-request-threads/create?view=azure-devops-rest-7.1, https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pull-request-threads/list?view=azure-devops-rest-7.1, https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pull-request-threads/update?view=azure-devops-rest-7.1, https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pull-request-thread-comments/create?view=azure-devops-rest-7.1, https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/evaluations/list?view=azure-devops-rest-7.1, https://learn.microsoft.com/en-us/rest/api/azure/devops/build/builds/get-build-log?view=azure-devops-rest-7.1, https://learn.microsoft.com/en-us/rest/api/azure/devops/build/stages/update?view=azure-devops-rest-7.1, https://learn.microsoft.com/en-us/azure/devops/repos/git/branch-policies?view=azure-devops, https://learn.microsoft.com/en-us/azure/devops/repos/git/resolution-mentions, https://github.com/Azure/azure-devops-cli-extension
- **Placeholders:** `<n>` PR number, `<b>` PR branch, `<t>` target branch, `<sha>` reviewed head, `<ticket>` ticket number, `<org>` organization, `<project>` project, `<repo>` repo

REST uses full refs (`refs/heads/<b>`); CLI flags take short names. `az devops invoke` takes `--api-version 7.1` as a number. Write JSON bodies to a file and pass `--in-file`.

REST calls below share this shape (change `--resource`, `--http-method`, `--in-file`):

```
az devops invoke --area git --resource pullRequests --route-parameters project=<project> repositoryId=<repo> pullRequestId=<n> --http-method PATCH --in-file body.json --api-version 7.1
```

## Detect & auth

- Remotes: `https://dev.azure.com/<org>/<project>/_git/<repo>`, `https://<org>@dev.azure.com/…`, `https://<org>.visualstudio.com/…`, `git@ssh.dev.azure.com:v3/<org>/<project>/<repo>`. **Unverified**: check `git remote get-url origin` on a real repo (or the Azure DevOps remote-URL docs) before first use.
- Setup: `az extension add --name azure-devops`. Login: `az login`, or `az devops login --organization https://dev.azure.com/<org>`, or env `AZURE_DEVOPS_EXT_PAT`.
- Defaults: `az devops configure -d organization=https://dev.azure.com/<org> project=<project>`; `--detect true` reads the org from the git remote.
- Auth status: **Unsupported** → probe with `az repos pr list --top 1`.
- Push access: learned from the first push.

## Who am I

`GET https://dev.azure.com/<org>/_apis/connectionData` → `authenticatedUser`. **Unverified**: check `az devops invoke --area Location --resource ConnectionData` (or the API page) before first use. `az account show` is the Entra identity, not the DevOps identity.

## Default branch

`az repos show --repository <repo> --query defaultBranch -o tsv` → `refs/heads/<name>` (strip the prefix). **Unverified**: check `az repos show --help` (or the API page) before first use.

## Find PRs

- Open PR for a branch: `az repos pr list --source-branch <b> --status active --query "[].{id:pullRequestId,author:createdBy.uniqueName,head:lastMergeSourceCommit.commitId,base:targetRefName}"`. The `--query` field names (from the REST `GitPullRequest` type): **Unverified**: check `az repos pr list` output (or the API page) before first use. Other options: `--target-branch`, `--creator`, `--reviewer`, `--top`, `--status {abandoned,active,all,completed}`.
- PRs that close a ticket: work items link at create, so list PRs on the work item: `az repos pr list --status all` and check `az repos pr work-item list --id <n>` for `<ticket>`. Fallback: search PR descriptions for the closing keyword + `<ticket>`. **Unverified**: check `az repos pr work-item list --help` before first use.

## Open PR

```
az repos pr create --source-branch <b> --target-branch <t> --title "<title>" --description "<short body>" [--work-items <ticket>]
```

- Body file: **Unsupported** → `--description` takes values, each one a new line. The description limit is 4000 characters, so open with a short body, then set the full one with Edit PR body.
- `--target-branch` defaults to the repo default. `--draft true` exists.

## Edit PR body

`PATCH …/pullRequests/<n>` with `{"description": "<body>"}` (4000 characters max). Build the JSON from the file: `jq -Rs '{description: .}' body.md > body.json`, then the `az devops invoke` PATCH above.

If the body is over 4000 characters: set the description to Summary and Merge Danger plus a link to an overflow thread, and put the full body in that thread (create it as in Comment, with `status: closed`).

## Comment

Create a thread with `status: closed` so it doesn't count as an open thread. `az repos pr` has no comment command: **Unsupported** → REST:

```
az devops invoke --area git --resource pullRequestThreads --route-parameters project=<project> repositoryId=<repo> pullRequestId=<n> --http-method POST --in-file thread.json --api-version 7.1
```

`thread.json`: `{"comments":[{"parentCommentId":0,"content":"<text>","commentType":1}],"status":"closed"}`. The `thread.json` body shape: **Unverified**: check the Threads – Create page before first use.

## List comments

`GET …/pullRequests/<n>/threads` (`--resource pullRequestThreads --http-method GET`). Top-level comments are threads with no `threadContext` (no file/line anchor). Skip system comments (the `commentType` value for system comments is **Unverified**: check the Threads – List page). The API order isn't documented: sort by `lastUpdatedDate`, oldest first.

## Checks

- PR checks: no watch. Poll `az repos pr policy list --id <n>`. Each evaluation `status`: `queued`/`running` = pending, `approved` = pass, `rejected`/`broken` = fail, `notApplicable` = ignore. `isBlocking` marks required policies.
- Checks on a commit (default branch head): **Unverified**: check `az pipelines runs list --help` (or the Builds API page) before first use.
- CI config paths: **Unverified**: no path read. `azure-pipelines.yml` is the usual file; check the repo and the project's pipelines (`az pipelines list`) before concluding there is no CI.
- Failing job logs: `GET …/_apis/build/builds/<buildId>/logs` lists logs; `…/logs/<logId>` reads one. `az pipelines` has no log command: **Unsupported** → the REST calls above. Build ID from the policy evaluation `context`. **Unverified**: check the policy evaluation output before first use.
- Rerun failed: `az repos pr policy queue --id <n> --evaluation-id <e>` re-queues a policy evaluation. Or retry one stage: `PATCH …/_apis/build/builds/<buildId>/stages/<stageRefName>` with `{"state":"retry","forceRetryAllJobs":false}`.

## Review threads

- List unresolved: threads list as in List comments; keep `status` of `active` (or `pending`) and not deleted.
- Reply: `POST …/threads/<threadId>/comments` (`--resource pullRequestThreadComments`, route parameter `threadId=<threadId>`).
- Resolve: `PATCH …/threads/<threadId>` with `{"status":"fixed"}`. `status` values: `active, fixed, wontFix, closed, byDesign, pending, unknown`. Needs scope `vso.threads_full`.

## Blocking verdicts

`az repos pr show --id <n> --query "reviewers[].{who:uniqueName,vote:vote,required:isRequired}"`. The `vote` number meanings (and `isRequired`) are **Unverified**: check the Pull Request Reviewers API page before first use. A reviewer's rejection is also a `rejected` minimum-reviewers policy evaluation.

## Approvals & readiness

- Required approvals: the "minimum reviewers" policy configuration (`az repos policy list`); the setting name is **Unverified**: check its output before first use.
- Current approvals: `reviewers[].vote` from `az repos pr show --id <n>`.
- Mergeable now: `az repos pr show --id <n> --query "{status:status,merge:mergeStatus,why:mergeFailureMessage,draft:isDraft}"` plus `az repos pr policy list --id <n>`. Ready = `status` `active`, not draft, `mergeStatus` `succeeded`, every `isBlocking` policy `approved`. `mergeStatus` values: `notSet`, `queued` (wait), `conflicts`, `rejectedByPolicy`, `failure` (hold).

## Bypass check

Bypass needs a permission ("Bypass policies when completing pull requests" / "when pushing", at project, repo or branch scope) and the per-call opt-in `completionOptions.bypassPolicy`. Without the opt-in, a completion doesn't bypass, even for a holder. Reading your own effective permission is **Unverified**: check the security-namespace API page before first use. Never send `bypassPolicy`.

## Merge methods & merge queue

- `completionOptions.mergeStrategy`: `squash` = `squash`; `noFastForward` (default) = `merge commit`; `rebase` and `rebaseMerge` = `rebase`. If unset, the deprecated `squashMerge` decides.
- Allowed methods: set by a branch policy ("Limit merge types"). **Unverified**: check `az repos policy list` output before first use.
- Merge queue: **Unsupported** → none found in the sources; merge once the policies pass.

## Merge

Head-SHA pin: **Unverified**: check the Pull Requests – Update page for how a mismatching `lastMergeSourceCommit` is handled before first use. Until then re-read the head just before completing (`az repos pr show --id <n> --query lastMergeSourceCommit.commitId -o tsv`), abort if it isn't `<sha>`, and compare `lastMergeSourceCommit` after.

`body.json`:

```json
{
  "status": "completed",
  "lastMergeSourceCommit": { "commitId": "<sha>" },
  "completionOptions": { "mergeStrategy": "squash", "deleteSourceBranch": true }
}
```

Then the `az devops invoke` PATCH above. If `autoCompleteSetBy` is set, clear it first (see Read back).

Never pass:

- `bypassPolicy` / `--bypass-policy true` (also `--bypass-policy-reason`): skips required policies.
- `--auto-complete true` / `autoCompleteOptions`: completes later once policies pass (default off).
- `autoCompleteIgnoreConfigIds`: lets auto-complete skip optional policies.
- `az repos pr update --status completed`: re-sends the server's current head, so it's no pin, and its merge strategy is `--squash` only.

## Read back

Completion is asynchronous. Poll: `az repos pr show --id <n> --query "{status:status,merge:mergeStatus,commit:lastMergeCommit.commitId,auto:autoCompleteSetBy.id,closed:closedDate}"`.

- Merged: `status` is `completed` and `lastMergeCommit` is set.
- In progress: `status` still `active` and `lastMergeCommit` empty (also empty if the merge failed); `mergeStatus` `queued`. A failure `mergeStatus` (`conflicts`, `rejectedByPolicy`, `failure`) means it didn't merge.
- Auto-complete on: `autoCompleteSetBy` is set.
- Queued in a required merge queue: **Unsupported** → no queue found.
- Cancel auto-complete: `az repos pr update --id <n> --auto-complete false`.

## Delete branch

With the merge: `deleteSourceBranch: true` in `completionOptions`. Already gone counts as deleted.

## Retarget

`PATCH …/pullRequests/<n>` with `{"targetRefName":"refs/heads/<t>"}`. Works only when the PR retargeting feature is enabled. `az repos pr update` has no target flag: **Unsupported** → this REST call.

## Closing tickets

Tickets are work items, not issues.

- Link at create: `az repos pr create --work-items <ticket>`; `--transition-work-items true` also transitions them. Later: `az repos pr work-item add` (**Unverified**: check `--help` before first use).
- Commit keywords `fix`, `fixes`, `fixed` + `#<ticket>` (case-insensitive, optional colon; a list like `#1,2,3` only resolves the first). They resolve on push to the default branch, or on PR completion with "Complete associated work items after merging".
- Squash merges don't resolve work items.

## Quirks

- Server's REST supports up to 7.0, so the 7.1 pages don't apply there.
