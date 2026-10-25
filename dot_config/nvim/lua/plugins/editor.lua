local function get_vaults()
  local workspaces = {}

  local vaults_path = vim.fn.finddir('vaults', os.getenv('HOME'))
  if vaults_path == '' then
    return workspaces
  end

  local personal_vault_name = 'personal'
  local personal_vault_path = vim.fn.finddir(personal_vault_name, vaults_path)
  if personal_vault_path ~= '' then
    workspaces = vim.list_extend(workspaces, {
      {
        name = personal_vault_name,
        path = personal_vault_path,
      },
    })
  end

  local family_vault_name = 'family'
  local family_vault_path = vim.fn.finddir(family_vault_name, vaults_path)
  if family_vault_path ~= '' then
    workspaces = vim.list_extend(workspaces, {
      {
        name = family_vault_name,
        path = family_vault_path,
      },
    })
  end

  local work_vault_name = 'work'
  local work_vault_path = vim.fn.finddir(work_vault_name, vaults_path)
  if work_vault_path ~= '' then
    workspaces = vim.list_extend(workspaces, {
      {
        name = work_vault_name,
        path = work_vault_path,
      },
    })
  end

  return workspaces
end

local vault_workspaces = get_vaults()

return {
  {
    'ibhagwan/fzf-lua',
    opts = function(_, opts)
      opts.winopts = opts.winopts or {}

      local previous_on_create = opts.winopts.on_create
      opts.winopts.on_create = function(event, ...)
        if type(previous_on_create) == 'function' then
          previous_on_create(event, ...)
        end

        local bufnr = event and event.bufnr or vim.api.nvim_get_current_buf()
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return
          end

          vim.keymap.set('t', '<C-j>', '<Down>', { buffer = bufnr, nowait = true, silent = true })
          vim.keymap.set('t', '<C-k>', '<Up>', { buffer = bufnr, nowait = true, silent = true })
        end)
      end
    end,
  },
  { -- fff: file/grep backend for the Snacks picker (see config/fff_picker.lua)
    'dmtrKovalenko/fff',
    build = function()
      require('fff.download').download_or_build_binary()
    end,
    lazy = false, -- fff initialises itself lazily
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
    opts = {},
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
    'epwalsh/obsidian.nvim',
    enabled = vault_workspaces ~= nil and #vault_workspaces > 0,
    ft = { 'markdown' },
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    opts = function(_, opts)
      opts.workspaces = vault_workspaces
    end,
  },
  { -- Directory diffing plugin
    'will133/vim-dirdiff',
    cmd = 'DirDiff',
    opts = {},
  },
  ---@module "neominimap.config.meta"
  {
    'Isrothy/neominimap.nvim',
    lazy = false, -- NOTE: NO NEED to Lazy load
    -- Optional. You can also set your own keybindings
    keys = {
      -- Global Minimap Controls
      { '<leader>nm', '<cmd>Neominimap Toggle<cr>', desc = 'Toggle global minimap' },
      { '<leader>no', '<cmd>Neominimap Enable<cr>', desc = 'Enable global minimap' },
      { '<leader>nc', '<cmd>Neominimap Disable<cr>', desc = 'Disable global minimap' },
      { '<leader>nr', '<cmd>Neominimap Refresh<cr>', desc = 'Refresh global minimap' },

      -- Window-Specific Minimap Controls
      { '<leader>nwt', '<cmd>Neominimap WinToggle<cr>', desc = 'Toggle minimap for current window' },
      { '<leader>nwr', '<cmd>Neominimap WinRefresh<cr>', desc = 'Refresh minimap for current window' },
      { '<leader>nwo', '<cmd>Neominimap WinEnable<cr>', desc = 'Enable minimap for current window' },
      { '<leader>nwc', '<cmd>Neominimap WinDisable<cr>', desc = 'Disable minimap for current window' },

      -- Tab-Specific Minimap Controls
      { '<leader>ntt', '<cmd>Neominimap TabToggle<cr>', desc = 'Toggle minimap for current tab' },
      { '<leader>ntr', '<cmd>Neominimap TabRefresh<cr>', desc = 'Refresh minimap for current tab' },
      { '<leader>nto', '<cmd>Neominimap TabEnable<cr>', desc = 'Enable minimap for current tab' },
      { '<leader>ntc', '<cmd>Neominimap TabDisable<cr>', desc = 'Disable minimap for current tab' },

      -- Buffer-Specific Minimap Controls
      { '<leader>nbt', '<cmd>Neominimap BufToggle<cr>', desc = 'Toggle minimap for current buffer' },
      { '<leader>nbr', '<cmd>Neominimap BufRefresh<cr>', desc = 'Refresh minimap for current buffer' },
      { '<leader>nbo', '<cmd>Neominimap BufEnable<cr>', desc = 'Enable minimap for current buffer' },
      { '<leader>nbc', '<cmd>Neominimap BufDisable<cr>', desc = 'Disable minimap for current buffer' },

      ---Focus Controls
      { '<leader>nf', '<cmd>Neominimap Focus<cr>', desc = 'Focus on minimap' },
      { '<leader>nu', '<cmd>Neominimap Unfocus<cr>', desc = 'Unfocus minimap' },
      { '<leader>ns', '<cmd>Neominimap ToggleFocus<cr>', desc = 'Switch focus on minimap' },
    },
    init = function()
      -- The following options are recommended when layout == "float"
      vim.opt.wrap = false
      vim.opt.sidescrolloff = 36 -- Set a large value

      --- Put your configuration here
      ---@type Neominimap.UserConfig
      vim.g.neominimap = {
        auto_enable = true,
      }
    end,
  },
}
