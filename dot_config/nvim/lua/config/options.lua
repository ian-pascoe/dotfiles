-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- enable prettier only if a config file is present in the project
vim.g.lazyvim_prettier_needs_config = true

-- Tern's remote panes come from its daemon, not sshd, so they have no
-- SSH_CONNECTION; their identity chain names how the user reached the host.
local function in_remote_tern_pane()
  local ok, identity = pcall(vim.json.decode, vim.env.TERN_IDENTITY or '')
  if not ok or type(identity) ~= 'table' or type(identity.hops) ~= 'table' then
    return false
  end
  for _, hop in ipairs(identity.hops) do
    if hop.method ~= 'local' then
      return true
    end
  end
  return false
end

local remote_tern = in_remote_tern_pane()

if vim.env.SSH_CONNECTION or remote_tern then
  vim.o.clipboard = 'unnamedplus'

  -- Herdr and Tern relay OSC 52 copies but never answer reads.
  if vim.env.HERDR_ENV == '1' or remote_tern then
    local function paste_from_unnamed_register()
      return { vim.fn.getreg('"', 1, true), vim.fn.getregtype('"') }
    end

    local osc52 = require('vim.ui.clipboard.osc52')
    vim.g.clipboard = {
      name = 'OSC 52 (copy only)',
      copy = {
        ['+'] = osc52.copy('+'),
        ['*'] = osc52.copy('*'),
      },
      -- Unanswered OSC 52 read requests time out, which causes a 10-second wait.
      paste = {
        ['+'] = paste_from_unnamed_register,
        ['*'] = paste_from_unnamed_register,
      },
    }
  else
    vim.g.clipboard = 'osc52'
  end
end

-- use pwsh as terminal on windows
if LazyVim.is_win() then
  if vim.fn.executable('pwsh') == 1 then
    vim.opt.shell = 'pwsh'
  else
    vim.opt.shell = 'powershell'
  end

  vim.opt.shellcmdflag =
    '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;'
  vim.opt.shellredir = '-RedirectStandardOutput %s -NoNewWindow -Wait'
  vim.opt.shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
  vim.opt.shellquote = ''
  vim.opt.shellxquote = ''
end

-- enable line wrap
vim.opt.wrap = true

-- change listchars
vim.opt.listchars = {
  tab = '→ ',
  extends = '»',
  precedes = '«',
  trail = '·',
  nbsp = '␣',
}
