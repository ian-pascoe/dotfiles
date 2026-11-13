-- Rex configuration, kept in step with ~/.config/herdr/config.toml so the
-- muscle memory carries over: the same ctrl+a prefix, the same keys after it,
-- the same vim-aware ctrl+h/j/k/l, and the terminal colors of the current
-- theme variant (herdr's "terminal" theme follows Ghostty, which reads
-- ~/.config/theme/ghostty.conf).
--
-- Docs: https://www.superlogical.com/rex/docs
-- Apply changes with `rex config reload` (or prefix+ctrl+r); check with `rex config check`.

local PREFIX = "ctrl+a"
local SHELL = "com.superlogical.terminal.shell"
local TERMINAL = "com.superlogical.terminal"
local HOME = os.getenv("HOME")

-- "ctrl+a>x": a key pressed after the prefix, like herdr's "prefix+x".
local function prefixed(key)
  return PREFIX .. ">" .. key
end

local function bind_prefixed(key, action, args)
  rex.bind(prefixed(key), action, args)
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- The focused terminal's foreground process, or nil.
local function foreground(block_id)
  if not block_id then
    return nil
  end
  local info = rex.block.call(TERMINAL, "process", { block_id = block_id })
  return info and (info.foreground or info.child) or nil
end

-- A floating pane over the active tab, like herdr's popup commands. The pane
-- closes when its command exits. `options` adds shell block options, such as
-- login = false.
local function popup(command, cwd, options)
  local block_options = { command = command, cwd = cwd }
  for key, value in pairs(options or {}) do
    block_options[key] = value
  end
  local _, err = rex.session.new_layer({
    bounds = { 0.05, 0.05, 0.9, 0.9 },
    focus = true,
    layout = rex.layout.block({
      flavor = SHELL,
      options = block_options,
    }),
  })
  if err ~= nil then
    error(err, 0)
  end
end

----------------------------------------------------------------------------
-- Prefix
----------------------------------------------------------------------------

-- Press the prefix twice to send it to the terminal (start of line in shells).
bind_prefixed(PREFIX, "pane.send_key", { key = PREFIX })

----------------------------------------------------------------------------
-- App
----------------------------------------------------------------------------

bind_prefixed("shift+/", "client.palette.toggle") -- help (prefix+?)
bind_prefixed("shift+;", "client.palette.toggle") -- prefix+:
bind_prefixed("shift+s", "client.settings") -- settings
bind_prefixed("d", "client.window.close") -- detach: sessions keep running on the server
bind_prefixed("b", "client.sidebar.toggle") -- toggle_sidebar
-- reload_config; not alt+r, which AeroSpace takes for its resize mode.
bind_prefixed("ctrl+r", "client.config.reload")

----------------------------------------------------------------------------
-- Sessions (herdr workspaces)
----------------------------------------------------------------------------

bind_prefixed("s", "session.switch") -- workspace_picker
bind_prefixed("alt+g", "session.switch") -- goto: Rex's closest picker
bind_prefixed("ctrl+c", "session.new") -- new_workspace
bind_prefixed("shift+r", "session.rename") -- rename_workspace
bind_prefixed("shift+d", "session.close") -- close_workspace
bind_prefixed("shift+p", "session.previous") -- previous_workspace
bind_prefixed("shift+n", "session.next") -- next_workspace

-- switch_workspace = "prefix+shift+1..9"
rex.action({
  name = "goto_session",
  title = "Go to Session by Number",
  category = "Session",
  args = { index = "integer" },
  run = function(ctx, args)
    local list, err = rex.call("session.list")
    if list == nil then
      error(err, 0)
    end
    local session = list.sessions[args.index]
    if session then
      rex.client.queue("session.select", { session_id = session.session_id })
    end
  end,
})

for i = 1, 9 do
  bind_prefixed("shift+" .. i, "goto_session", { index = i })
end

----------------------------------------------------------------------------
-- Tabs
----------------------------------------------------------------------------

bind_prefixed("t", "client.tab.new") -- new_tab
bind_prefixed(",", "client.tab.rename") -- rename_tab
bind_prefixed("p", "client.tab.previous") -- previous_tab
bind_prefixed("n", "client.tab.next") -- next_tab
bind_prefixed("shift+x", "client.tab.close") -- close_tab

