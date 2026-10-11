local theme = Util.get_theme()

---@module "lazy"
---@type LazyPluginSpec[]
local M = {
  { -- transparency
    'xiyaowong/transparent.nvim',
    build = ':TransparentEnable',
    lazy = false,
    priority = 1001,
    opts = {
      extra_groups = {
        'NormalFloat',
      },
    },
  },
}

local theme_specs = {
  ['tokyo-night'] = {
    repo = 'folke/tokyonight.nvim',
    name = 'tokyonight',
    colorscheme = 'tokyonight',
    opts = {
      transparent = vim.g.transparent_enabled,
    },
  },
  catppuccin = {
    repo = 'catppuccin/nvim',
    name = 'catppuccin',
    colorscheme = 'catppuccin',
    opts = function(_, opts)
      opts.auto_integrations = true
      opts.transparent_background = vim.g.transparent_enabled
      opts.float = opts.float or {}
      opts.float.transparent = vim.g.transparent_enabled
    end,
  },
  nord = {
    repo = 'shaunsingh/nord.nvim',
    name = 'nord',
    colorscheme = 'nord',
    opts = function()
      vim.g.nord_disable_background = vim.g.transparent_enabled
    end,
    config = function()
      require('nord').set()
    end,
  },
  ['rose-pine'] = {
    repo = 'rose-pine/neovim',
    name = 'rose-pine',
    colorscheme = 'rose-pine',
    opts = {
      styles = { transparency = vim.g.transparent_enabled },
    },
  },
  gruvbox = {
    repo = 'ellisonleao/gruvbox.nvim',
    name = 'gruvbox',
    colorscheme = 'gruvbox',
    opts = {
      transparent_mode = vim.g.transparent_enabled,
      contrast = 'medium',
    },
  },
  kanagawa = {
    repo = 'rebelot/kanagawa.nvim',
    name = 'kanagawa',
    colorscheme = 'kanagawa',
    opts = {
      transparent = vim.g.transparent_enabled,
    },
  },
  everforest = {
    repo = 'sainnhe/everforest',
    name = 'everforest',
    colorscheme = 'everforest',
    config = function()
      vim.g.everforest_background = 'medium'
      vim.g.everforest_transparent_background = vim.g.transparent_enabled and 1 or 0
    end,
  },
  dracula = {
    repo = 'Mofiqul/dracula.nvim',
    name = 'dracula',
    colorscheme = 'dracula',
    opts = {
      transparent_bg = vim.g.transparent_enabled,
    },
  },
  solarized = {
    repo = 'maxmx03/solarized.nvim',
    name = 'solarized',
    colorscheme = 'solarized',
    opts = {},
    config = function(_, opts)
      vim.o.termguicolors = true
      vim.o.background = 'dark'
      require('solarized').setup(opts)
    end,
  },
  ['one-dark'] = {
    repo = 'navarasu/onedark.nvim',
    name = 'onedark',
    colorscheme = 'onedark',
    config = function()
      require('onedark').setup({
        style = 'dark',
        transparent = vim.g.transparent_enabled,
      })
      require('onedark').load()
    end,
  },
  vesper = {
    repo = 'datsfilipe/vesper.nvim',
    name = 'vesper',
    colorscheme = 'vesper',
    config = function()
      require('vesper').setup({
        transparent = vim.g.transparent_enabled,
      })
    end,
  },
  flexoki = {
    repo = 'kepano/flexoki-neovim',
    name = 'flexoki',
    colorscheme = 'flexoki-dark',
  },
  cyberdream = {
    repo = 'scottmckendry/cyberdream.nvim',
    name = 'cyberdream',
    colorscheme = 'cyberdream',
    opts = {
      transparent = vim.g.transparent_enabled,
    },
  },
  carbonfox = {
    repo = 'EdenEast/nightfox.nvim',
    name = 'nightfox',
    colorscheme = 'carbonfox',
    opts = {
      options = { transparent = vim.g.transparent_enabled },
    },
  },
  vague = {
    repo = 'vague2k/vague.nvim',
    name = 'vague',
    colorscheme = 'vague',
    opts = {
      transparent = vim.g.transparent_enabled,
    },
  },
  moonfly = {
    repo = 'bluz71/vim-moonfly-colors',
    name = 'moonfly',
    colorscheme = 'moonfly',
    config = function()
      vim.g.moonflyTransparent = vim.g.transparent_enabled
    end,
  },
  ['monokai-pro'] = {
    repo = 'loctvl842/monokai-pro.nvim',
    name = 'monokai-pro',
    colorscheme = 'monokai-pro',
    opts = {
      filter = 'pro',
      transparent_background = vim.g.transparent_enabled,
    },
  },
}

local function spec_for(name)
  return theme_specs[name] or theme_specs['rose-pine']
end

local active_spec = spec_for(theme)

-- Every theme is installed; only the active one loads at startup. lazy.nvim
-- loads the others when `:colorscheme` asks for them.
for _, spec in pairs(theme_specs) do
  table.insert(M, {
    spec.repo,
    name = spec.name,
    lazy = spec ~= active_spec,
    priority = 1000,
    opts = spec.opts,
    config = spec.config,
  })
end

table.insert(M, {
  'LazyVim/LazyVim',
  opts = { colorscheme = active_spec.colorscheme },
})

-- Follow `set-theme` live: it swaps the `theme` link, so watch its directory
-- and reapply the colorscheme when the link changes. Util outlives spec
-- reloads, so the guard keeps one watcher per Neovim.
local function apply_theme()
  local ok, err = pcall(vim.cmd.colorscheme, spec_for(Util.get_theme()).colorscheme)
  if not ok then
    vim.notify('Could not switch colorscheme: ' .. err, vim.log.levels.WARN)
  end
end

if not Util.theme_watcher then
  local watcher, timer = vim.uv.new_fs_event(), vim.uv.new_timer()
  if watcher and timer then
    Util.theme_watcher = watcher
    watcher:start(Util.theme_dir(), {}, function(err, filename)
      if not err and filename == 'theme' then
        -- `ln -snf` reports more than one event; apply once they settle.
        timer:start(100, 0, vim.schedule_wrap(apply_theme))
      end
    end)
  end
end

return M
