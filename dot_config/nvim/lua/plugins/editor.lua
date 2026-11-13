-- AeroSpace takes alt+a/d/f/h/i/m/p/r/s/t system-wide (aerospace.toml), so the
-- picker's keys on them (Snacks' and LazyVim extras') never arrive. Move them
-- to Alt keys AeroSpace leaves free, and drop the dead defaults.
local picker_alt_moves = {
  { '<a-a>', '<a-b>', 'sidekick_send' },
  { '<a-s>', "<a-'>", 'flash' }, -- ' jumps to a mark
  { '<a-t>', '<a-q>', 'trouble_open' }, -- a quickfix-style list
  { '<a-d>', '<a-n>', 'inspect' },
  { '<a-f>', '<a-y>', 'toggle_follow' },
  { '<a-h>', '<a-.>', 'toggle_hidden' }, -- dotfiles
  { '<a-i>', '<a-g>', 'toggle_ignored' }, -- gitignored
  { '<a-m>', '<a-z>', 'toggle_maximize' }, -- zoom
  { '<a-p>', '<a-e>', 'toggle_preview' }, -- eye
  { '<a-r>', '<a-x>', 'toggle_regex' },
}

-- The picker window's keys for those moves; `spec` adds options such as mode.
local function picker_alt_keys(spec)
  local keys = {}
  for _, move in ipairs(picker_alt_moves) do
    keys[move[1]] = false
    keys[move[2]] = vim.tbl_extend('force', { move[3] }, spec or {})
  end
  return keys
end

