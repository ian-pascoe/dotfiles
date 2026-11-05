-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Add keymap to search neovim config files
vim.keymap.set('n', '<leader>sN', LazyVim.pick('files', { cwd = vim.fn.stdpath('config') }), { desc = 'Neovim config' })

-- Move the selection with J/K: AeroSpace takes LazyVim's <A-j>/<A-k> system-wide.
-- Same commands as LazyVim's; join and keyword lookup stay on J/K in Normal mode.
vim.keymap.set('x', 'J', ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = 'Move Down', silent = true })
vim.keymap.set('x', 'K', ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = 'Move Up', silent = true })

-- No autcmd write
vim.keymap.set('n', '<leader>W', '<cmd>noautocmd write<cr>', { desc = 'No autocmd write' })

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