for i = 1, 9 do
  bind_prefixed(tostring(i), "client.tab.goto", { index = i }) -- switch_tab
end

----------------------------------------------------------------------------
-- Panes
----------------------------------------------------------------------------

bind_prefixed("h", "pane.focus", { direction = "left", wrap = false })
bind_prefixed("j", "pane.focus", { direction = "down", wrap = false })
bind_prefixed("k", "pane.focus", { direction = "up", wrap = false })
bind_prefixed("l", "pane.focus", { direction = "right", wrap = false })
bind_prefixed("shift+h", "pane.move", { direction = "left" }) -- swap_pane_left
bind_prefixed("shift+j", "pane.move", { direction = "down" }) -- swap_pane_down
bind_prefixed("shift+k", "pane.move", { direction = "up" }) -- swap_pane_up
bind_prefixed("shift+l", "pane.move", { direction = "right" }) -- swap_pane_right
bind_prefixed("tab", "pane.focus_next") -- cycle_pane_next
bind_prefixed("shift+tab", "pane.focus_previous") -- cycle_pane_previous

bind_prefixed("shift+\\", "pane.split", { direction = "right" }) -- split_vertical (prefix+|)
bind_prefixed("-", "pane.split", { direction = "down" }) -- split_horizontal (prefix+minus)
bind_prefixed("x", "pane.close") -- close_pane
bind_prefixed("z", "pane.zoom") -- zoom

-- resize_mode = "prefix+r": hjkl or arrows resize, shift for bigger steps,
-- escape or enter leaves.
rex.mode("resize", { exclusive = true })
bind_prefixed("r", "client.mode.enter", { name = "resize" })

local resize_keys = {
  left = { "h", "left" },
  down = { "j", "down" },
  up = { "k", "up" },
  right = { "l", "right" },
}
for direction, keys in pairs(resize_keys) do
  for _, key in ipairs(keys) do
    rex.bind("resize/" .. key, "pane.resize", { direction = direction })
    rex.bind("resize/shift+" .. key, "pane.resize", { direction = direction, amount = 15 })
  end
end
rex.bind("resize/=", "pane.balance")
rex.bind("resize/enter", "client.mode.exit")

-- edit_scrollback = "prefix+[": open the focused pane's scrollback in $EDITOR.
rex.action({
  name = "edit_scrollback",
  title = "Edit Scrollback in $EDITOR",
  category = "Pane",
  run = function(ctx)
    local screen, err = rex.block.call(TERMINAL, "format", {
      block_id = ctx.block_id,
      format = "text",
      trim = true,
      unwrap = true,
    })
    if screen == nil then
      error(err, 0)
    end
    local dir = (os.getenv("TMPDIR") or "/tmp/"):gsub("/?$", "/")
    local path = dir .. "rex-scrollback-" .. os.time() .. ".txt"
    local file = assert(io.open(path, "w"))
    file:write(screen.content)
    file:close()
    popup({ "sh", "-c", '${VISUAL:-${EDITOR:-neopane}} + "$1"; rm -f "$1"', "sh", path })
  end,
})
bind_prefixed("[", "edit_scrollback")

----------------------------------------------------------------------------
-- Commands
----------------------------------------------------------------------------

