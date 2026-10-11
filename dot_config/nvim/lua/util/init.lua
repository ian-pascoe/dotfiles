---@class util
local M = {}

function M.is_win()
  return vim.uv.os_uname().sysname:find('Windows') ~= nil
end

-- Directory holding the `theme` link to the current ~/.themes entry.
function M.theme_dir()
  return vim.env.XDG_CONFIG_HOME or vim.fs.joinpath(vim.env.HOME, '.config')
end

function M.get_theme()
  local theme = 'rose-pine'
  local target = vim.uv.fs_readlink(vim.fs.joinpath(M.theme_dir(), 'theme'))
  if not target then
    return theme
  end

  theme = vim.fn.fnamemodify(target, ':t')
  return theme
end

return M
