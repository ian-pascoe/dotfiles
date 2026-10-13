-- Neovim as Tern's file editor. File opens from the Files sidebar, palette,
-- file picker, links, drops and Finder go to a Neovim pane beside the focused
-- one; a Neovim already running in the tab is reused, whether this plugin
-- started it or it was started by hand (found by asking each local Neovim's
-- server socket for its $TERN_PANE).
-- Files on a remote host open in a Neovim there: panes spawn on the session's
-- host, but this half's tern.fs and tern.process act on this machine, so
-- remote reuse types the open into the Neovim pane with cx:run instead.
-- Tern keeps sidebar previews, `tern open` (so EDITOR='tern open --wait'
-- still works), Carly's opens, files on a host other than the session's, and
-- images, archives, notebooks and other binaries.
-- The Files sidebar's Changes tab opens file blocks without asking routes, so
-- a new file block that no route.open announced is taken for one: it closes
-- and the file's changes open in the Neovim, in Diffview when installed.
-- `plugin.nvim-editor.toggle` switches routing off/on.

local ROUTED_ORIGINS = { palette = true, files = true, drop = true, link = true, system = true }

local TERN_KEEPS = {}
for ext in
	string.gmatch(
		"png jpg jpeg gif webp bmp ico icns tif tiff heic avif pdf zip gz tgz bz2 xz zst 7z rar tar jar "
			.. "mp3 mp4 m4a mov avi mkv webm wav flac ogg woff woff2 ttf otf sqlite sqlite3 db ipynb "
			.. "dylib dll exe bin so o a class pyc wasm",
		"%S+"
	)
do
	TERN_KEEPS[ext] = true
end

-- Tab id -> the Neovim last used there.
local editors: { [number]: { pane: number, socket: string } } = {}

local function enabled(): boolean
	return tern.kv.get("enabled") ~= false
end

local function quote(s: string): string
	return "'" .. string.gsub(s, "'", "'\\''") .. "'"
end

local function dirname(path: string): string
	return string.match(path, "^(.*)/[^/]*$") or "/"
end

-- Lua for Neovim that shows the file's git changes: the file, then Diffview
-- on it in a new tabpage (lazy.nvim may not have loaded Diffview yet).
local function diff_lua(path: string): string
	return "local p = " .. string.format("%q", path) .. "; local e = vim.fn.fnameescape; "
		.. "vim.cmd('edit ' .. e(p)); "
		.. "pcall(function() require('lazy').load({ plugins = { 'diffview.nvim' } }) end); "
		.. "if vim.fn.exists(':DiffviewOpen') == 2 then "
		.. "vim.cmd('DiffviewOpen -C' .. e(vim.fn.fnamemodify(p, ':h')) .. ' -- ' .. e(p)) end"
end

local function is_nvim(program: string?): boolean
	return program ~= nil and string.match(string.lower(program), "n?vim$") ~= nil
end

local function routable(req, cx): boolean
	if not enabled() or not ROUTED_ORIGINS[req.origin] or req.how == "preview" then
		return false
	end
	-- New panes spawn on the session's host, so only its files can open there.
	local host = cx.hosts:current()
	if req.host ~= host.name then
		return false
	end
	local ext = string.match(req.path, "%.([%w]+)$")
	if ext and TERN_KEEPS[string.lower(ext)] then
		return false
	end
	if host.kind ~= "local" then
		-- tern.fs can't see the remote host; a directory opens in Neovim's explorer.
		return true
	end
	-- Directories go to Tern (fs.list only succeeds on one).
	return not pcall(tern.fs.list, req.path)
end

local function is_remote(cx): boolean
	return cx.hosts:current().kind ~= "local"
end

-- The tab's live Neovim from an earlier open, if any.
local function reusable(cx, tab: number?)
	local editor = tab and editors[tab]
	if not editor then
		return nil
	end
	local pane = cx.session:pane(editor.pane)
	local alive
	if is_remote(cx) then
		-- A remote socket lives on the remote host, out of tern.fs's reach.
		alive = pane ~= nil and is_nvim(pane.program)
	else
		-- Neovim removes its socket on exit; a hand-started one runs under a
		-- shell, so the pane's program need not be nvim.
		alive = tern.fs.exists(editor.socket)
	end
	if pane and pane.tab == tab and alive then
		return editor
	end
	editors[tab :: number] = nil
	return nil
