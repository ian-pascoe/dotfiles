-- Helpers shared by the sidekick session backends for Herdr, Herdr app, Tern
-- and Rex.

local Config = require('sidekick.config')
local Util = require('sidekick.util')

local M = {}

--- Run `cmd` and decode its stdout as a JSON object; nil on any failure.
---@param cmd string[]
---@return table?
function M.exec_json(cmd)
  local _, stdout = Util.exec(cmd, { notify = false })
  if not stdout then
    return
  end
  local ok, value = pcall(vim.json.decode, stdout)
  if ok and type(value) == 'table' then
    return value
  end
end

--- Run each pane's process command in parallel. Each prints a JSON report
--- with the pane's `child` program and its `foreground` program; return the
--- child's pid and the foreground's cwd (sparing sidekick's per-process lsof).
--- `adapt` maps a report of another shape to `{ child, foreground }`; each
--- result keeps the decoded report as `report`.
---@param cmds table<string, string[]> process command by pane id
---@param adapt? fun(report: table): { child: table?, foreground: table? }?
---@return table<string, { pid: integer, cwd: string?, report: table }>
function M.programs(cmds, adapt)
  local jobs = {}
  for id, cmd in pairs(cmds) do
    jobs[id] = vim.system(cmd, { text = true })
  end
  local ret = {}
  for id, job in pairs(jobs) do
    local result = job:wait(2000)
    local ok, report = pcall(vim.json.decode, result.stdout or '')
    local info = ok and type(report) == 'table' and (adapt and adapt(report) or report) or nil
    if result.code == 0 and type(info) == 'table' and type(info.child) == 'table' and type(info.child.pid) == 'number' then
      local front = type(info.foreground) == 'table' and info.foreground or info.child
      ret[id] = { pid = info.child.pid, cwd = type(front.cwd) == 'string' and front.cwd or nil, report = report }
    end
  end
  return ret
end

--- The first process under `pid` that is `tool`, as the tmux backend finds it.
---@param tool sidekick.cli.Tool
---@param pid integer
---@param procs sidekick.cli.Procs
---@return sidekick.cli.Proc?
function M.find_tool(tool, pid, procs)
  local found
  procs:walk(pid, function(proc)
    if tool:is_proc(proc) then
      found = proc
      return true
    end
  end)
  return found
end

--- The last `cli.mux.dump` lines of `text`.
---@param text string?
---@return string?
function M.tail(text)
  if not text then
    return
  end
  local lines = vim.split(text, '\n', { plain = true })
  return table.concat(lines, '\n', math.max(1, #lines - Config.cli.mux.dump + 1))
end

return M
