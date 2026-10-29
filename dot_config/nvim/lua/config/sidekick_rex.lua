local Config = require('sidekick.config')
local Procs = require('sidekick.cli.procs')
local Util = require('sidekick.util')

-- Agents running in Rex terminals. Rex reports each terminal's program
-- (`rex block call ... process`), so agents are found the way the tmux backend
-- finds them: walking that program's process tree with each tool's `is_proc`.

---@class sidekick.cli.muxer.Rex: sidekick.cli.Session
---@field rex_session_id string
---@field rex_block_id string
local M = {}
M.__index = M
M.external = true
M.priority = 50

local TERMINAL = 'com.superlogical.terminal'

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

---@return { session_id: string, block_id: string, session: string }[]
local function blocks()
  local ret = {}
  local list = exec_json({ 'rex', 'ls', '--json' })
  for _, session in ipairs(list and list.sessions or {}) do
    local ls = exec_json({ 'rex', 'block', 'ls', '-s', session.session_id, '--json' })
    for _, block in ipairs(ls and ls.blocks or {}) do
      if block.creator_name == TERMINAL then
        ret[#ret + 1] = { session_id = session.session_id, block_id = block.block_id, session = session.label }
      end
    end
  end
  return ret
end

---@param block { session_id: string, block_id: string }
---@param method string
---@param args? table
local function call(block, method, args)
  return { 'rex', 'block', 'call', '-s', block.session_id, '-b', block.block_id, method, args and vim.json.encode(args) or '{}' }
end

-- Each terminal's program pid and its foreground program's cwd (sparing
-- sidekick's per-process lsof); the `process` calls run in parallel.
---@param list { session_id: string, block_id: string }[]
---@return table<string, { pid: integer, cwd: string? }>
local function programs(list)
  local jobs = {}
  for _, block in ipairs(list) do
    jobs[block.block_id] = vim.system(call(block, 'process'), { text = true })
  end
  local ret = {}
  for id, job in pairs(jobs) do
    local result = job:wait(2000)
    local ok, info = pcall(vim.json.decode, result.stdout or '')
    if result.code == 0 and ok and type(info) == 'table' and type(info.child) == 'table' then
      local front = type(info.foreground) == 'table' and info.foreground or info.child
      ret[id] = { pid = info.child.pid, cwd = type(front.cwd) == 'string' and front.cwd or nil }
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

---@return { session_id: string, block_id: string }
function M:block()
  return { session_id = self.rex_session_id, block_id = self.rex_block_id }
end

function M:is_running()
  local program = programs({ self:block() })[self.rex_block_id]
  return program ~= nil and find_tool(self.tool, program.pid, Procs.new()) ~= nil
end

---@return sidekick.cli.session.State[]
function M.sessions()
  local list = blocks()
  local pids = programs(list)
  local procs = Procs.new()
  local tools = Config.tools()

  local sessions = {} ---@type sidekick.cli.session.State[]
  for _, block in ipairs(list) do
    local program = pids[block.block_id]
    if program then
      for _, tool in pairs(tools) do
        if find_tool(tool, program.pid, procs) then
          sessions[#sessions + 1] = {
            id = 'rex:' .. block.block_id,
            cwd = program.cwd or vim.fn.getcwd(),
            tool = tool,
            rex_session_id = block.session_id,
            rex_block_id = block.block_id,
            mux_session = block.session,
            pids = Procs.pids(program.pid),
          }
          break
        end
      end
    end
  end
  return sessions
end

---@return boolean
function M:bracketed_paste()
  local modes = exec_json(call(self:block(), 'modes'))
  for _, mode in ipairs(modes and modes.modes or {}) do
    if mode.name == 'bracketed_paste' then
      return mode.set == true
    end
  end
  return false
end

-- Bracketed paste when the program asks for it, so multi-line text doesn't
-- submit early.
function M:send(text)
  if self:bracketed_paste() then
    text = '\27[200~' .. text .. '\27[201~'
  end
  Util.exec(call(self:block(), 'write', { data = text }))
end

function M:submit()
  Util.exec({ 'rex', 'send-key', '-s', self.rex_session_id, '-b', self.rex_block_id, 'enter' })
end

function M:dump()
  local _, stdout = Util.exec({ 'rex', 'capture', '-s', self.rex_session_id, '-b', self.rex_block_id, '--format', 'vt', '--trim' })
  if not stdout then
    return
  end
  local lines = vim.split(stdout, '\n', { plain = true })
  return table.concat(lines, '\n', math.max(1, #lines - Config.cli.mux.dump + 1))
end

return M
