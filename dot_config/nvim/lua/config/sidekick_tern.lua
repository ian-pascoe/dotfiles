local Config = require('sidekick.config')
local Procs = require('sidekick.cli.procs')
local Util = require('sidekick.util')

-- Agents running in Tern panes. Tern's CLI reports each pane's shell
-- (`tern process`), so agents are found the way the tmux backend finds them:
-- walking the shell's process tree with each tool's `is_proc`.

---@class sidekick.cli.muxer.Tern: sidekick.cli.Session
---@field tern_pane_id string
local M = {}
M.__index = M
M.external = true
M.priority = 50

---@param cmd string[]
---@return table?
local function exec_json(cmd)
  local _, stdout = Util.exec(cmd, { notify = false })
  if not stdout then
    return
  end
  local ok, value = pcall(vim.json.decode, stdout)
  if ok and type(value) == 'table' then
    return value
  end
end

---@return { id: string, cwd: string, session: string }[]
local function panes()
  local inspect = exec_json({ 'tern', 'inspect', '--json' })
  local ret = {}
  for _, session in ipairs(inspect and inspect.sessions or {}) do
    for _, tab in ipairs(session.tabs or {}) do
      for _, block in ipairs(tab.blocks or {}) do
        if block.live and block.exited == vim.NIL and type(block.id) == 'number' then
          ret[#ret + 1] = { id = string.format('%d', block.id), cwd = block.cwd, session = session.name }
        end
      end
    end
  end
  return ret
end

-- Each pane's shell pid and its foreground program's cwd (sparing sidekick's
-- per-process lsof); the `tern process` calls run in parallel.
---@param list { id: string }[]
---@return table<string, { pid: integer, cwd: string? }>
local function shell_pids(list)
  local jobs = {}
  for _, pane in ipairs(list) do
    jobs[pane.id] = vim.system({ 'tern', 'process', pane.id, '--json' }, { text = true })
  end
  local ret = {}
  for id, job in pairs(jobs) do
    local result = job:wait(2000)
    local ok, info = pcall(vim.json.decode, result.stdout or '')
    if result.code == 0 and ok and type(info) == 'table' and type(info.child) == 'table' then
      local front = type(info.foreground) == 'table' and info.foreground or info.child
      ret[id] = { pid = info.child.pid, cwd = front.cwd }
    end
  end
  return ret
end

---@param tool sidekick.cli.Tool
---@param pid integer
---@param procs sidekick.cli.Procs
---@return sidekick.cli.Proc?
local function find_tool(tool, pid, procs)
  local found
  procs:walk(pid, function(proc)
    if tool:is_proc(proc) then
      found = proc
      return true
    end
  end)
  return found
end

function M:is_running()
  local shell = shell_pids({ { id = self.tern_pane_id } })[self.tern_pane_id]
  return shell ~= nil and find_tool(self.tool, shell.pid, Procs.new()) ~= nil
end

---@return sidekick.cli.session.State[]
function M.sessions()
  local list = panes()
  local pids = shell_pids(list)
  local procs = Procs.new()
  local tools = Config.tools()

  local sessions = {} ---@type sidekick.cli.session.State[]
  for _, pane in ipairs(list) do
    local shell = pids[pane.id]
    if shell then
      for _, tool in pairs(tools) do
        if find_tool(tool, shell.pid, procs) then
          sessions[#sessions + 1] = {
            id = 'tern:' .. pane.id,
            cwd = shell.cwd or pane.cwd,
            tool = tool,
            tern_pane_id = pane.id,
            mux_session = pane.session,
            pids = Procs.pids(shell.pid),
          }
          break
        end
      end
    end
  end
  return sessions
end

-- Bracketed paste, so multi-line text doesn't submit early.
function M:send(text)
  Util.exec({ 'tern', 'send', self.tern_pane_id, 'paste', text })
end

function M:submit()
  Util.exec({ 'tern', 'send', self.tern_pane_id, 'keys', 'enter' })
end

function M:dump()
  local _, stdout = Util.exec({ 'tern', 'capture', self.tern_pane_id, '--ansi', '--scrollback' })
  if not stdout then
    return
  end
  local lines = vim.split(stdout, '\n', { plain = true })
  return table.concat(lines, '\n', math.max(1, #lines - Config.cli.mux.dump + 1))
end

return M
