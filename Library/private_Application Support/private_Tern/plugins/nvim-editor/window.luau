-- Neovim as Tern's file editor. File opens from the Files sidebar, palette,
-- file picker, links, drops and Finder go to a Neovim pane beside the focused
-- one; the tab's Neovim (started here, listening on a socket) is reused.
-- Files on a remote host open in a Neovim there: panes spawn on the session's
-- host, but this half's tern.fs and tern.process act on this machine, so
-- remote reuse types the open into the Neovim pane with cx:run instead.
-- Tern keeps sidebar previews, `tern open` (so EDITOR='tern open --wait'
-- still works), Carly's opens, files on a host other than the session's, and
-- images, archives, notebooks and other binaries.
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

-- Tab id -> the Neovim this plugin started there.
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
	-- A remote socket lives on the remote host, out of tern.fs's reach.
	local socket_ok = is_remote(cx) or tern.fs.exists(editor.socket)
	if pane and pane.tab == tab and is_nvim(pane.program) and socket_ok then
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
	local spec = {
		command = "nvim --listen " .. quote(socket) .. " " .. jump .. "-- " .. quote(req.path),
		cwd = cwd,
	}

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

tern.route.open(function(req, cx)
	if not routable(req, cx) then
		return nil
	end
	local focused = cx.session:focused()
	local info = focused and cx.session:pane(focused)
	local tab = info and info.tab

	local editor = reusable(cx, tab)
	if not editor then
		launch(cx, req, focused, tab)
		return { handled = true }
	end

	if is_remote(cx) then
		-- tern.process.run would run here, not on the remote host, so type the
		-- open into the Neovim pane; cx:run reaches remote hosts' panes.
		if not pcall(cx.run, cx, editor.pane, typed_keys(req)) then
			launch(cx, req, focused, tab)
			return { handled = true }
		end
		cx.layout:focus(editor.pane)
		return { handled = true }
	end

	-- nvim lives on the login shell's PATH (mise), not Tern's.
	local shell = tern.getenv("SHELL") or "/bin/zsh"
	tern.process.run(
		{ shell, "-lc", 'exec nvim --server "$1" --remote-send "$2"', "nvim", editor.socket, remote_keys(req) },
		{ timeout_ms = 5000 },
		function(result, cx2)
			if not cx2 then
				return
			end
			if result.status == 0 then
				cx2.layout:focus(editor.pane)
			else
				launch(cx2, req, cx2.session:focused(), tab)
			end
		end
	)
	return { handled = true }
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
