-- herdr compat: the herdr actions Tern has no built-in for, as palette
-- commands `plugin.herdr.<id>`. settings.json `keybinds` gives them herdr's
-- keys (managed by chezmoi's modify_settings.json.tmpl); nothing is bound here
-- because preset chords win over plugin binds.

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

-- Focuses pane `id`, switching to its session.
local function focus_pane(cx, id: number)
	if addressable(cx, id) then
		cx.layout:focus(id)
		return
	end
	local spec = full_id(cx, id)
	if spec then
		cli({ "focus", spec })
	end
end

-- Vim-aware pane navigation (herdr's scripts/navigate.sh). A Vim in the
-- focused pane gets the Ctrl chord and moves between its own splits; at an
-- edge it calls `tern focus` itself (nvim lua/plugins/util.lua). Any other
-- program: Tern moves pane focus.

-- vim-tmux-navigator's matcher: vi, vim, nvim, lvim, gvim, view, *diff...
local function is_vim(program: string?): boolean
	if not program then
		return false
	end
	local name = string.lower(string.match(program, "[^/]+$") or program)
	name = (string.gsub(name, "diff$", ""))
	return string.match(name, "^g?view$") ~= nil or string.match(name, "^g?l?n?vim?x?$") ~= nil
end

local CHORDS = {
	left = "\x08", -- Ctrl+H
	down = "\x0a", -- Ctrl+J
	up = "\x0b", -- Ctrl+K
	right = "\x0c", -- Ctrl+L
}

for _, dir in ipairs({ "left", "down", "up", "right" }) do
	tern.command({
		id = "navigate_" .. dir,
		title = "Navigate " .. dir .. " (vim-aware)",
		group = "herdr",
		run = function(cx)
			local pane = cx.session:pane("@focused")
			if not pane or not is_vim(pane.program) then
				cx:action("focus_pane:" .. dir)
			elseif not pcall(cx.run, cx, pane.pane, CHORDS[dir]) then
				cli({ "send", full_id(cx, pane.pane) or "@focused", "text", CHORDS[dir] })
			end
		end,
	})
end

-- Workspaces are Tern sessions on the current host, in list order.

local function local_sessions(cx)
	local current = cx.sessions:current()
	local list = {}
	for _, session in ipairs(cx.sessions:list()) do
		if session.host == current.host then
			table.insert(list, session)
		end
	end
	return list, current
end

local function step_session(delta: number)
	return function(cx)
		local list, current = local_sessions(cx)
		if #list < 2 then
			return
		end
		for i, session in ipairs(list) do
			if session.id == current.id then
				cx.sessions:switch(list[(i - 1 + delta) % #list + 1].id)
				return
			end
		end
	end
end

tern.command({ id = "next_session", title = "Next session", group = "herdr", run = step_session(1) })
tern.command({ id = "previous_session", title = "Previous session", group = "herdr", run = step_session(-1) })

for n = 1, 9 do
	tern.command({
		id = "goto_session_" .. n,
		title = "Go to session " .. n,
		group = "herdr",
		run = function(cx)
			local list = local_sessions(cx)
			if list[n] then
				cx.sessions:switch(list[n].id)
			end
		end,
	})
end

-- herdr's goto: search agents and terminals across sessions, then focus one.

tern.command({
	id = "goto",
	title = "Go to agent or terminal…",
	group = "herdr",
	run = function(cx)
		local names = {}
		for _, session in ipairs(cx.session:sessions()) do
			names[session.id] = session.name
		end
		local session_of = {}
		for _, tab in ipairs(cx.session:tabs()) do
			session_of[tab.id] = tab.session
		end

		local home = tern.getenv("HOME") or tern.getenv("USERPROFILE") or ""
		local items = {}
		for _, pane in ipairs(cx.session:panes()) do
			if pane.kind == "terminal" or pane.kind == "agent" then
				local session = pane.tab and session_of[pane.tab]
				local cwd = pane.cwd or ""
				if home ~= "" and string.sub(cwd, 1, #home) == home then
					cwd = "~" .. string.sub(cwd, #home + 1)
				end
				table.insert(items, {
					label = if pane.title ~= "" then pane.title else (pane.program or "shell"),
					detail = (pane.program or pane.kind) .. "  " .. cwd,
					group = session and names[session] or "Parked",
					current = pane.focused,
					pane = pane.pane,
					session = session,
				})
			end
		end
		if #items == 0 then
			return
		end
		-- The picker heads runs of one group, so keep each session together.
		table.sort(items, function(a, b)
			return (a.session or math.huge) < (b.session or math.huge)
		end)

		cx:pick({ items = items, placeholder = "Go to agent or terminal", action = "focus" })
			:next(function(item, _, cx2)
				if not item or not cx2 then
					return
				end
				if not addressable(cx2, item.pane) then
					focus_pane(cx2, item.pane) -- the CLI switches sessions itself
					return
				end
				if item.session and item.session ~= cx2.sessions:current().id then
					cx2.sessions:switch(item.session)
				end
				cx2.layout:focus(item.pane)
			end)
	end,
})

-- herdr's `type = "popup"` lazygit: a floating block in the focused pane's
-- directory that closes when lazygit exits.

tern.command({
	id = "lazygit",
	title = "lazygit (popup)",
	group = "herdr",
	run = function(cx)
		local pane = cx.session:pane("@focused")
		if not pane then
			return
		end
		local id = pane.pane
		local cwd = if pane.cwd ~= "" then pane.cwd else nil
		if addressable(cx, id) then
			local popup = cx.layout:split(id, "right", { command = "lazygit", cwd = cwd })
			if popup then
				cx.layout:float(popup, id)
			end
			return
		end
		-- The CLI floats the popup over the block that takes its place: the
		-- focused one it split.
		local args = { "split", full_id(cx, id) or "@focused", "right", "--json" }
		if cwd then
			table.insert(args, "--cwd")
			table.insert(args, cwd)
		end
		table.insert(args, "--")
		if tern.runtime.os == "windows" then
			table.insert(args, "lazygit")
		else
			table.insert(args, tern.getenv("SHELL") or "/bin/sh")
			table.insert(args, "-lc")
			table.insert(args, "lazygit")
		end
		cli(args, function(ok, out)
			local block = ok and string.match(out, '"block"%s*:%s*(%d+)')
			if block then
				cli({ "pip", block })
			end
		end)
	end,
})
