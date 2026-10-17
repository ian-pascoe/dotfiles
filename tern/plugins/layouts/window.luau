-- Pre-defined layouts. Each LAYOUTS entry is a palette command (action
-- `plugin.layouts.<id>`) that builds a tab in the focused block's directory.
-- A node is a leaf ({ run = "cmd" }, or {} for a plain shell) or a split:
-- { split = "right"|"down", ratio = first side's share, [1], [2] }.
-- A leaf's command starts in its pane's login shell, and a shell takes its
-- place when it quits (on Windows the pane closes instead).
-- Run from a tab holding only an idle shell (a fresh session or tab), the
-- layout replaces that tab.
-- Tern 0.9.2's plugin API can't address panes or tabs created since the
-- update by id (ids at or above 2^44), so nothing here looks panes up by the
-- ids cx.layout:tab or events hand out: commands go in with the launch, and
-- the replaced shell is found in cx.session:panes() and closed as the focused
-- pane.

local LAYOUTS = {
	{
		id = "dev",
		title = "Dev layout: pi | nvim / shell",
		split = "right",
		ratio = 0.4,
		{ run = "pi" },
		{ split = "down", ratio = 0.7, { run = "nvim ." }, {} },
	},
}

local WINDOWS = tern.runtime.os == "windows"

local function launch_of(node, cwd: string)
	if not node.run then
		return { cwd = cwd }
	end
	local command = if WINDOWS then node.run else node.run .. '; exec "${SHELL:-/bin/sh}" -l'
	return { cwd = cwd, command = command }
end

local function spec_of(node, cwd: string)
	if node.split then
		return {
			cwd = cwd,
			split = node.split,
			ratio = node.ratio,
			spec_of(node[1], cwd),
			spec_of(node[2], cwd),
		}
	end
	return { cwd = cwd, launch = launch_of(node, cwd) }
end

-- The focused pane's info, and whether it is its tab's only pane and an idle
-- shell.
local function focused_pane(cx)
	local panes = cx.session:panes()
	local focused = nil
	for _, p in panes do
		if p.focused then
			focused = p
		end
	end
	if not focused then
		return nil, false
	end
	local alone = true
	for _, p in panes do
		if p.pane ~= focused.pane and p.tab == focused.tab then
			alone = false
		end
	end
	local idle = focused.kind == "terminal" and focused.at_prompt == true and not focused.running
	return focused, alone and idle and not focused.floating
end

local function build(cx, layout)
	local focused, replace = focused_pane(cx)
	local cwd = focused and focused.cwd
	if not cwd or cwd == "" then
		cwd = tern.getenv("HOME") or "/"
	end

	-- Built in the background so the shell it replaces is still focused, and
	-- closing that shows the layout's tab.
	local tab, err = cx.layout:tab(spec_of(layout, cwd :: string), { focus = not replace })
	if not tab then
		cx:toast("error", "Layout failed: " .. tostring(err))
		return
	end
	if replace then
		cx:command("close_pane")
	end
end

for _, layout in LAYOUTS do
	tern.command({
		id = layout.id,
		title = layout.title,
		group = "layouts",
		run = function(cx)
			build(cx, layout)
		end,
	})
end
