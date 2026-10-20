-- herdr's worktree workspaces for Tern: create, open and remove git worktrees
-- of the focused block's repository. Each worktree is its own session, named
-- "<repo>/<branch>" ("<repo>" for the main checkout); new worktrees go in
-- ~/.tern/worktrees/<repo>/<branch> on the session's host, branched from the
-- focused checkout's HEAD (or checking out the branch when it exists).
--
-- Git runs on the session's host. Locally that is tern.process.run. On a
-- remote host this half's processes would run on this machine, so git runs as
-- the program of a parked block there; it sets the block's title when done,
-- and the `title` event reads its output back. Events can reach another VM
-- of this plugin than the command that started the job (and timers stall
-- while nothing redraws), so a job's state lives in tern.kv and `finish`
-- resumes it from that state alone.
-- Windows has no login shell, so the same scripts run in Git for Windows'
-- sh; remote hosts are always POSIX (Tern's remote runs on sh).

local WINDOWS = tern.runtime.os == "windows"

local function quote(s: string): string
	return "'" .. string.gsub(s, "'", "'\\''") .. "'"
end

local function trim(s: string): string
	return string.match(s, "^%s*(.-)%s*$") or s
end

local function basename(path: string): string
	return string.match(path, "([^/\\]+)[/\\]*$") or path
end

-- git and the user's PATH (mise, Homebrew) come from the login shell.
local function login_shell(): string
	return tern.getenv("SHELL") or (if tern.runtime.os == "macos" then "/bin/zsh" else "/bin/sh")
end

-- Git for Windows' sh, found beside git (<root>/mingw64/libexec/git-core):
-- bin/sh.exe puts its coreutils on PATH, usr/bin/sh.exe needs them added.
type Shell = { argv: { string }, prefix: string }

local git_sh: Shell? = nil

local function with_git_sh(cx, cb: (sh: Shell?, cx: any) -> ())
	if git_sh then
		cb(git_sh, cx)
		return
	end
	local ok = pcall(function()
		tern.process.run({ "git", "--exec-path" }, { timeout_ms = 5000 }, function(result, cx2)
			local root = string.match(trim(result.stdout), "^(.+)[/\\][^/\\]+[/\\]libexec[/\\]git%-core$")
			if root and tern.fs.exists(root .. "/bin/sh.exe") then
				git_sh = { argv = { root .. "/bin/sh.exe", "-c" }, prefix = "" }
			elseif root and tern.fs.exists(root .. "/usr/bin/sh.exe") then
				git_sh = { argv = { root .. "/usr/bin/sh.exe", "-c" }, prefix = "PATH=/usr/bin:$PATH\n" }
			end
			cb(git_sh, cx2)
		end)
	end)
	if not ok then
		cb(nil, cx)
	end
end

-- Tern (since 0.9.2) hands plugins pane and tab ids cut to 44 bits, and the
-- daemon's ids for panes created since are longer, so for those panes the
-- numeric calls (cx.session:pane/read, cx:run, cx.layout:*) find nothing.
-- cx.session lookups still take the full id as a string, and so does the
-- tern CLI, which stands in for cx:run and cx.layout here until Tern fixes
-- it (stencil-hq/tern-sdk#30).

-- Whether the window API can address pane `id` by number.
local function addressable(cx, id: number): boolean
	return cx.session:pane(id) ~= nil
end

-- Pane `id`'s full id, as a resolve spec for cx.session and the tern CLI.
local function full_id(cx, id: number): string?
	for high = 0, 15 do
		local spec = string.format("%.0f", id + high * 2 ^ 44)
		local info = cx.session:pane(spec)
		if info and info.pane == id then
			return spec
		end
	end
	return nil
end

-- The tern CLI: this half's PATH is the app's, which lacks it.
local tern_path: string? = nil

local function tern_bin(): string
	if tern_path then
		return tern_path
	end
	local home = tern.getenv("HOME") or ""
	for _, path in {
		"/Applications/Tern.app/Contents/MacOS/tern",
		home .. "/Applications/Tern.app/Contents/MacOS/tern",
		home .. "/.local/bin/tern",
		"/opt/homebrew/bin/tern",
		"/usr/local/bin/tern",
		"/usr/bin/tern",
	} do
		if tern.fs.exists(path) then
			tern_path = path
			return path
		end
	end
	tern_path = "tern"
	return "tern"
end

-- Runs `tern <args>`, then cb(ok, stdout, cx) when given.
local function cli(args: { string }, cb: ((ok: boolean, out: string, cx: any) -> ())?)
	local argv = { tern_bin() }
	for _, arg in args do
		table.insert(argv, arg)
	end
	local ok = pcall(tern.process.run, argv, { timeout_ms = 5000 }, function(result, cx)
		if cb then
			cb(result.status == 0, result.stdout, cx)
		end
	end)
	if not ok and cb then
		cb(false, "", nil)
	end
end

local function is_local(cx): boolean
	return cx.hosts:current().kind == "local"
end

-- Scripts run with `exec 2>&1`, so the output carries git's errors in order.

-- The repository's main checkout ("root"), the checkout this runs in
-- ("here"), then `git worktree list --porcelain`.
local LIST = [[
exec 2>&1
common=$(git rev-parse --path-format=absolute --git-common-dir) || exit 1
printf 'root %s\n' "$(dirname "$common")"
printf 'here %s\n' "$(git rev-parse --show-toplevel 2>/dev/null)"
git worktree list --porcelain
]]

-- $1: branch; $2: nonempty when $1 is a suggestion. Prints "session <name>"
-- and "path <worktree>"; a branch some worktree already has is reported, not
-- added again.
local CREATE = [[
exec 2>&1
branch=$1
git check-ref-format --branch "$branch" >/dev/null 2>&1 || { echo "Not a valid branch name: $branch"; exit 1; }
common=$(git rev-parse --path-format=absolute --git-common-dir) || exit 1
root=$(dirname "$common")
name=$(basename "$root")
# $2 nonempty: a suggested name, so a taken one gets a -2, -3, ... suffix.
if [ -n "$2" ]; then
	base=$branch n=2
	while git show-ref --quiet --verify "refs/heads/$branch" ||
		git show-ref --quiet --verify "refs/remotes/origin/$branch" ||
		[ -e "$HOME/.tern/worktrees/$name/$branch" ]; do
		branch=$base-$n n=$((n + 1))
	done
fi
existing=$(git worktree list --porcelain | awk -v b="branch refs/heads/$branch" '/^worktree /{p=substr($0,10)} $0==b{print p; exit}')
if [ -n "$existing" ]; then
	if [ "$existing" = "$root" ]; then session=$name; else session=$name/$branch; fi
	printf 'session %s\npath %s\n' "$session" "$existing"
	exit 0
fi
dest="$HOME/.tern/worktrees/$name/$(printf '%s' "$branch" | tr '/' '-')"
mkdir -p "$(dirname "$dest")" || exit 1
if git show-ref --verify --quiet "refs/heads/$branch"; then
	git worktree add "$dest" "$branch" >/dev/null || exit 1
elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
	git worktree add --track -b "$branch" "$dest" "origin/$branch" >/dev/null || exit 1
else
	git worktree add -b "$branch" "$dest" >/dev/null || exit 1
fi
# git prints the path the way this OS writes it (C:/... in Git for Windows).
printf 'session %s\npath %s\n' "$name/$branch" "$(git -C "$dest" rev-parse --show-toplevel)"
]]

-- $1: worktree path; $2: nonempty to force (discarding its changes).
local REMOVE = [[
exec 2>&1
if [ -n "$2" ]; then
	git worktree remove --force "$1"
else
	git worktree remove "$1"
fi
]]

local SCRIPTS = { list = LIST, create = CREATE, remove = REMOVE }

local finish: (cx: any, job: any, status: number, output: string) -> ()

-- Runs SCRIPTS[script] in `cwd` on the session's host with `args`, then
-- finish(cx, job, status, output). `job` must be JSON: it may come back
-- through tern.kv in another VM.
local function run_git(cx, script: string, cwd: string, args: { string }, job)
	if is_local(cx) then
		local function go(shell: Shell?, cx1)
			if not shell then
				cx1:toast("error", "Worktrees: Git for Windows' sh not found", "Install Git for Windows")
				return
			end
			local argv = table.clone(shell.argv)
			table.insert(argv, shell.prefix .. SCRIPTS[script])
			table.insert(argv, "tern-worktree")
			for _, arg in args do
				table.insert(argv, arg)
			end
			tern.process.run(argv, { cwd = cwd, timeout_ms = 30000 }, function(result, cx2)
				if cx2 then
					local output = string.gsub(result.stdout .. result.stderr, "\r", "")
					finish(cx2, job, result.status, output)
				end
			end)
		end
		if WINDOWS then
			with_git_sh(cx, go)
		else
			go({ argv = { login_shell(), "-lc" }, prefix = "" }, cx)
		end
		return
	end

	local focused = cx.session:pane("@focused")
	if not focused then
		cx:toast("error", "Worktrees: no focused block to run git beside")
		return
	end
	local host = cx.hosts:current().name
	local nonce = string.format("%06x", math.random(0, 0xffffff))
	local cmd = "printf '_%s%s_\\n' TWB " .. nonce .. "; sh -c " .. quote(SCRIPTS[script]) .. " tern-worktree"
	for _, arg in args do
		cmd ..= " " .. quote(arg)
	end
	-- The title change is the "done" signal; sleep keeps the output readable
	-- until the title handler closes the block (or ends it after 10 minutes).
	cmd ..= "; printf '_%s%s_%s_\\n' TWE " .. nonce .. ' "$?"'
	cmd ..= "; printf '\\033]2;%s\\007' tern-worktree-" .. nonce .. "; exec sleep 600"
	-- Jobs are found by the nonce in the title; "pane:<id>" maps a block
	-- back to its job for pane_closed.
	tern.kv.set("job:" .. nonce, { nonce = nonce, job = job })
	if addressable(cx, focused.pane) then
		local pane = cx.layout:split(focused.pane, "down", { cwd = cwd, command = cmd }, { focus = false })
		if not pane then
			tern.kv.set("job:" .. nonce, nil)
			cx:toast("error", "Worktrees: couldn't start git on " .. host)
			return
		end
		tern.kv.set("pane:" .. tostring(pane), nonce)
		cx.layout:park(pane)
		return
	end
	-- The CLI can't park a block: this one shows below the focused one until
	-- git is done.
	local split_args = { "split", full_id(cx, focused.pane) or "@focused", "down", "--json", "--cwd", cwd, "--", "sh", "-c", cmd }
	cli(split_args, function(ok, out, cx2)
		local block = ok and string.match(out, '"block"%s*:%s*(%d+)')
		if not block then
			tern.kv.set("job:" .. nonce, nil)
			if cx2 then
				cx2:toast("error", "Worktrees: couldn't start git on " .. host)
			end
			return
		end
		local info = cx2 and cx2.session:pane(block)
		if info then
			tern.kv.set("pane:" .. tostring(info.pane), nonce)
		end
	end)
end

tern.on("title", function(ev, cx)
	local pane = ev and tonumber(ev.pane)
	local nonce = ev and type(ev.title) == "string" and string.match(ev.title, "^tern%-worktree%-(%x+)$")
	if not pane or not nonce then
		return
	end
	local key = "job:" .. nonce
	local pending = tern.kv.get(key)
	if type(pending) ~= "table" then
		return
	end
	local native = addressable(cx, pane)
	local spec = if native then pane else full_id(cx, pane)
	local text = spec and cx.session:read(spec, { as = "text", lines = 2000 })
	if type(text) ~= "string" then
		return
	end
	local n = pending.nonce
	local output, status = string.match(text, "_TWB" .. n .. "_\n(.-)\n?_TWE" .. n .. "_(%d+)_")
	if not status then
		return
	end
	tern.kv.set(key, nil)
	tern.kv.set("pane:" .. tostring(pane), nil)
	if native then
		cx.layout:close(pane)
	else
		cli({ "close", tostring(spec) })
	end
	finish(cx, pending.job, tonumber(status) :: number, output)
end)

tern.on("pane_closed", function(ev)
	local pane = ev and tonumber(ev.pane)
	local nonce = pane and tern.kv.get("pane:" .. tostring(pane))
	if type(nonce) == "string" then
		tern.kv.set("pane:" .. tostring(pane), nil)
		tern.kv.set("job:" .. nonce, nil)
	end
end)

-- The failure's last output line, which is git's message.
local function fail(cx, title: string, output: string)
	local last = ""
	for line in string.gmatch(output, "[^\n]+") do
		if trim(line) ~= "" then
			last = trim(line)
		end
	end
	cx:toast("error", title, if last ~= "" then last else nil)
end

local function parse_list(output: string)
	local repo = { root = "", here = "", worktrees = {} }
	local current = nil
	for line in string.gmatch(output, "[^\n]+") do
		local key, value = string.match(trim(line), "^(%S+)%s*(.-)$")
		if key == "root" then
			repo.root = value
		elseif key == "here" then
			repo.here = value
		elseif key == "worktree" then
			current = { path = value }
			table.insert(repo.worktrees, current)
		elseif current and key == "branch" then
			current.branch = (string.gsub(value, "^refs/heads/", ""))
		elseif current and key == "HEAD" then
			current.head = value
		elseif current and key == "bare" then
			current.bare = true
		end
	end
	repo.name = basename(repo.root)
	return repo
end

local function session_name(repo, worktree): string
	if worktree.path == repo.root then
		return repo.name
	end
	return repo.name .. "/" .. (worktree.branch or string.sub(worktree.head or "detached", 1, 7))
end

local function find_session(cx, name: string)
	local host = cx.hosts:current().id
	for _, session in cx.sessions:list() do
		if session.name == name and session.host == host then
			return session
		end
	end
	return nil
end

-- Shows the worktree's session, starting one there when it has none.
local function open_session(cx, name: string, path: string)
	local session = find_session(cx, name)
	if session then
		cx.sessions:switch(session.id)
	else
		cx.sessions:create({ name = name, cwd = path })
	end
end

local function short_path(path: string): string
	local home = string.match(path, "^/Users/[^/]+")
		or string.match(path, "^/home/[^/]+")
		or string.match(path, "^%a:[/\\]Users[/\\][^/\\]+")
	if home then
		return "~" .. string.sub(path, #home + 1)
	end
	return path
end

local function items_for(cx, repo, include_main: boolean)
	local items = {}
	for _, worktree in repo.worktrees do
		if not worktree.bare and (include_main or worktree.path ~= repo.root) then
			local name = session_name(repo, worktree)
			local label = worktree.branch or ("detached " .. string.sub(worktree.head or "", 1, 7))
			local detail = short_path(worktree.path)
			if find_session(cx, name) then
				detail ..= "  · session"
			end
			table.insert(items, {
				label = label,
				detail = detail,
				group = repo.name,
				current = worktree.path == repo.here,
				path = worktree.path,
				session = name,
				root = repo.root,
			})
		end
	end
	return items
end

finish = function(cx, job, status: number, output: string)
	if job.op == "open" or job.op == "remove" then
		if status ~= 0 then
			fail(cx, "Couldn't list worktrees", output)
			return
		end
		local repo = parse_list(output)
		if job.op == "open" then
			cx:pick({ items = items_for(cx, repo, true), placeholder = "Open a worktree", action = "open" })
				:next(function(item, _, cx2)
					if item and cx2 then
						open_session(cx2, item.session, item.path)
					end
				end)
			return
		end
		local items = items_for(cx, repo, false)
		if #items == 0 then
			cx:toast("info", "No worktrees to remove", repo.name .. " has only its main checkout")
			return
		end
		cx:pick({ items = items, placeholder = "Remove a worktree", action = "remove" }):next(function(item, _, cx2)
			if not item or not cx2 then
				return
			end
			cx2:pick({
				items = {
					{ label = "Remove " .. item.label, detail = short_path(item.path), force = false },
					{ label = "Force remove " .. item.label, detail = "discards its uncommitted changes", force = true },
				},
				placeholder = "Remove the worktree and close its session?",
				action = "remove",
			}):next(function(choice, _, cx3)
				if choice and cx3 then
					local force = if choice.force then "1" else ""
					run_git(cx3, "remove", item.root, { item.path, force }, {
						op = "removed",
						session = item.session,
						label = item.label,
					})
				end
			end)
		end)
	elseif job.op == "create" then
		if status ~= 0 then
			fail(cx, "Couldn't create worktree " .. job.branch, output)
			return
		end
		-- git's own messages come first; the script's lines come last.
		local name, path
		for line in string.gmatch(output, "[^\n]+") do
			name = string.match(line, "^session (.+)$") or name
			path = string.match(line, "^path (.+)$") or path
		end
		if not name or not path then
			fail(cx, "Couldn't create worktree " .. job.branch, output)
			return
		end
		open_session(cx, trim(name), trim(path))
	elseif job.op == "removed" then
		if status ~= 0 then
			fail(cx, "Couldn't remove worktree " .. job.label, output)
			return
		end
		local session = find_session(cx, job.session)
		if session then
			cx.sessions:close(session.id)
		end
		cx:toast("success", "Removed worktree " .. job.label)
	end
end

-- Default worktree names, herdr-style: an adjective and a noun (64 × 64).
local ADJECTIVES = {
	"amber", "ancient", "autumn", "bold", "brave", "bright", "brisk", "calm",
	"clear", "clever", "cosmic", "crimson", "crisp", "daring", "dusty", "eager",
	"early", "fancy", "fierce", "frosty", "gentle", "gilded", "golden", "grand",
	"green", "hidden", "hollow", "humble", "icy", "jolly", "keen", "lively",
	"lucky", "lunar", "mellow", "misty", "modest", "noble", "nimble", "patient",
	"polar", "proud", "quick", "quiet", "rapid", "rustic", "scarlet", "silent",
	"silver", "sleepy", "snowy", "solar", "steady", "stormy", "sunny", "swift",
	"tidy", "tranquil", "velvet", "vivid", "wandering", "wild", "windy", "young",
}
local NOUNS = {
	"anchor", "aspen", "badger", "beacon", "birch", "bison", "brook", "canyon",
	"cedar", "cliff", "cloud", "comet", "coral", "cove", "crane", "delta",
	"dune", "ember", "falcon", "fern", "field", "fjord", "forest", "fox",
	"glacier", "grove", "harbor", "hawk", "heron", "island", "lagoon", "lantern",
	"maple", "marsh", "meadow", "mesa", "moon", "moss", "nebula", "oak",
	"orbit", "otter", "owl", "pebble", "pine", "prairie", "quartz", "raven",
	"reef", "ridge", "river", "sparrow", "spruce", "stone", "summit", "thicket",
	"tide", "tundra", "valley", "willow", "wolf", "wren", "yarrow", "zephyr",
}

local function suggest_branch(): string
	return ADJECTIVES[math.random(#ADJECTIVES)] .. "-" .. NOUNS[math.random(#NOUNS)]
end

-- The focused block's directory, where git finds the repository (looked up by
-- spec: see `addressable`).
local function focused_cwd(cx): string?
	local info = cx.session:pane("@focused")
	local cwd = info and info.cwd
	if not cwd or cwd == "" then
		cx:toast("error", "Worktrees: focus a block inside a git repository")
		return nil
	end
	return cwd
end

tern.command({
	id = "new",
	title = "New worktree…",
	group = "Worktrees",
	run = function(cx)
		local cwd = focused_cwd(cx)
		if not cwd then
			return
		end
		local suggestion = suggest_branch()
		cx:prompt({ value = suggestion, placeholder = "Branch for the new worktree", action = "create" })
			:next(function(text, _, cx2)
				local branch = text and trim(text)
				if cx2 and branch and branch ~= "" then
					local suggested = if branch == suggestion then "1" else ""
					run_git(cx2, "create", cwd :: string, { branch, suggested }, { op = "create", branch = branch })
				end
			end)
	end,
})

tern.command({
	id = "open",
	title = "Open worktree…",
	group = "Worktrees",
	run = function(cx)
		local cwd = focused_cwd(cx)
		if cwd then
			run_git(cx, "list", cwd, {}, { op = "open" })
		end
	end,
})

tern.command({
	id = "remove",
	title = "Remove worktree…",
	group = "Worktrees",
	run = function(cx)
		local cwd = focused_cwd(cx)
		if cwd then
			run_git(cx, "list", cwd, {}, { op = "remove" })
		end
	end,
})
