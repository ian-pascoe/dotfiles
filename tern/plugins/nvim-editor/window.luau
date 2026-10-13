-- Neovim as Tern's file editor. File opens from the Files sidebar, palette,
-- file picker, links, drops and Finder go to a Neovim pane beside the focused
-- one; a Neovim already running in the tab is reused, whether this plugin
-- started it or it was started by hand (found by asking each local Neovim's
-- server socket for its $TERN_PANE).
-- Files on a remote host open in a Neovim there: panes spawn on the session's
-- host, but this half's tern.fs and tern.process act on this machine, so
-- remote reuse types the open into the Neovim pane with cx:run instead, and
-- finds a hand-started Neovim by the pane's foreground program.
-- Tern keeps sidebar previews, `tern open` (so EDITOR='tern open --wait'
-- still works), Carly's opens, files on a host other than the session's, and
-- images, archives, notebooks and other binaries.
-- The Files sidebar's Changes tab opens file blocks without asking routes, so
-- a new file block that no route.open announced is taken for one: it closes
-- and the file opens in the Neovim instead (gitsigns' ]h/[h walk its hunks),
-- on remote hosts too.
-- `plugin.nvim-editor.toggle` switches routing off/on.
-- Open scrollback in editor (prefix+[) shows the block's scrollback in a
-- Neovim that takes the block's place until it quits.
-- On Windows this machine's Neovims listen on named pipes and local panes run
-- PowerShell; remote hosts are always POSIX (Tern's remote runs on sh).

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

local WINDOWS = tern.runtime.os == "windows"

local function quote(s: string): string
	return "'" .. string.gsub(s, "'", "'\\''") .. "'"
end

local function psquote(s: string): string
	return "'" .. string.gsub(s, "'", "''") .. "'"
end

-- PowerShell takes a script as base64 UTF-16LE, which needs no quoting in
-- whichever shell (PowerShell or cmd) Tern runs a pane command with.
local function encoded(script: string): string
	local units = {}
	for _, c in utf8.codes(script) do
		if c >= 0x10000 then
			c -= 0x10000
			local hi, lo = 0xD800 + c // 0x400, 0xDC00 + c % 0x400
			table.insert(units, string.char(hi % 256, hi // 256, lo % 256, lo // 256))
		else
			table.insert(units, string.char(c % 256, c // 256))
		end
	end
	return tern.base64.encode(table.concat(units))
end

local function powershell_argv(script: string): { string }
	return { "powershell", "-NoProfile", "-NonInteractive", "-EncodedCommand", encoded(script) }
end

local function powershell_command(script: string): string
	return "powershell -NoProfile -EncodedCommand " .. encoded(script)
end

local SEP = if WINDOWS then "[/\\]" else "/"

local function dirname(path: string): string
	return string.match(path, "^(.*)" .. SEP .. "[^/\\]*$") or "/"
end

-- Whether path is inside directory dir.
local function inside(path: string, dir: string): boolean
	local sep = string.sub(path, #dir + 1, #dir + 1)
	return dir ~= "" and string.sub(path, 1, #dir) == dir and string.match(sep, SEP) ~= nil
end

local function is_nvim(program: string?): boolean
	if program == nil then
		return false
	end
	return string.match(string.gsub(string.lower(program), "%.exe$", ""), "n?vim$") ~= nil
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

-- Whether new panes spawn on this machine, running Windows.
local function windows_panes(cx): boolean
	return WINDOWS and not is_remote(cx)
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
	elseif WINDOWS then
		-- tern.fs can't see named pipes; a dead one fails the send instead.
		alive = pane ~= nil
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
	local name = string.format("tern-nvim-%x%04x", os.time(), math.random(0, 0xffff))
	local windows = windows_panes(cx)
	local socket = if windows then "\\\\.\\pipe\\" .. name else "/tmp/" .. name .. ".sock"
	local args = { "--listen", socket }
	if req.line and req.col then
		table.insert(args, string.format("+call cursor(%d, %d)", req.line, req.col))
	elseif req.line then
		table.insert(args, "+" .. req.line)
	end
	if not windows then
		-- Windows paths never start with "-" (and PowerShell 5 drops "--").
		table.insert(args, "--")
	end
	table.insert(args, req.path)
	local command = "nvim"
	for _, arg in args do
		command ..= " " .. (if windows then psquote(arg) elseif arg == "--" then arg else quote(arg))
	end

	local pane = focused and cx.session:pane(focused)
	local cwd = pane and pane.cwd or ""
	if not inside(req.path, cwd) then
		cwd = dirname(req.path)
	end
	local spec = {
		command = if windows then powershell_command(command) else command,
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

-- nvim lives on the login shell's PATH (mise), not Tern's. A login shell
-- takes ~250 ms, so one finds nvim and where its default sockets go, then
-- nvim runs directly; the login shell stays the fallback. Windows has no
-- login shell: nvim is on PATH, and its sockets are named pipes.
local function login_shell(): string
	return tern.getenv("SHELL") or (if tern.runtime.os == "macos" then "/bin/zsh" else "/bin/sh")
end

-- Neovim's default socket is $XDG_RUNTIME_DIR/nvim.PID.0, or without that
-- variable (macOS) $TMPDIR/nvim.$USER/<random>/nvim.PID.0.
local RESOLVE = [[
bin=$(mise which nvim 2>/dev/null || command -v nvim) || exit 1
tmp=${TMPDIR:-/tmp}
printf '%s\n%s\n%s\n' "$bin" "$XDG_RUNTIME_DIR" "${tmp%/}/nvim.${USER:-$(id -un)}"
]]

local nvim: { bin: string, run: string, tmp: string }? = nil
local resolve_tried = false

-- Runs cb once nvim's path is known (or known to be unknown).
local function with_nvim(cb: () -> ())
	if nvim and tern.fs.exists(nvim.bin) then
		cb()
		return
	end
	resolve_tried = true
	local argv = if WINDOWS then { "where.exe", "nvim" } else { login_shell(), "-lc", RESOLVE }
	tern.process.run(argv, { timeout_ms = 5000 }, function(result)
		local out = string.gsub(result.stdout, "\r", "")
		local bin, run, tmp
		if WINDOWS then
			bin, run, tmp = string.match(out, "^([^\n]+)"), "", ""
		else
			bin, run, tmp = string.match(out, "^([^\n]+)\n([^\n]*)\n([^\n]+)")
		end
		nvim = if result.status == 0 and bin and run and tmp then { bin = bin, run = run, tmp = tmp } else nil
		cb()
	end)
end

-- argv running nvim with args.
local function nvim_argv(args: { string }): { string }
	local argv = if nvim
		then { nvim.bin }
		elseif WINDOWS then { "nvim" }
		else { login_shell(), "-lc", 'exec nvim "$@"', "nvim" }
	for _, arg in args do
		table.insert(argv, arg)
	end
	return argv
end

-- Prints "<TERN_PANE>\t<socket>" for every live local Neovim: default sockets
-- (stdpath('run')/nvim.PID.0) and the ones this plugin starts with --listen.
-- $1 is nvim; $2 and $3 RESOLVE's directories (default: this shell's).
local SCAN = [[
setopt null_glob 2>/dev/null
nvim=$1
if [ $# -ge 3 ]; then
	run=$2 tmp=$3
else
	run=$XDG_RUNTIME_DIR tmp=${TMPDIR:-/tmp}
	tmp=${tmp%/}/nvim.${USER:-$(id -un)}
fi
for s in "${run:-/nonexistent}"/nvim.*.0 "$tmp"/*/nvim.*.0 /tmp/tern-nvim-*.sock; do
	[ -S "$s" ] || continue
	p=$("$nvim" --server "$s" --remote-expr '$TERN_PANE' 2>/dev/null) || continue
	[ -n "$p" ] && printf '%s\t%s\n' "$p" "$s"
done
exit 0
]]

-- The same on Windows, where Neovim's sockets are named pipes (nvim.PID.0 by
-- default); $nvim is set above it.
local SCAN_WINDOWS = [[
try { $pipes = [IO.Directory]::GetFiles('\\.\pipe\') } catch { $pipes = @() }
foreach ($s in $pipes) {
	if ([IO.Path]::GetFileName($s) -notmatch '^(nvim\.\d+\.0|tern-nvim-[0-9a-f]+)$') { continue }
	$p = & $nvim --server $s --remote-expr '$TERN_PANE' 2>$null
	if ($LASTEXITCODE -eq 0 -and "$p" -match '^\d+$') { [Console]::Out.Write("$p`t$s`n") }
}
exit 0
]]

-- Finds a running Neovim in `tab`, preferring the focused pane's.
local function discover(tab: number?, focused: number?, cb: (editor: any, cx: any) -> ())
	with_nvim(function()
		local argv
		if WINDOWS then
			argv = powershell_argv("$nvim = " .. psquote(if nvim then nvim.bin else "nvim") .. "\n" .. SCAN_WINDOWS)
		elseif nvim then
			argv = { "/bin/sh", "-c", SCAN, "scan", nvim.bin, nvim.run, nvim.tmp }
		else
			argv = { login_shell(), "-lc", SCAN, "scan", "nvim" }
		end
		tern.process.run(argv, { timeout_ms = 5000 }, function(result, cx)
			if not cx then
				return
			end
			local found = nil
			if tab and result.status == 0 then
				local out = string.gsub(result.stdout, "\r", "")
				for id, socket in string.gmatch(out, "(%d+)\t([^\n]+)") do
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
	end)
end

-- Opens the file in a local Neovim over its socket; on failure calls on_fail.
local function send(editor, req, on_fail: (cx: any) -> ())
	with_nvim(function()
		local argv = nvim_argv({ "--server", editor.socket, "--remote-send", remote_keys(req) })
		tern.process.run(argv, { timeout_ms = 5000 }, function(result, cx)
			if not cx then
				return
			end
			if result.status == 0 then
				cx.layout:focus(editor.pane)
			else
				on_fail(cx)
			end
		end)
	end)
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

-- A Neovim running in `tab` (preferring the focused pane), by foreground
-- program: remote sockets are out of this machine's reach.
local function find_by_program(cx, tab: number?, focused: number?)
	if not tab then
		return nil
	end
	local found = nil
	for _, p in cx.session:panes() do
		if p.tab == tab and p.kind == "terminal" and is_nvim(p.program) and (not found or p.pane == focused) then
			found = { pane = p.pane, socket = "" }
		end
	end
	if found then
		editors[tab :: number] = found
	end
	return found
end

-- Opens req in the tab's Neovim on the session's remote host, typing the open
-- into it with cx:run (tern.process.run would run on this machine).
local function open_remote(cx, req, focused: number?, tab: number?)
	local editor = reusable(cx, tab) or (req.how ~= "tab" and find_by_program(cx, tab, focused))
	if editor and pcall(cx.run, cx, editor.pane, typed_keys(req)) then
		cx.layout:focus(editor.pane)
	else
		launch(cx, req, focused, tab)
	end
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

	if is_remote(cx) then
		open_remote(cx, req, focused, tab)
	else
		open_local(cx, req, focused, tab)
	end
	return { handled = true }
end)

-- Every pane as of the last focus change. Pane ids are not ordered across
-- sessions, so newness is "absent from the last snapshot".
local known: { [number]: boolean }? = nil

local function snapshot(cx): { [number]: boolean }
	local panes = {}
	for _, p in cx.session:panes() do
		panes[p.pane] = true
	end
	return panes
end

local function warm_up()
	if not resolve_tried then
		with_nvim(function() end)
	end
end

tern.on("window_start", function(cx)
	known = snapshot(cx)
	warm_up()
end)

-- A Changes-tab open shows up as a new, focused file block.
tern.on("focus", function(ev, cx)
	warm_up()
	local id = ev and ev.pane
	if not id then
		return
	end
	-- After a reload (no window_start) the first focus only takes the snapshot.
	local fresh = known ~= nil and not (known :: { [number]: boolean })[id]
	known = snapshot(cx)
	if not fresh then
		return
	end

	local info = cx.session:pane(id)
	if not enabled() or not info or info.kind ~= "file" or not info.path then
		return
	end
	local path = info.path :: string
	local when = announced[path]
	if when and os.time() - when <= 2 then
		return -- a route.open that Tern kept (preview, `tern open`, images, ...)
	end
	local ext = string.match(path, "%.([%w]+)$")
	if ext and TERN_KEEPS[string.lower(ext)] then
		return
	end
	local remote = is_remote(cx)
	-- tern.fs sees only this machine; a remote directory doesn't reach here.
	if not remote and pcall(tern.fs.list, path) then
		return
	end
	local read = cx.session:read(id, { lines = 1 })
	if type(read) == "table" then
		if read.dirty then
			return
		end
		-- Neovim panes spawn on the session's host; a file elsewhere stays in Tern.
		local host = cx.hosts:current()
		if type(read.host) == "number" and read.host ~= host.id then
			return
		end
	end

	cx.layout:close(id)
	local focused = cx.session:focused()
	local req = { path = path, how = "beside" }
	if remote then
		open_remote(cx, req, focused, info.tab)
		return
	end
	-- Show the known Neovim at once; the open follows over its socket.
	local editor = reusable(cx, info.tab)
	if editor then
		cx.layout:focus(editor.pane)
	end
	open_local(cx, req, cx.session:focused(), info.tab)
end)

-- Scrollback in Neovim. Tern's built-in hands a temp file to the system's
-- text editor; this captures it with `tern capture` on the block's host
-- (remote ones too) and runs Neovim in a block split from it, then parks the
-- block so Neovim fills its place. When Neovim quits, its block sets a title,
-- and the handler deals the parked block back into Neovim's place. Events can
-- reach another VM than the override's, so the state lives in tern.kv.

-- A window pane id carries its host in the bits above 2^44 (local ones have
-- none); `tern capture` on that host knows the block by the rest.
local function host_pane_id(pane: number): string
	return string.format("%.0f", pane % 2 ^ 44)
end

local function scrollback_key(pane: number): string
	return "scrollback:" .. string.format("%.0f", pane)
end

-- $1: block id on this host; $2: title that says Neovim quit; $3: the
-- block's title while Neovim runs. Trailing blank rows are dropped; the block
-- then waits for the plugin to close it.
local SCROLLBACK = [[
printf '\033]2;%s\007' "$3"
f=$(mktemp "${TMPDIR:-/tmp}/tern-scrollback.XXXXXX")
tern capture "$1" --scrollback 2>&1 | awk 'NF { for (; n > 0; n--) print ""; print; next } { n++ }' > "$f"
nvim -R + -- "$f"
rm -f "$f"
printf '\033]2;%s\007' "$2"
exec sleep 600
]]

-- The same in PowerShell, for panes on this machine running Windows; $id,
-- $marker and $title are set above it. The console title reaches Tern as
-- OSC 2 through ConPTY.
local SCROLLBACK_WINDOWS = [=[
[Console]::Title = $title
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$f = [IO.Path]::GetTempFileName()
$lines = @(tern capture $id --scrollback 2>&1 | ForEach-Object { "$_" })
$n = $lines.Count
while ($n -gt 0 -and $lines[$n - 1].Trim() -eq '') { $n-- }
$keep = if ($n -gt 0) { $lines[0..($n - 1)] } else { @() }
[IO.File]::WriteAllLines($f, [string[]]$keep, [Text.UTF8Encoding]::new($false))
nvim -R + $f
Remove-Item -LiteralPath $f -ErrorAction SilentlyContinue
[Console]::Title = $marker
Start-Sleep -Seconds 600
]=]

tern.override("open_scrollback", function(cx)
	local focused = cx.session:focused()
	local info = focused and cx.session:pane(focused)
	if not info or (info.kind ~= "terminal" and info.kind ~= "agent") then
		return false
	end
	local pane = focused :: number
	local marker = string.format("tern-scrollback-%06x", math.random(0, 0xffffff))
	local title = "scrollback: " .. info.title
	local command
	if windows_panes(cx) then
		command = powershell_command(
			string.format("$id = %s\n$marker = %s\n$title = %s\n", host_pane_id(pane), psquote(marker), psquote(title))
				.. SCROLLBACK_WINDOWS
		)
	else
		command = "sh -c " .. quote(SCROLLBACK) .. " scrollback " .. host_pane_id(pane) .. " " .. marker .. " " .. quote(title)
	end
	local editor = cx.layout:split(pane, "down", { command = command, cwd = info.cwd })
	if not editor then
		return false
	end
	tern.kv.set(scrollback_key(editor), { pane = pane, marker = marker })
	cx.layout:park(pane)
	return true
end)

-- Puts the parked block back where its Neovim was (unpark deals it beside the
-- focused block, then a swap moves it into place) and closes the Neovim.
local function restore(cx, editor: number, pane: number)
	local info = cx.session:pane(pane)
	if not info then
		return
	end
	if info.parked then
		cx.layout:unpark(pane, { focus = false })
	end
	if cx.session:pane(editor) then
		cx.layout:move(pane, editor, "swap", { focus = false })
		cx.layout:close(editor)
	end
	cx.layout:focus(pane)
end

tern.on("title", function(ev, cx)
	local editor = ev and tonumber(ev.pane)
	local job = editor and tern.kv.get(scrollback_key(editor))
	if type(job) ~= "table" or ev.title ~= job.marker then
		return
	end
	tern.kv.set(scrollback_key(editor :: number), nil)
	restore(cx, editor :: number, job.pane)
end)

-- The Neovim block closed some other way: bring the parked block back.
tern.on("pane_closed", function(ev, cx)
	local editor = ev and tonumber(ev.pane)
	local job = editor and tern.kv.get(scrollback_key(editor))
	if type(job) ~= "table" then
		return
	end
	tern.kv.set(scrollback_key(editor :: number), nil)
	local info = cx.session:pane(job.pane)
	if info and info.parked then
		cx.layout:unpark(job.pane)
	end
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
