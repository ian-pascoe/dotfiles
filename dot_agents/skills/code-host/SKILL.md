---
name: code-host
description: Find a repo's code host and the commands for its PRs, reviews, checks, and merges. Use when acting on a PR, or when another skill names it.
---

Find the repo's **code host** and load its **code host reference** from `references/`: that host's commands, under the same headings in every reference. A skill that runs this one points at a heading in parentheses, like (**Checks**), and takes the command from there.

## Find the code host

The code host is the service holding the remote the branch pushes to: its push remote, else `origin`. Take the host you were told, by the user or a brief, else the one the tracker doc (`docs/agents/issue-tracker.md`) names, else the remote's hostname from this table:

| Hostname                                                   | Reference         |
| ---------------------------------------------------------- | ----------------- |
| `github.com`, `*.ghe.com`                                  | `github.md`       |
| `gitlab.com`                                               | `gitlab.md`       |
| `bitbucket.org`                                            | `bitbucket.md`    |
| `dev.azure.com`, `ssh.dev.azure.com`, `*.visualstudio.com` | `azure-devops.md` |
| `codeberg.org`                                             | `forgejo.md`      |
| `gitea.com`                                                | `gitea.md`        |
| `git.cafe`                                                 | `gitcafe.md`      |

For any other hostname, probe in order: `https://<host>/api/forgejo/v1/version` answers, Forgejo; `https://<host>/api/v1/version` answers, Gitea; otherwise the host whose CLI (`gh`, `glab`, `cafe`) recognises the repo. When none does, or more than one, the host is **ambiguous**.

## Check access

Check that the host's tool or token works and that you can push to that remote, or learn it from the first push where the host can't tell (**Detect & auth**).

Done when you hold one reference whose tool works and can push, or can name what's missing: no remote, an ambiguous host, a host or edition no reference covers, missing auth, or no push access.