-- neopane (https://github.com/ian-pascoe/neopane), installed by its
-- `just install`: one headless Neovim whose windows are each a Rex pane.
local NEOPANE = HOME .. "/.local/bin/neopane"

-- mise's link to its newest Neovim. neopane starts `nvim` from PATH; putting
-- this first skips the mise shim, which costs about 80ms a launch.
local MISE_NVIM_DIR = (os.getenv("XDG_DATA_HOME") or HOME .. "/.local/share") .. "/mise/installs/neovim/latest/bin"

local function exists(path)
  local file = io.open(path)
  if file then
    file:close()
  end
  return file ~= nil
end

-- The command running neopane with `args` (Neovim arguments).
local function neopane(args)
  local command = { "env" }
  if exists(MISE_NVIM_DIR .. "/nvim") then
    table.insert(command, "PATH=" .. MISE_NVIM_DIR .. ":" .. (os.getenv("PATH") or ""))
  end
  table.insert(command, exists(NEOPANE) and NEOPANE or "neopane")
  for _, arg in ipairs(args) do
    table.insert(command, arg)
  end
  return command
end

rex.action({
  name = "neogit",
  title = "Neogit",
  category = "Commands",
  run = function(ctx)
    -- NeogitPopup (nvim plugins/editor.lua) quits Neovim, and so neopane,
    -- when Neogit closes.
    -- login = false: zsh reads only .zshenv (XDG dirs, EDITOR,
    -- GIT_OPTIONAL_LOCKS) and skips the login profile (brew, mise activate,
    -- ~/.env, egress proxy), which took ~0.5s of a ~1.1s open. The server's
    -- PATH already has Homebrew and the mise shims.
    local fg = foreground(ctx.block_id)
    popup(neopane({ "+NeogitPopup" }), fg and fg.cwd or nil, { login = false })
  end,
})
bind_prefixed("g", "neogit")

-- file_viewer = "prefix+f": yazi in a popup. A chosen file opens in the
-- tab's neopane pane, or a new neopane split beside the pane yazi was opened
-- from. Yazi writes its choice to a file and quits; the popup then hands it
-- to open_in_neopane below through `rex do`.
local YAZI = [=[
chosen=$(mktemp "${TMPDIR:-/tmp}/rex-yazi.XXXXXX")
yazi --chooser-file="$chosen"
if [[ -s $chosen ]]; then
  args=$(jq -Rn --arg block "$1" '{block: $block, paths: [inputs | select(. != "")]}' <"$chosen")
  if ! out=$("${REX_BIN_DIR:+$REX_BIN_DIR/}rex" "do" open_in_neopane --args "$args" 2>&1); then
    printf '\nCouldn'"'"'t open in neopane: %s\n\n' "$out" >&2
    read -rsn1 -p 'Press any key to close'
  fi
fi
rm -f "$chosen"
]=]

rex.action({
  name = "file_viewer",
  title = "File Viewer (Yazi)",
  category = "Commands",
  keywords = "yazi files browse open nvim neovim neopane",
  run = function(ctx)
    local fg = foreground(ctx.block_id)
    popup({
      "env",
      "REX_CLIENT=" .. (ctx.client_id or ""),
      "bash",
      "-c",
      YAZI,
      "rex-yazi",
      ctx.block_id or "",
    }, fg and fg.cwd or nil)
  end,
})
bind_prefixed("f", "file_viewer")

-- A neopane pane's foreground process: the launcher (`neopane`, or its `npane`
-- link) in the first pane, `neopane pane` in the rest.
local function is_neopane(name)
  name = name and name:lower()
  return name == "neopane" or name == "npane"
end

-- The window holding block_id, in any of its layers, else the active window.
local function window_of(view, block_id)
  local active
  for _, window in ipairs(view.windows or {}) do
    for _, layer in ipairs(window.layers or {}) do
      for _, block in ipairs(layer.blocks or {}) do
        if block.block_id == block_id then
          return window
        end
      end
    end
    if window.window_id == view.active_window_id then
      active = window
    end
  end
  return active
end

-- The tiled blocks of the window holding block_id (or the active window),
-- in layout order.
local function tiled_blocks(view, block_id)
  local tiled = {}
  local window = window_of(view, block_id)
  for _, layer in ipairs(window and window.layers or {}) do
    if layer.kind == "tiled" then
      for _, block in ipairs(layer.blocks or {}) do
        table.insert(tiled, block.block_id)
      end
    end
  end
  return tiled
end

-- Typed into a neopane pane: Ctrl-\ Ctrl-N reaches Normal mode from any mode, then
-- each path opens with :edit.
local function edit_keys(paths)
  local keys = "\28\14"
  for _, path in ipairs(paths) do
    keys = keys .. ":call execute('edit ' . fnameescape('" .. path:gsub("'", "''") .. "'))\r"
  end
  return keys
end

