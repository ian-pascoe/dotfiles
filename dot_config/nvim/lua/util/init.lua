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

-- 'light' when the current theme has a light.mode marker, else 'dark'.
function M.get_background()
  local marker = vim.fs.joinpath(M.theme_dir(), 'theme', 'light.mode')
  return vim.uv.fs_stat(marker) and 'light' or 'dark'
end

return M
