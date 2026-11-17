local Config = require('sidekick.config')
local Mux = require('config.sidekick_mux')
local Procs = require('sidekick.cli.procs')
local Util = require('sidekick.util')
local bit = require('bit')

-- Agents running in terminals of the Herdr desktop app, which herdr-core runs
-- (CLI `hc`). `hc get` reports each terminal's program, so agents are found the
-- way the tmux backend finds them: walking that program's process tree with
-- each tool's `is_proc`.
--
-- `hc send` always presses Enter, and `hc keys` only presses named keys, so
-- text goes in as raw input instead: a framed `hc connect` connection attaches
-- to the terminal (`terminal.attach`, at its current size, so nothing resizes)
-- and writes the bytes as DATA frames, as a viewer typing would. The attach's
-- first paint replays the terminal's modes, which tell whether the program
-- wants bracketed paste and how its keyboard protocol encodes Enter. See
-- https://github.com/herdrdev/herdr-core/blob/master/schema/README.md.

---@class sidekick.cli.muxer.HerdrApp: sidekick.cli.Session
---@field hc_terminal string
local M = {}
M.__index = M
M.external = true
M.priority = 50

local TIMEOUT = 2000

-- Framed mode: `[channel u32 LE][kind u8][len u32 LE][payload]`.
local DATA, CLOSE = 0, 2

---@param n integer
local function u32(n)
  return string.char(bit.band(n, 0xff), bit.band(bit.rshift(n, 8), 0xff), bit.band(bit.rshift(n, 16), 0xff), bit.band(bit.rshift(n, 24), 0xff))
end

---@param s string
---@param i integer
local function read_u32(s, i)
  local a, b, c, d = s:byte(i, i + 3)
  return a + b * 0x100 + c * 0x10000 + d * 0x1000000
end