-- Opens paths in a neopane pane in the window of `block` (preferring that
-- block), else in a new neopane split to the right of it. All of a neopane's
-- panes share one Neovim, so any of them will do.
rex.action({
  name = "open_in_neopane",
  title = "Open Files in neopane",
  category = "Commands",
  args = { paths = "array", block = "string?" },
  run = function(ctx, args)
    if #args.paths == 0 then
      return
    end
    local view, err = rex.session.view({})
    if view == nil then
      error(err, 0)
    end
    local origin = args.block ~= "" and args.block or nil
    local blocks = tiled_blocks(view, origin or ctx.block_id)

    local editor
    for _, id in ipairs(blocks) do
      local fg = foreground(id)
      if fg and is_neopane(fg.name) and (not editor or id == origin) then
        editor = id
      end
    end

    if editor then
      local _, werr = rex.block.call(TERMINAL, "write", { block_id = editor, data = edit_keys(args.paths) })
      if werr ~= nil then
        error(werr, 0)
      end
      rex.session.focus_block({ block_id = editor })
      return
    end

    local anchor = origin
    if not anchor or not foreground(anchor) then
      anchor = blocks[1]
    end
    local fg = anchor and foreground(anchor)
    local nvim_args = { "--" }
    for _, path in ipairs(args.paths) do
      table.insert(nvim_args, path)
    end
    local command = neopane(nvim_args)
    local _, serr = rex.session.new_split({
      anchor_id = anchor,
      direction = "horizontal",
      side = "after",
      focus = true,
      layout = rex.layout.block({
        flavor = SHELL,
        options = { command = command, cwd = fg and fg.cwd or nil },
      }),
    })
    if serr ~= nil then
      error(serr, 0)
    end
  end,
})

