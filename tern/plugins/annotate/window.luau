-- Annotate: a port of herdr-annotate. Plugins can't read the terminal
-- selection, so capture annotates the clipboard: copy text (⌘C, or
-- ctrl+insert), then run `plugin.annotate.capture`. Annotations live in this plugin's kv store and
-- are copied as the same Markdown herdr-annotate writes.

local ACTIVE = "annotations" -- oldest first
local ARCHIVES = "archives" -- oldest first

type Annotation = {
	id: string,
	selectedText: string,
	comment: string,
	context: { session: string?, tab: string?, cwd: string?, program: string? },
	createdAt: string,
}

type Archive = { id: string, archivedAt: string, annotations: { Annotation } }

local function load(key: string): { any }
	return tern.kv.get(key) or {}
end

local function now(): string
	return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function new_id(): string
	return string.format("%x%04x", os.time(), math.random(0, 0xffff))
end

-- Tern can write the clipboard but not read it, so capture runs the OS's
-- paste tool. Linux: wl-paste on Wayland, else xclip or xsel.
local LINUX_PASTE = [[
if [ -n "$WAYLAND_DISPLAY" ] && command -v wl-paste >/dev/null 2>&1; then exec wl-paste --no-newline; fi
if command -v xclip >/dev/null 2>&1; then exec xclip -selection clipboard -out; fi
if command -v xsel >/dev/null 2>&1; then exec xsel --clipboard --output; fi
echo 'install wl-clipboard, xclip or xsel' >&2
exit 127
]]

local PASTE = {
	macos = { "pbpaste" },
	linux = { "/bin/sh", "-c", LINUX_PASTE },
	-- UTF-8 without a BOM; -Raw keeps the text's own line breaks.
	windows = {
		"powershell",
		"-NoProfile",
		"-NonInteractive",
		"-Command",
		"[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false); Get-Clipboard -Raw",
	},
}

local COPY_HINT = if tern.runtime.os == "macos" then "Copy terminal text first (⌘C)" else "Copy terminal text first"

local function count(n: number): string
	return n .. (if n == 1 then " annotation" else " annotations")
end

-- Terminal text without control characters, tabs as four spaces.
local function sanitize(text: string): string
	text = string.gsub(text, "\r\n", "\n")
	text = string.gsub(text, "\t", "    ")
	return (string.gsub(text, "[%z\1-\8\11\12\14-\31\127]", ""))
end

-- One line of at most `max` characters, for picker rows.
local function oneline(text: string, max: number): string
	text = string.gsub(text, "%s+", " ")
	text = string.match(text, "^%s*(.-)%s*$") or text
	if utf8.len(text) and utf8.len(text) > max then
		text = string.sub(text, 1, utf8.offset(text, max) - 1) .. "…"
	end
	return text
end

local function newest_first(list: { Annotation }): { Annotation }
	local out = {}
	for i = #list, 1, -1 do
		table.insert(out, list[i])
	end
	return out
end

