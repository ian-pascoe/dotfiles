-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Search the Neovim config in its chezmoi source: `chezmoi apply` overwrites edits to ~/.config/nvim.
vim.keymap.set('n', '<leader>sN', function()
  local source = vim.fs.joinpath(vim.uv.os_homedir(), '.local', 'share', 'chezmoi', 'dot_config', 'nvim')
  local cwd = vim.fn.isdirectory(source) == 1 and source or vim.fn.stdpath('config')
  require('config.fff_picker').files({ cwd = cwd })
end, { desc = 'Neovim config' })

-- On Windows (and WSL) GlazeWM takes LazyVim's <A-j>/<A-k>; move the selection
-- with J/K there instead. Join and keyword lookup stay on J/K in Normal mode.
if vim.fn.has('win32') == 1 or vim.fn.has('wsl') == 1 then
  vim.keymap.set('x', 'J', ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = 'Move Down', silent = true })
  vim.keymap.set('x', 'K', ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = 'Move Up', silent = true })
end

-- No autcmd write
vim.keymap.set('n', '<leader>W', '<cmd>noautocmd write<cr>', { desc = 'No autocmd write' })

-- The Herdr app's file viewer (its open-in-neopane mod) lists the files yazi
-- chose in ~/.cache/herdr-app/neopane-edit.json, then presses <C-M-F12> in a
-- neopane pane: hc can't type ':' into a terminal.
if vim.env.HC_TERMINAL_ID then
  vim.keymap.set('n', '<C-M-F12>', function()
    local path = vim.fs.joinpath(vim.uv.os_homedir(), '.cache', 'herdr-app', 'neopane-edit.json')
    local file = io.open(path)
    if not file then
      return
    end
    local ok, paths = pcall(vim.json.decode, file:read('*a'))
    file:close()
    os.remove(path)
    for _, p in ipairs(ok and type(paths) == 'table' and paths or {}) do
      vim.cmd.edit(vim.fn.fnameescape(p))
    end
  end, { desc = 'Open files the Herdr app chose' })
end

-- Herdr annotate
if vim.env.HERDR_ENV == '1' then
  vim.keymap.set('x', '<leader>aa', function()
    vim.cmd('normal! "+y')
    vim.fn.jobstart({
      'herdr',
      'plugin',
      'action',
      'invoke',
      'annotate.capture',
    })
  end, { desc = 'Annotate in Herdr' })
end