----------------------------------------------------------------------------
-- Browser (terminal-browser, https://terminal-browser.com)
----------------------------------------------------------------------------

-- prefix+w toggles a floating browser over the tab. Rex has no browser
-- block yet, so this runs terminal-browser, which draws Chromium with Kitty
-- graphics. Unlike the popups above, hiding it minimizes the layer, so the
-- browser keeps its pages; quitting it (ctrl+q) closes the layer. One per
-- tab, found by its block label. --no-merge keeps it from opening as a tab
-- of another terminal-browser and leaving the layer empty.
local TERMINAL_BROWSER = HOME .. "/.local/bin/terminal-browser"
local BROWSER_LABEL = "Browser"

-- The browser's floating layer in `window`, and its block, or nil.
local function browser_layer(window)
  for _, layer in ipairs(window.layers or {}) do
    local block = layer.kind == "floating" and layer.blocks and layer.blocks[1]
    if block and block.label == BROWSER_LABEL then
      return layer, block
    end
  end
  return nil
end

rex.action({
  name = "browser",
  title = "Toggle Browser",
  category = "Commands",
  keywords = "terminal-browser web browser localhost preview html",
  run = function(ctx)
    local view, err = rex.session.view({})
    if view == nil then
      error(err, 0)
    end
    local window = window_of(view, ctx.block_id)
    if not window then
      error("Browser: the session has no tab", 0)
    end

    local layer, block = browser_layer(window)
    local result
    if not layer then
      local fg = foreground(ctx.block_id)
      result, err = rex.session.new_layer({
        window_id = window.window_id,
        bounds = { 0.05, 0.05, 0.9, 0.9 },
        focus = true,
        layout = rex.layout.block({
          flavor = SHELL,
          label = BROWSER_LABEL,
          options = {
            command = { exists(TERMINAL_BROWSER) and TERMINAL_BROWSER or "terminal-browser", "open", "--no-merge" },
            cwd = fg and fg.cwd or nil,
            login = false,
          },
        }),
      })
    elseif layer.state ~= "minimized" and window.focused_block_id == block.block_id then
      result, err = rex.session.set_layer_state({ layer_id = layer.layer_id, state = "minimized" })
    else
      result, err = rex.session.set_layer_state({ layer_id = layer.layer_id, state = "normal", focus = true })
    end
    if result == nil then
      error(err, 0)
    end
  end,
})
bind_prefixed("w", "browser")

----------------------------------------------------------------------------
-- Worktrees (herdr worktree workspaces, as in Tern's worktrees plugin)
----------------------------------------------------------------------------

-- Each git worktree is its own session, named "<repo>/<branch>". Rex has no
-- prompts or pickers for actions, so ~/.local/bin/rex-worktree asks in a
-- popup over the focused pane, runs git there, then calls worktree_session or
-- worktree_close below through `rex do`.

local function find_session(label)
  local list, err = rex.call("session.list")
  if list == nil then
    error(err, 0)
  end
  for _, session in ipairs(list.sessions) do
    if session.label == label then
      return session
    end
  end
  return nil
end

local worktree_ops = {
  new = { title = "New Worktree…", key = "shift+g" }, -- new_worktree
  open = { title = "Open Worktree…", key = "shift+w" }, -- open_worktree
  remove = { title = "Remove Worktree…", key = "alt+w" }, -- remove_worktree
}

for op, spec in pairs(worktree_ops) do
  rex.action({
    name = "worktree_" .. op,
    title = spec.title,
    category = "Worktrees",
    keywords = "git worktree branch session",
    run = function(ctx)
      local fg = foreground(ctx.block_id)
      local cwd = fg and fg.cwd
      if not cwd or cwd == "" then
        error("Worktrees: focus a terminal inside a git repository", 0)
      end
      -- REX_CLIENT: the script's `rex do` shows the session in this client.
      popup({ "env", "REX_CLIENT=" .. (ctx.client_id or ""), HOME .. "/.local/bin/rex-worktree", op }, cwd)
    end,
  })
  bind_prefixed(spec.key, "worktree_" .. op)
end

-- Shows session `name`, starting it in `path` when there is none.
rex.action({
  name = "worktree_session",
  title = "Show Worktree Session",
  category = "Worktrees",
  args = { name = "string", path = "string" },
  run = function(_, args)
    local session = find_session(args.name)
    local id = session and session.session_id
    if not id then
      local created, err = rex.call("session.create", {
        label = args.name,
        initial_windows = {
          { layout = rex.layout.block({ flavor = SHELL, options = { cwd = args.path } }) },
        },
      })
      if created == nil then
        error(err, 0)
      end
      id = created.session_id
    end
    rex.client.queue("session.select", { session_id = id })
  end,
})

-- Closes session `name`, if there is one.
rex.action({
  name = "worktree_close",
  title = "Close Worktree Session",
  category = "Worktrees",
  args = { name = "string" },
  run = function(_, args)
    local session = find_session(args.name)
    if session then
      -- The server only destroys a session this connection is attached to.
      local id = session.session_id
      local _, err = rex.call("session.attach", { session_id = id })
      if err == nil then
        _, err = rex.call("session.destroy", { session_id = id })
      end
      if err ~= nil then
        error(err, 0)
      end
    end
  end,
})

----------------------------------------------------------------------------
-- Plannotator (herdr-annotate's document review)
----------------------------------------------------------------------------

-- plannotator-tui's review in a popup over the focused pane, sending the
-- feedback to the agent there (else to the clipboard), as herdr-annotate's
-- annotate.* actions do in Herdr. ~/.local/bin/rex-plannotator runs
-- plannotator-tui's Herdr pane and stands in for herdr behind it.
local PLANNOTATOR = HOME .. "/.local/bin/rex-plannotator"

-- Opens `command` in a popup in `cwd`. Agents reach it through
-- `rex-plannotator open`.
rex.action({
  name = "plannotator_popup",
  title = "Plannotator Review Popup",
  category = "Plannotator",
  args = { command = "array", cwd = "string?" },
  run = function(_, args)
    popup(args.command, args.cwd ~= "" and args.cwd or nil)
  end,
})

local annotate_actions = {
  { name = "open", title = "Review Documents in This Folder", key = "o" },
  { name = "last", title = "Review the Agent's Last Reply", key = "shift+o", flags = { "--last" } },
  { name = "last_newest", title = "Review the Agent's Newest Reply", key = "ctrl+o", flags = { "--newest" } },
  -- No keys, as in herdr-annotate.
  { name = "gate", title = "Review Documents Here, with Approve", flags = { "--gate" } },
  { name = "terminal", title = "Review This Pane's Recent Output", flags = { "--terminal" } },
}

for _, spec in ipairs(annotate_actions) do
  local name = "annotate_" .. spec.name
  rex.action({
    name = name,
    title = spec.title,
    category = "Plannotator",
    keywords = "plannotator annotate review feedback markdown plan agent",
    run = function(ctx)
      if not ctx.block_id then
        error("Plannotator: focus a terminal first", 0)
      end
      local fg = foreground(ctx.block_id)
      local command = { PLANNOTATOR, "review", "--target", ctx.block_id }
      for _, flag in ipairs(spec.flags or {}) do
        table.insert(command, flag)
      end
      popup(command, fg and fg.cwd or nil)
    end,
  })
  if spec.key then
    bind_prefixed(spec.key, name)
  end
end

----------------------------------------------------------------------------
-- Vim navigation (vim-herdr-navigation)
----------------------------------------------------------------------------

-- ctrl+h/j/k/l moves between panes. neopane's windows are Rex panes, so Rex
-- moves between them itself. When a plain Vim is in the foreground the key
-- goes to Vim instead, which moves between its own splits and, at an edge,
-- calls `rex focus` to cross into the next pane
-- (dot_config/nvim/lua/plugins/util.lua).
-- Nested multiplexers get the key too, so they navigate their own panes.
local passthrough = { herdr = true, tmux = true, zellij = true }

-- Same matcher as vim-tmux-navigator: ^g?(view|l?n?vim?x?)(diff)?$
local function wants_nav_keys(name)
  name = name:lower()
  if passthrough[name] then
    return true
  end
  name = name:gsub("^g", ""):gsub("diff$", "")
  return name == "view" or name:match("^l?n?vim?x?$") ~= nil
end

local nav_keys = { left = "ctrl+h", down = "ctrl+j", up = "ctrl+k", right = "ctrl+l" }

rex.action({
  name = "navigate",
  title = "Navigate (Vim-aware)",
  category = "Pane",
  args = { direction = "string" },
  repeats = true,
  run = function(ctx, args)
    local key = nav_keys[args.direction]
    if not key then
      error("direction must be left, down, up, or right", 0)
    end
    local fg = foreground(ctx.block_id)
    if fg and wants_nav_keys(fg.name) then
      rex.client.queue("pane.send_key", { key = key })
    else
      rex.client.queue("pane.focus", { direction = args.direction, wrap = false })
    end
  end,
})

for direction, key in pairs(nav_keys) do
  rex.bind(key, "navigate", { direction = direction })
end

----------------------------------------------------------------------------
-- Theme
----------------------------------------------------------------------------

-- Imports the current theme variant's Ghostty colors and selects them, for
-- the variant's mode. set-theme runs this through `rex do sync_theme`, which
-- needs Remote Control on in Rex's Settings under Rex Server.
-- Rex names an imported theme after its file, so each variant is staged as a
-- file named for the variant.
rex.action({
  name = "sync_theme",
  title = "Sync Theme with ~/.config/theme",
  category = "Appearance",
  keywords = "theme colors ghostty set-theme variant",
  run = function()
    local link = HOME .. "/.config/theme"
    local target, err = rex.exec({ "readlink", link })
    if target == nil then
      error(err, 0)
    end
    if not target.ok then
      error("no current theme: " .. link .. " is not a link", 0)
    end
    local variant = trim(target.stdout):match("([^/]+)/?$")

    local source = io.open(link .. "/ghostty.conf", "r")
    if not source then
      error(variant .. " has no ghostty.conf", 0)
    end
    local colors = source:read("*a")
    source:close()

    local dir = HOME .. "/.cache/rex/themes"
    rex.exec({ "mkdir", "-p", dir })
    local path = dir .. "/" .. variant
    local staged = assert(io.open(path, "w"))
    staged:write(colors)
    staged:close()

    local light = io.open(link .. "/light.mode", "r")
    if light then
      light:close()
    end
    rex.client.queue("client.appearance.switch_mode", { mode = light and "light" or "dark" })
    rex.client.queue("client.theme.import", { path = path })
  end,
})