---@param channel integer
---@param kind integer
---@param payload string
local function frame(channel, kind, payload)
  return u32(channel) .. string.char(kind) .. u32(#payload) .. payload
end

---@param id integer
---@param method string
---@param params table
local function rpc(id, method, params)
  return vim.json.encode({ jsonrpc = '2.0', id = id, method = method, params = params })
end

---@class sidekick.cli.muxer.HerdrApp.Modes
---@field bracketed_paste boolean
---@field kitty_flags integer

--- The modes a first paint leaves set: it resets them all, then sets the
--- program's, and ends with `CSI ?9001h|l`.
---@param paint string
---@return sidekick.cli.muxer.HerdrApp.Modes
local function modes(paint)
  local ret = { bracketed_paste = false, kitty_flags = 0 }
  for set in paint:gmatch('\27%[%?2004([hl])') do
    ret.bracketed_paste = set == 'h'
  end
  for flags in paint:gmatch('\27%[=(%d+);?%d*u') do
    ret.kitty_flags = tonumber(flags) or 0
  end
  return ret
end

--- Attach to `terminal` and write `input(modes)` as raw input. False when the
--- terminal can't be attached in time.
---@param terminal string
---@param input fun(modes: sidekick.cli.muxer.HerdrApp.Modes): string
---@return boolean
local function write(terminal, input)
  local buf, framed, done = '', false, false
  local replies = {} ---@type table<integer, table>
  -- Stream output by channel: it can arrive in the same read as the attach
  -- reply, before the channel is known.
  local output = {} ---@type table<integer, string>
  local closed = {} ---@type table<integer, boolean>

  local job ---@type vim.SystemObj
  local ok = pcall(function()
    job = vim.system({ 'hc', 'connect' }, {
      stdin = true,
      stdout = function(_, data)
        if not data then
          done = true
          return
        end
        buf = buf .. data
        if not framed then
          -- The hello reply is a plain line; the connection is framed after it.
          local nl = buf:find('\n', 1, true)
          if not nl then
            return
          end
          buf, framed = buf:sub(nl + 1), true
        end
        while #buf >= 9 do
          local len = read_u32(buf, 6)
          if #buf < 9 + len then
            break
          end
          local ch, kind, payload = read_u32(buf, 1), buf:byte(5), buf:sub(10, 9 + len)
          buf = buf:sub(10 + len)
          if ch == 0 and kind == DATA then
            local decoded, msg = pcall(vim.json.decode, payload)
            if decoded and type(msg) == 'table' and msg.id then
              replies[msg.id] = msg
            end
          elseif kind == DATA then
            output[ch] = (output[ch] or '') .. payload
          elseif kind == CLOSE then
            closed[ch] = true
          end
        end
      end,
    })
  end)
  if not ok then
    return false
  end

  local function wait(cond)
    vim.wait(TIMEOUT, function()
      return done or cond()
    end, 5)
    return cond()
  end

  local function finish(result)
    pcall(job.write, job, nil)
    job:wait(200) -- kills it on timeout
    return result
  end

  job:write(rpc(1, 'hello', { generation = 1, framed = true }) .. '\n')
  if not wait(function()
    return framed
  end) then
    return finish(false)
  end

  job:write(frame(0, DATA, rpc(2, 'terminal.get', { terminal = terminal })))
  if not wait(function()
    return replies[2] ~= nil
  end) then
    return finish(false)
  end
  local facts = replies[2].result
  if type(facts) ~= 'table' or facts.state ~= 'live' then
    return finish(false)
  end

  job:write(frame(0, DATA, rpc(3, 'terminal.attach', { terminal = terminal, cols = facts.cols, rows = facts.rows, caller = vim.env.HC_TERMINAL_ID })))
  if not wait(function()
    return replies[3] ~= nil
  end) then
    return finish(false)
  end
  local channel = replies[3].result and replies[3].result.channel
  if type(channel) ~= 'number' or not wait(function()
    return (output[channel] or ''):find('\27%[%?9001[hl]') ~= nil
  end) then
    return finish(false)
  end

  job:write(frame(channel, DATA, input(modes(output[channel]))))
  -- The core answers CLOSE with CLOSE once the input is in.
  job:write(frame(channel, CLOSE, ''))
  return finish(wait(function()
    return closed[channel] == true
  end))
end

---@return table<string, string> space name by id, from the Herdr app
local function spaces()
  local ret = {}
  local ls = Mux.exec_json({ 'herdr-app', 'ls' })
  for _, space in ipairs(ls and ls.spaces or {}) do
    if type(space.id) == 'string' and type(space.name) == 'string' then
      ret[space.id] = space.name
    end
  end
  return ret
end

---@param report table `hc get` of a terminal
local function program(report)
  return { child = { pid = report.pid }, foreground = report.foreground }
end

function M:is_running()
  local found = Mux.programs({ [self.hc_terminal] = { 'hc', 'get', self.hc_terminal, '--json' } }, program)[self.hc_terminal]
  return found ~= nil and Mux.find_tool(self.tool, found.pid, Procs.new()) ~= nil
end

---@return sidekick.cli.session.State[]
function M.sessions()
  local list = Mux.exec_json({ 'hc', 'ls', '--json' })
  local cmds = {}
  for _, terminal in ipairs(list and list.terminals or {}) do
    -- Terminals on other machines (`machine/t7`) have no local process tree.
    if type(terminal.address) == 'string' and not terminal.address:find('/', 1, true) then
      cmds[terminal.address] = { 'hc', 'get', terminal.address, '--json' }
    end
  end
  local programs = Mux.programs(cmds, program)
  if vim.tbl_isempty(programs) then
    return {}
  end
  local names = spaces()
  local procs = Procs.new()
  local tools = Config.tools()

  local sessions = {} ---@type sidekick.cli.session.State[]
  for address, found in pairs(programs) do
    for _, tool in pairs(tools) do
      if Mux.find_tool(tool, found.pid, procs) then
        local labels = type(found.report.labels) == 'table' and found.report.labels or {}
        local where = type(labels.where) == 'string' and labels.where:match('^(.-) / ') or nil
        sessions[#sessions + 1] = {
          id = 'hc:' .. address,
          cwd = found.cwd or found.report.cwd or vim.fn.getcwd(),
          tool = tool,
          hc_terminal = address,
          mux_session = names[labels['herdr.space']] or where or address,
          pids = Procs.pids(found.pid),
        }
        break
      end
    end
  end
  return sessions
end

-- Bracketed paste when the program asks for it, so multi-line text doesn't
-- submit early.
function M:send(text)
  local ok = write(self.hc_terminal, function(mode)
    if mode.bracketed_paste then
      return '\27[200~' .. text:gsub('\27%[201~', '') .. '\27[201~'
    end
    return text
  end)
  if not ok then
    Util.warn(('Could not type into Herdr app terminal `%s`'):format(self.hc_terminal))
  end
end

-- Enter as the program's keyboard protocol encodes it: `CSI 13 u` when it asks
-- for every key as an escape code (kitty flag 8). `hc keys` encodes it too but
-- waits for ~3 s of quiet first, so it is only the fallback.
function M:submit()
  local ok = write(self.hc_terminal, function(mode)
    return bit.band(mode.kitty_flags, 8) ~= 0 and '\27[13u' or '\r'
  end)
  if not ok then
    Util.exec({ 'hc', 'keys', self.hc_terminal, 'enter' })
  end
end

function M:dump()
  local _, stdout = Util.exec({ 'hc', 'read', self.hc_terminal, '--lines', tostring(Config.cli.mux.dump) })
  return Mux.tail(stdout)
end

return M
