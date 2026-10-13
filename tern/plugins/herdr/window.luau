-- herdr compat: the herdr actions Tern has no built-in for, as palette
-- commands `plugin.herdr.<id>`. settings.json `keybinds` gives them herdr's
-- keys (managed by chezmoi's modify_settings.json.tmpl); nothing is bound here
-- because preset chords win over plugin binds.

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
			local id = cx.session:focused()
			local pane = id and cx.session:pane(id)
			if pane and is_vim(pane.program) then
				cx:run(id, CHORDS[dir])
			else
				cx:action("focus_pane:" .. dir)
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
		local id = cx.session:focused()
		if not id then
			return
		end
		local pane = cx.session:pane(id)
		local cwd = if pane and pane.cwd ~= "" then pane.cwd else nil
		local popup = cx.layout:split(id, "right", { command = "lazygit", cwd = cwd })
		if popup then
			cx.layout:float(popup, id)
		end
	end,
})