local function fence(text: string): string
	local longest = 0
	for run in string.gmatch(text, "`+") do
		longest = math.max(longest, #run)
	end
	return string.rep("`", math.max(3, longest + 1))
end

-- herdr-annotate's Markdown, newest first.
local function format(list: { Annotation }): string
	local sections = {}
	for i, a in ipairs(newest_first(list)) do
		local parts = { "## Annotation " .. i }
		local source = {}
		for _, field in ipairs({ a.context.session, a.context.tab }) do
			if field and field ~= "" then
				table.insert(source, field)
			end
		end
		if #source > 0 then
			table.insert(parts, "")
			table.insert(parts, "Source: " .. table.concat(source, " / "))
		end
		local f = fence(a.selectedText)
		table.insert(parts, "")
		table.insert(parts, "Selected text:")
		table.insert(parts, "")
		table.insert(parts, f)
		table.insert(parts, a.selectedText)
		table.insert(parts, f)
		table.insert(parts, "")
		table.insert(parts, "Comment:")
		table.insert(parts, "")
		table.insert(parts, a.comment)
		table.insert(sections, table.concat(parts, "\n"))
	end
	return "# Annotated context\n\n" .. table.concat(sections, "\n\n") .. "\n"
end

-- Where the text came from: the focused pane's session, tab and directory.
local function context_of(cx)
	local context = {}
	local id = cx.session:focused()
	local pane = id and cx.session:pane(id)
	if not pane then
		return context
	end
	context.cwd = if pane.cwd ~= "" then pane.cwd else nil
	context.program = pane.program
	for _, tab in ipairs(cx.session:tabs()) do
		if tab.id == pane.tab then
			context.tab = tab.name or tab.title or pane.title
			for _, session in ipairs(cx.session:sessions()) do
				if session.id == tab.session then
					context.session = session.name
				end
			end
		end
	end
	return context
end

local function remove(key: string, id: string)
	local kept = {}
	for _, item in ipairs(load(key)) do
		if item.id ~= id then
			table.insert(kept, item)
		end
	end
	tern.kv.set(key, kept)
end

local function copy_all(cx): boolean
	local active = load(ACTIVE)
	if #active == 0 then
		cx:toast("info", "No annotations to copy")
		return false
	end
	cx:copy(format(active))
	cx:toast("success", "Copied " .. count(#active))
	return true
end

local function copy_and_archive(cx)
	local active = load(ACTIVE)
	if #active == 0 then
		cx:toast("info", "No annotations to copy")
		return
	end
	cx:copy(format(active))
	local archives = load(ARCHIVES)
	table.insert(archives, { id = new_id(), archivedAt = now(), annotations = active })
	tern.kv.set(ARCHIVES, archives)
	tern.kv.set(ACTIVE, {})
	cx:toast("success", "Copied and archived " .. count(#active))
end

tern.command({
	id = "capture",
	title = "Annotate copied text",
	group = "annotate",
	run = function(cx)
		local context = context_of(cx)
		local argv = PASTE[tern.runtime.os]
		if not argv then
			cx:toast("error", "Annotate can't read the clipboard on " .. tern.runtime.os)
			return
		end
		tern.process.run(argv, { timeout_ms = 3000 }):next(function(result, err, cx2)
			if not cx2 then
				return
			end
			if result and result.status == 127 then
				cx2:toast("error", "Annotate can't read the clipboard", sanitize(result.stderr))
				return
			end
			local text = result and result.status == 0 and sanitize(result.stdout) or ""
			if tern.runtime.os == "windows" then
				-- PowerShell ends its output with a line break of its own.
				text = string.gsub(text, "\n$", "")
			end
			if err or not string.find(text, "%S") then
				cx2:toast("info", "Nothing to annotate", COPY_HINT)
				return
			end
			cx2:prompt({ placeholder = "Comment on “" .. oneline(text, 60) .. "”", action = "save" })
				:next(function(comment, _, cx3)
					if not comment or not string.find(comment, "%S") or not cx3 then
						return
					end
					local active = load(ACTIVE)
					table.insert(active, {
						id = new_id(),
						selectedText = text,
						comment = comment,
						context = context,
						createdAt = now(),
					})
					tern.kv.set(ACTIVE, active)
					cx3:toast("success", "Annotation saved", count(#active))
				end)
		end)
	end,
})

tern.command({
	id = "copy_context",
	title = "Copy annotations as context",
	group = "annotate",
	run = function(cx)
		copy_all(cx)
	end,
})

tern.command({
	id = "copy_archive",
	title = "Copy annotations as context and archive them",
	group = "annotate",
	run = copy_and_archive,
})

-- Manager: herdr-annotate's popup as a chain of pickers.

local manage, manage_archives

local function manage_one(cx, a: Annotation)
	cx:pick({
		placeholder = oneline(a.comment, 80),
		items = {
			{ label = "Copy", detail = "this annotation as context", op = "copy" },
			{ label = "Edit comment", op = "edit" },
			{ label = "Delete", op = "delete" },
			{ label = "Back", op = "back" },
		},
	}):next(function(item, _, cx2)
		if not item or not cx2 then
			return
		end
		if item.op == "copy" then
			cx2:copy(format({ a }))
			cx2:toast("success", "Copied 1 annotation")
		elseif item.op == "edit" then
			cx2:prompt({ value = a.comment, placeholder = "Comment", action = "save" }):next(function(comment, _, cx3)
				if not comment or not string.find(comment, "%S") or not cx3 then
					return
				end
				local active = load(ACTIVE)
				for _, other in ipairs(active) do
					if other.id == a.id then
						other.comment = comment
					end
				end
				tern.kv.set(ACTIVE, active)
				manage(cx3)
			end)
		elseif item.op == "delete" then
			remove(ACTIVE, a.id)
			cx2:toast("info", "Annotation deleted")
			manage(cx2)
		else
			manage(cx2)
		end
	end)
end

local function manage_archive(cx, archive: Archive)
	cx:pick({
		placeholder = "Archive of " .. archive.archivedAt,
		items = {
			{ label = "Copy", detail = count(#archive.annotations) .. " as context", op = "copy" },
			{ label = "Restore", detail = "back into the active list", op = "restore" },
			{ label = "Delete permanently", op = "delete" },
			{ label = "Back", op = "back" },
		},
	}):next(function(item, _, cx2)
		if not item or not cx2 then
			return
		end
		if item.op == "copy" then
			cx2:copy(format(archive.annotations))
			cx2:toast("success", "Copied " .. count(#archive.annotations))
		elseif item.op == "restore" then
			local active = load(ACTIVE)
			local have = {}
			for _, a in ipairs(active) do
				have[a.id] = true
			end
			for _, a in ipairs(archive.annotations) do
				if not have[a.id] then
					table.insert(active, a)
				end
			end
			table.sort(active, function(x, y)
				return x.createdAt < y.createdAt
			end)
			tern.kv.set(ACTIVE, active)
			remove(ARCHIVES, archive.id)
			cx2:toast("success", "Restored " .. count(#archive.annotations))
			manage(cx2)
		elseif item.op == "delete" then
			cx2:pick({
				placeholder = "Delete " .. count(#archive.annotations) .. " for good?",
				items = { { label = "Cancel" }, { label = "Delete permanently", confirm = true } },
			}):next(function(answer, _, cx3)
				if answer and answer.confirm and cx3 then
					remove(ARCHIVES, archive.id)
					cx3:toast("info", "Archive deleted")
					manage_archives(cx3)
				end
			end)
		else
			manage_archives(cx2)
		end
	end)
end

function manage_archives(cx)
	local archives = load(ARCHIVES)
	if #archives == 0 then
		cx:toast("info", "No archives")
		return
	end
	local items = {}
	for i = #archives, 1, -1 do
		local archive = archives[i]
		local first = archive.annotations[#archive.annotations]
		table.insert(items, {
			label = archive.archivedAt,
			detail = count(#archive.annotations) .. (if first then "  " .. oneline(first.comment, 50) else ""),
			archive = archive,
		})
	end
	cx:pick({ items = items, placeholder = "Archived annotations" }):next(function(item, _, cx2)
		if item and cx2 then
			manage_archive(cx2, item.archive)
		end
	end)
end

function manage(cx)
	local active = load(ACTIVE)
	local archives = load(ARCHIVES)
	local items = {}
	for _, a in ipairs(newest_first(active)) do
		table.insert(items, {
			label = oneline(a.comment, 80),
			detail = oneline(a.selectedText, 60),
			group = count(#active),
			annotation = a,
		})
	end
	if #active > 0 then
		table.insert(items, { label = "Copy all", detail = "as context", group = "Actions", op = "copy" })
		table.insert(items, { label = "Copy all and archive", group = "Actions", op = "archive" })
	end
	if #archives > 0 then
		table.insert(items, { label = "Archives", detail = tostring(#archives), group = "Actions", op = "archives" })
	end
	if #items == 0 then
		cx:toast("info", "No annotations", "Copy terminal text, then annotate it")
		return
	end
	cx:pick({ items = items, placeholder = "Annotations" }):next(function(item, _, cx2)
		if not item or not cx2 then
			return
		end
		if item.annotation then
			manage_one(cx2, item.annotation)
		elseif item.op == "copy" then
			copy_all(cx2)
		elseif item.op == "archive" then
			copy_and_archive(cx2)
		elseif item.op == "archives" then
			manage_archives(cx2)
		end
	end)
end

tern.command({ id = "manage", title = "Manage annotations", group = "annotate", run = manage })