-- Obsidian vaults under ~/vaults that exist on this machine.
local function get_vaults()
  local root = vim.fs.joinpath(vim.uv.os_homedir(), 'vaults')
  local workspaces = {}
  for _, name in ipairs({ 'personal', 'family', 'work' }) do
    local path = vim.fs.joinpath(root, name)
    if vim.fn.isdirectory(path) == 1 then
      workspaces[#workspaces + 1] = { name = name, path = path }
    end
  end
  return workspaces
end

local vault_workspaces = get_vaults()

return {
  { -- fff: file/grep backend for the Snacks picker (see config/fff_picker.lua)
    'dmtrKovalenko/fff',
    build = function()
      require('fff.download').download_or_build_binary()
    end,
    lazy = false, -- fff initialises itself lazily
    init = function()
      -- fff logs at info by default; one session grew its log to 4 GB.
      vim.g.fff = { logging = { enabled = false } }
    end,
  },
  {
    'folke/snacks.nvim',
    dependencies = { 'dmtrKovalenko/fff' },
    ---@module "snacks"
    ---@type snacks.Config
    opts = {
      explorer = {
        enabled = false, -- disable built-in file explorer
      },
      picker = {
        sources = { -- show hidden files in pickers
          files = { hidden = true },
          grep = { hidden = true },
          explorer = { hidden = true },
        },
        win = {
          input = { keys = picker_alt_keys({ mode = { 'n', 'i' } }) },
          list = { keys = picker_alt_keys() },
        },
      },
    },
    keys = {
      -- fff-backed replacements for LazyVim's file/grep pickers
      {
        '<leader><space>',
        function()
          require('config.fff_picker').files({ cwd = LazyVim.root() })
        end,
        desc = 'Find Files (Root Dir)',
      },
      {
        '<leader>ff',
        function()
          require('config.fff_picker').files({ cwd = LazyVim.root() })
        end,
        desc = 'Find Files (Root Dir)',
      },
      {
        '<leader>fF',
        function()
          require('config.fff_picker').files()
        end,
        desc = 'Find Files (cwd)',
      },
      {
        '<leader>/',
        function()
          require('config.fff_picker').grep({ cwd = LazyVim.root() })
        end,
        desc = 'Grep (Root Dir)',
      },
      {
        '<leader>sg',
        function()
          require('config.fff_picker').grep({ cwd = LazyVim.root() })
        end,
        desc = 'Grep (Root Dir)',
      },
      {
        '<leader>sG',
        function()
          require('config.fff_picker').grep()
        end,
        desc = 'Grep (cwd)',
      },
      {
        '<leader>sw',
        function()
          require('config.fff_picker').grep_word({ cwd = LazyVim.root() })
        end,
        mode = { 'n', 'x' },
        desc = 'Visual selection or word (Root Dir)',
      },
      {
        '<leader>sW',
        function()
          require('config.fff_picker').grep_word()
        end,
        mode = { 'n', 'x' },
        desc = 'Visual selection or word (cwd)',
      },
      {
        '<leader>fd',
        function()
          require('snacks').picker.files({
            cwd = LazyVim.root(),
            hidden = true,
            follow = true,
            cmd = 'fd',
            args = { '--type', 'd' },
            transform = function(entry)
              return vim.fn.isdirectory(entry.file) == 1
            end,
          })
        end,
        desc = 'Find directories',
      },
      {
        '<leader>fD',
        function()
          require('snacks').picker.files({
            cwd = vim.fn.getcwd(),
            hidden = true,
            follow = true,
            cmd = 'fd',
            args = { '--type', 'd' },
            transform = function(entry)
              return vim.fn.isdirectory(entry.file) == 1
            end,
          })
        end,
        desc = 'Find directories (cwd)',
      },
    },
  },
  { -- better file explorer
    'stevearc/oil.nvim',
    dependencies = { 'nvim-mini/mini.icons' },
    lazy = false,
    ---@module "oil"
    ---@type oil.setupOpts
    opts = {
      delete_to_trash = true,
      view_options = {
        show_hidden = true,
        is_always_hidden = function(name)
          -- always hide .git directory
          if name:match('^%.git$') then
            return true
          end
          return false
        end,
      },
      keymaps = {
        -- default keybindings; some disabled
        ['g?'] = { 'actions.show_help', mode = 'n' },
        ['<CR>'] = 'actions.select',
        ['<C-s>'] = { 'actions.select', opts = { vertical = true } },
        -- ['<C-h>'] = { 'actions.select', opts = { horizontal = true } },
        ['<C-t>'] = { 'actions.select', opts = { tab = true } },
        ['<C-p>'] = 'actions.preview',
        ['<C-c>'] = { 'actions.close', mode = 'n' },
        -- ['<C-l>'] = 'actions.refresh',
        ['-'] = { 'actions.parent', mode = 'n' },
        ['_'] = { 'actions.open_cwd', mode = 'n' },
        ['`'] = { 'actions.cd', mode = 'n' },
        ['g~'] = { 'actions.cd', opts = { scope = 'tab' }, mode = 'n' },
        ['gs'] = { 'actions.change_sort', mode = 'n' },
        ['gx'] = 'actions.open_external',
        ['g.'] = { 'actions.toggle_hidden', mode = 'n' },
        ['g\\'] = { 'actions.toggle_trash', mode = 'n' },
        -- custom
        ['<C-r>'] = 'actions.refresh',
      },
      use_default_keymaps = false,
    },
    keys = {
      {
        '-',
        function()
          require('oil').open()
        end,
        desc = 'File Explorer',
      },
      {
        '<leader>e',
        function()
          require('oil').open(LazyVim.root())
        end,
        desc = 'Explorer oil (root dir)',
      },
      {
        '<leader>E',
        function()
          require('oil').open(vim.fn.getcwd())
        end,
        desc = 'Explorer oil (cwd)',
      },
    },
  },
  { -- neogit
    'NeogitOrg/neogit',
    cmd = 'Neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'sindrets/diffview.nvim', -- diff integration
      'folke/snacks.nvim', -- picker integration
    },
    opts = { kind = 'replace' },
    init = function()
      -- `nvim +NeogitPopup`: Neogit alone in the cwd's repo, for terminal
      -- popups such as Rex's prefix+g. Closing the status buffer quits nvim
      -- unless it left a file open.
      vim.api.nvim_create_user_command('NeogitPopup', function()
        vim.api.nvim_create_autocmd('BufWipeout', {
          group = vim.api.nvim_create_augroup('neogit_popup', { clear = true }),
          callback = function(ev)
            if vim.bo[ev.buf].filetype ~= 'NeogitStatus' then
              return
            end
            -- Neogit opens a file from status in a callback it schedules after
            -- this wipe; check once that has run.
            vim.schedule(function()
              vim.schedule(function()
                local buf = vim.api.nvim_get_current_buf()
                if vim.api.nvim_buf_get_name(buf) == '' and vim.bo[buf].buftype == '' then
                  vim.cmd('qa')
                end
              end)
            end)
          end,
        })
        require('neogit').open({ kind = 'replace', cwd = vim.fn.getcwd() })
      end, { desc = 'Neogit alone; quit nvim when it closes' })
    end,
    keys = {
      {
        '<leader>gg',
        function()
          require('neogit').open({ cwd = LazyVim.root.git() })
        end,
        desc = 'Neogit',
      },
      {
        '<leader>gG',
        function()
          require('neogit').open({ cwd = vim.fn.getcwd() })
        end,
        desc = 'Neogit (cwd)',
      },
    },
  },
  { -- diffview: q closes it from the diff or the file panel
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory', 'DiffviewClose' },
    -- <leader>gd/gD/gf stay LazyVim's Snacks pickers; Diffview gets <leader>gv.
    keys = {
      { '<leader>gv', '', desc = '+diffview' },
      { '<leader>gvd', '<cmd>DiffviewOpen<cr>', desc = 'Diff working tree' },
      { '<leader>gvb', '<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<cr>', desc = 'Diff branch vs origin' },
      { '<leader>gvf', '<cmd>DiffviewFileHistory %<cr>', desc = 'File history' },
      { '<leader>gvF', '<cmd>DiffviewFileHistory<cr>', desc = 'Repo history' },
      { '<leader>gvf', "<cmd>'<,'>DiffviewFileHistory<cr>", mode = 'x', desc = 'Selection history' },
      { '<leader>gvq', '<cmd>DiffviewClose<cr>', desc = 'Close Diffview' },
    },
    opts = {
      keymaps = {
        view = { { 'n', 'q', '<Cmd>DiffviewClose<CR>', { desc = 'Close Diffview' } } },
        file_panel = { { 'n', 'q', '<Cmd>DiffviewClose<CR>', { desc = 'Close Diffview' } } },
        file_history_panel = { { 'n', 'q', '<Cmd>DiffviewClose<CR>', { desc = 'Close Diffview' } } },
      },
    },
  },
  { -- yazi
    'mikavilpas/yazi.nvim',
    cmd = 'Yazi',
    dependencies = { 'nvim-lua/plenary.nvim' },
    ---@module "yazi"
    ---@type YaziConfig
    opts = {
      open_for_directories = true,
    },
    keys = {
      { '<leader>y', '<cmd>Yazi<cr>', desc = 'yazi' },
      { '<leader>Y', '<cmd>Yazi cwd<cr>', desc = 'yazi (cwd)' },
    },
  },
  {
    'obsidian-nvim/obsidian.nvim', -- community fork; epwalsh/obsidian.nvim is unmaintained
    enabled = #vault_workspaces > 0,
    ft = { 'markdown' },
    opts = {
      workspaces = vault_workspaces,
      legacy_commands = false, -- `:Obsidian <sub>` instead of the deprecated `:ObsidianX`
    },
  },
  { -- Directory diffing plugin
    'will133/vim-dirdiff',
    cmd = 'DirDiff', -- Vimscript plugin: no Lua module, so no opts
  },
}
