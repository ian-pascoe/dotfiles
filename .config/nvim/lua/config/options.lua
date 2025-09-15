-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- use blink.cmp for ai completions
vim.g.ai_cmp = true

if LazyVim.is_win() then
  LazyVim.terminal.setup("powershell") -- I use nushell on Windows
end

-- enable line wrap
vim.opt.wrap = true

-- change listchars
vim.opt.listchars = {
  tab = "→ ",
  extends = "»",
  precedes = "«",
  trail = "·",
  nbsp = "␣",
}