end

local function launch(cx, req, focused: number?, tab: number?)
	local socket = string.format("/tmp/tern-nvim-%x%04x.sock", os.time(), math.random(0, 0xffff))
	local jump = ""
	if req.line and req.col then
		jump = quote(string.format("+call cursor(%d, %d)", req.line, req.col)) .. " "
	elseif req.line then
		jump = quote("+" .. req.line) .. " "
	end
	local pane = focused and cx.session:pane(focused)
	local cwd = pane and pane.cwd ~= "" and pane.cwd or ""
	if cwd == "" or string.sub(req.path, 1, #cwd + 1) ~= cwd .. "/" then
		cwd = dirname(req.path)
	end
	local args = if req.diff
		then "-c " .. quote("lua " .. diff_lua(req.path))
		else jump .. "-- " .. quote(req.path)
	local spec = { command = "nvim --listen " .. quote(socket) .. " " .. args, cwd = cwd }

	local opened
	if req.how == "tab" or not focused then
		opened = cx.layout:new_tab(spec)
		tab = nil -- a new tab: don't remember it under the old one
	else
		opened = cx.layout:split(focused, if req.how == "below" then "down" else "right", spec)
	end
	if opened and tab then
		editors[tab] = { pane = opened, socket = socket }
	end
end

-- Neovim key notation for opening the file in the running editor.
local function remote_keys(req): string
	if req.diff then
		return "<C-\\><C-N><Cmd>lua " .. string.gsub(diff_lua(req.path), "<", "<lt>") .. "<CR>"
	end
	local path = string.gsub(string.gsub(req.path, "<", "<lt>"), "'", "''")
	local keys = "<C-\\><C-N><Cmd>call execute('edit " .. (if req.line then "+" .. req.line .. " " else "")
	keys ..= "' . fnameescape('" .. path .. "'))<CR>"
	if req.line and req.col then
		keys ..= string.format("<Cmd>call cursor(%d, %d)<CR>", req.line, req.col)
	end
	return keys
end

-- The same open as remote_keys, as raw keystrokes for cx:run: Ctrl-\ Ctrl-N
-- reaches Normal mode from any mode, then Ex commands run the open.
local function typed_keys(req): string
	local path = string.gsub(req.path, "'", "''")
	local keys = "\28\14:call execute('edit " .. (if req.line then "+" .. req.line .. " " else "")
	keys ..= "' . fnameescape('" .. path .. "'))\r"
	if req.line and req.col then
		keys ..= string.format(":call cursor(%d, %d)\r", req.line, req.col)
	end
	return keys
end

-- nvim lives on the login shell's PATH (mise), not Tern's.
local function login_shell(): string
	return tern.getenv("SHELL") or "/bin/zsh"
end

-- Prints "<TERN_PANE>\t<socket>" for every live local Neovim: default sockets
-- (stdpath('run')/nvim.PID.0) and the ones this plugin starts with --listen.
local SCAN = [[
setopt null_glob 2>/dev/null
for s in "${TMPDIR%/}/nvim.$USER"/*/nvim.*.0 /tmp/tern-nvim-*.sock; do
	[ -S "$s" ] || continue
	p=$(nvim --server "$s" --remote-expr '$TERN_PANE' 2>/dev/null) || continue
	[ -n "$p" ] && printf '%s\t%s\n' "$p" "$s"
done
exit 0
]]

-- Finds a running Neovim in `tab`, preferring the focused pane's.
local function discover(tab: number?, focused: number?, cb: (editor: any, cx: any) -> ())
	tern.process.run({ login_shell(), "-lc", SCAN }, { timeout_ms = 5000 }, function(result, cx)
		if not cx then
			return
		end
		local found = nil
		if tab and result.status == 0 then
			for id, socket in string.gmatch(result.stdout, "(%d+)\t([^\n]+)") do
				local pane = tonumber(id)
				local info = pane and cx.session:pane(pane)
				if info and info.tab == tab and (not found or pane == focused) then
					found = { pane = pane, socket = socket }
				end
			end
		end
		if found then
			editors[tab :: number] = found
		end
		cb(found, cx)
	end)
end

-- Opens the file in a local Neovim over its socket; on failure calls on_fail.
local function send(editor, req, on_fail: (cx: any) -> ())
	tern.process.run(
		{ login_shell(), "-lc", 'exec nvim --server "$1" --remote-send "$2"', "nvim", editor.socket, remote_keys(req) },
		{ timeout_ms = 5000 },
		function(result, cx)
			if not cx then
				return
			end
			if result.status == 0 then
				cx.layout:focus(editor.pane)
			else
				on_fail(cx)
			end
		end
	)
end

-- Reuses a hand-started Neovim in the tab, else starts one.
local function discover_or_launch(req, focused: number?, tab: number?)
	discover(tab, focused, function(editor, cx)
		if not editor then
			launch(cx, req, cx.session:focused(), tab)
			return
		end
		send(editor, req, function(cx2)
			editors[tab :: number] = nil
			launch(cx2, req, cx2.session:focused(), tab)
		end)
	end)
end

-- Opens req in the tab's local Neovim: the remembered one, else one found
-- running there, else a new one.
local function open_local(cx, req, focused: number?, tab: number?)
	local editor = reusable(cx, tab)
	if not editor then
		if req.how == "tab" then
			launch(cx, req, focused, tab)
		else
			discover_or_launch(req, focused, tab)
		end
		return
	end
	-- A stale socket (Neovim crashed): look for another before starting one.
	send(editor, req, function()
		editors[tab :: number] = nil
		discover_or_launch(req, focused, tab)
	end)
end

-- Path -> os.time() of its last route.open, routed or not, to tell the
-- Changes tab's file blocks (which skip routes) from every other open.
local announced: { [string]: number } = {}

tern.route.open(function(req, cx)
	announced[req.path] = os.time()
	if not routable(req, cx) then
		return nil
	end
	local focused = cx.session:focused()
	local info = focused and cx.session:pane(focused)
	local tab = info and info.tab

	if not is_remote(cx) then
		open_local(cx, req, focused, tab)
		return { handled = true }
	end

	local editor = reusable(cx, tab)
	if not editor then
		launch(cx, req, focused, tab)
		return { handled = true }
	end
	-- tern.process.run would run here, not on the remote host, so type the
	-- open into the Neovim pane; cx:run reaches remote hosts' panes.
	if pcall(cx.run, cx, editor.pane, typed_keys(req)) then
		cx.layout:focus(editor.pane)
	else
		launch(cx, req, focused, tab)
	end
	return { handled = true }
end)

-- Newest pane id when the plugin started watching; older blocks are left alone.
local watermark: number? = nil

local function newest_pane(cx): number
	local newest = 0
	for _, p in cx.session:panes() do
		newest = math.max(newest, p.pane)
	end
	return newest
end

tern.on("window_start", function(cx)
	watermark = newest_pane(cx)
end)

-- A Changes-tab open shows up as a new, focused file block.
tern.on("focus", function(ev, cx)
	local id = ev and ev.pane
	if not id then
		return
	end
	if not watermark then
		-- Reloaded without window_start: only blocks opened from now on.
		watermark = newest_pane(cx)
		return
	end
	if id <= (watermark :: number) then
		return
	end
	watermark = id

	local info = cx.session:pane(id)
	if not enabled() or is_remote(cx) or not info or info.kind ~= "file" or not info.path then
		return
	end
	local path = info.path :: string
	local when = announced[path]
	if when and os.time() - when <= 2 then
		return -- a route.open that Tern kept (preview, `tern open`, images, ...)
	end
	local ext = string.match(path, "%.([%w]+)$")
	if (ext and TERN_KEEPS[string.lower(ext)]) or pcall(tern.fs.list, path) then
		return
	end
	local read = cx.session:read(id, { lines = 1 })
	if type(read) == "table" and read.dirty then
		return
	end

	cx.layout:close(id)
	local focused = cx.session:focused()
	local req = { path = path, how = "beside", diff = true }
	open_local(cx, req, focused, info.tab)
end)

tern.command({
	id = "toggle",
	title = "Toggle opening files in Neovim",
	group = "nvim-editor",
	run = function(cx)
		local on = not enabled()
		tern.kv.set("enabled", on)
		cx:toast("info", if on then "Files open in Neovim" else "Files open in Tern's editor")
	end,
})
