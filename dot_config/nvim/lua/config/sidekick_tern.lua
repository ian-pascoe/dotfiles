local Config = require('sidekick.config')
local Mux = require('config.sidekick_mux')
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

---@return { id: string, cwd: string, session: string }[]
local function panes()
  local inspect = Mux.exec_json({ 'tern', 'inspect', '--json' })
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

---@param id string
local function process_cmd(id)
  return { 'tern', 'process', id, '--json' }
end

function M:is_running()
  local id = self.tern_pane_id
  local shell = Mux.programs({ [id] = process_cmd(id) })[id]
  return shell ~= nil and Mux.find_tool(self.tool, shell.pid, Procs.new()) ~= nil
end

---@return sidekick.cli.session.State[]
function M.sessions()
  local list = panes()
  local cmds = {}
  for _, pane in ipairs(list) do
    cmds[pane.id] = process_cmd(pane.id)
  end
  local pids = Mux.programs(cmds)
  local procs = Procs.new()
  local tools = Config.tools()

  local sessions = {} ---@type sidekick.cli.session.State[]
  for _, pane in ipairs(list) do
    local shell = pids[pane.id]
    if shell then
      for _, tool in pairs(tools) do
        if Mux.find_tool(tool, shell.pid, procs) then
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
  return Mux.tail(stdout)
end

return M
