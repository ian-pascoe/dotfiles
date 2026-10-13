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
  poimandres = {
    repo = 'olivercederborg/poimandres.nvim',
    name = 'poimandres.nvim',
    colorscheme = 'poimandres',
    config = function()
      require('poimandres').setup({
        disable_background = vim.g.transparent_enabled,
        disable_float_background = vim.g.transparent_enabled,
      })
    end,
  },
  oxocarbon = {
    repo = 'nyoom-engineering/oxocarbon.nvim',
    name = 'oxocarbon',
    colorscheme = 'oxocarbon',
    -- Its rockspec makes lazy.nvim build it with luarocks, but the compiled Lua
    -- is already in the repo.
    build = false,
    -- No transparency option; transparent.nvim clears the backgrounds.
  },
  melange = {
    repo = 'savq/melange-nvim',
    name = 'melange',
    colorscheme = 'melange',
    -- No transparency option; transparent.nvim clears the backgrounds.
  },
  ['matte-black'] = {
    repo = 'tahayvr/matteblack.nvim',
    name = 'matteblack.nvim',
    colorscheme = 'matteblack',
    -- No transparency option; transparent.nvim clears the backgrounds.
  },
  ['osaka-jade'] = {
    repo = 'ribru17/bamboo.nvim',
    name = 'bamboo',
    colorscheme = 'bamboo',
    config = function()
      require('bamboo').setup({
        style = 'vulgaris',
        transparent = vim.g.transparent_enabled,
      })
    end,
  },
  eldritch = {
    repo = 'eldritch-theme/eldritch.nvim',
    name = 'eldritch',
    colorscheme = 'eldritch',
    opts = {
      transparent = vim.g.transparent_enabled,
      styles = {
        sidebars = vim.g.transparent_enabled and 'transparent' or 'normal',
        floats = vim.g.transparent_enabled and 'transparent' or 'normal',
      },
    },
  },
  ['black-metal'] = {
    repo = 'metalelf0/black-metal-theme-neovim',
    name = 'black-metal',
    colorscheme = 'immortal',
    opts = {
      theme = 'immortal',
      variant = 'dark',
      transparent = vim.g.transparent_enabled,
    },
    config = function(_, opts)
      require('black-metal').setup(opts)
    end,
  },
  ['ayu-mirage'] = {
    repo = 'Shatur/neovim-ayu',
    name = 'neovim-ayu',
    colorscheme = 'ayu-mirage',
    -- No transparency option; transparent.nvim clears the backgrounds.
  },
  ['modus-operandi'] = {
    repo = 'miikanissi/modus-themes.nvim',
    name = 'modus-themes.nvim',
    colorscheme = 'modus_operandi',
    opts = {
      transparent = vim.g.transparent_enabled,
    },
  },
  ['zenbones-light'] = {
    repo = 'zenbones-theme/zenbones.nvim',
    name = 'zenbones.nvim',
    colorscheme = 'zenbones',
    config = function()
      -- The precompiled colorscheme runs without lush.nvim. It has no
      -- transparency option; transparent.nvim clears the backgrounds.
      vim.g.zenbones_compat = 1
    end,
  },
  miasma = {
    repo = 'xero/miasma.nvim',
    name = 'miasma.nvim',
    colorscheme = 'miasma',
    -- No transparency option; transparent.nvim clears the backgrounds.
  },
  iceberg = {
    repo = 'cocopon/iceberg.vim',
    name = 'iceberg',
    colorscheme = 'iceberg',
    -- No transparency option; transparent.nvim clears the backgrounds.
  },
  mellow = {
    repo = 'mellow-theme/mellow.nvim',
    name = 'mellow',
    colorscheme = 'mellow',
    config = function()
      vim.g.mellow_transparent = vim.g.transparent_enabled
    end,
  },
  kanso = {
    repo = 'webhooked/kanso.nvim',
    name = 'kanso.nvim',
    colorscheme = 'kanso-zen',
    opts = {
      transparent = vim.g.transparent_enabled,
      background = { dark = 'zen', light = 'pearl' },
    },
  },
  nightfly = {
    repo = 'bluz71/vim-nightfly-colors',
    name = 'nightfly',
    colorscheme = 'nightfly',
    config = function()
      vim.g.nightflyTransparent = vim.g.transparent_enabled
    end,
  },
  ['gruvbox-material'] = {
    repo = 'sainnhe/gruvbox-material',
    name = 'gruvbox-material',
    colorscheme = 'gruvbox-material',
    config = function()
      vim.g.gruvbox_material_background = 'medium'
      vim.g.gruvbox_material_foreground = 'material'
      vim.g.gruvbox_material_transparent_background = vim.g.transparent_enabled and 1 or 0
    end,
  },
  sonokai = {
    repo = 'sainnhe/sonokai',
    name = 'sonokai',
    colorscheme = 'sonokai',
    config = function()
      vim.g.sonokai_style = 'default'
      vim.g.sonokai_transparent_background = vim.g.transparent_enabled and 1 or 0
    end,
  },
  nordic = {
    repo = 'AlexvZyl/nordic.nvim',
    name = 'nordic',
    colorscheme = 'nordic',
    opts = {
      transparent = {
        bg = vim.g.transparent_enabled,
        float = vim.g.transparent_enabled,
      },
    },
  },
  ['solarized-osaka'] = {
    repo = 'craftzdog/solarized-osaka.nvim',
    name = 'solarized-osaka.nvim',
    colorscheme = 'solarized-osaka',
    opts = {
      transparent = vim.g.transparent_enabled,
    },
  },
  tokyodark = {
    repo = 'tiagovla/tokyodark.nvim',
    name = 'tokyodark.nvim',
    colorscheme = 'tokyodark',
    opts = {
      transparent_background = vim.g.transparent_enabled,
    },
  },
  jellybeans = {
    repo = 'WTFox/jellybeans.nvim',
    name = 'jellybeans',
    colorscheme = 'jellybeans',
    opts = {
      transparent = vim.g.transparent_enabled,
    },
  },
  bluloco = {
    repo = 'uloco/bluloco.nvim',
    name = 'bluloco.nvim',
    colorscheme = 'bluloco-dark',
    dependencies = { 'rktjmp/lush.nvim' },
    opts = {
      style = 'dark',
      transparent = vim.g.transparent_enabled,
    },
  },
  embark = {
    repo = 'embark-theme/vim',
    name = 'embark',
    colorscheme = 'embark',
    -- No transparency option; transparent.nvim clears the backgrounds.
  },
  ['no-clown-fiesta'] = {
    repo = 'aktersnurra/no-clown-fiesta.nvim',
    name = 'no-clown-fiesta.nvim',
    colorscheme = 'no-clown-fiesta',
    config = function()
      require('no-clown-fiesta').setup({
        theme = 'dark',
        transparent = vim.g.transparent_enabled,
      })
    end,
  },
  ['kanagawa-paper'] = {
    repo = 'thesimonho/kanagawa-paper.nvim',
    name = 'kanagawa-paper.nvim',
    colorscheme = 'kanagawa-paper-ink',
    opts = {
      transparent = vim.g.transparent_enabled,
    },
  },
  boo = {
    repo = 'rockerBOO/boo-colorscheme-nvim',
    name = 'boo-colorscheme-nvim',
    colorscheme = 'crimson_moonlight',
    -- No transparency option; transparent.nvim clears the backgrounds.
  },
  ['retro-82'] = {
    repo = 'OldJobobo/retro-82.nvim',
    name = 'retro-82.nvim',
    colorscheme = 'retro-82',
    config = function()
      require('retro82').setup({
        transparent = vim.g.transparent_enabled,
      })
    end,
  },
  ethereal = {
    repo = 'bjarneo/ethereal.nvim',
    name = 'ethereal.nvim',
    colorscheme = 'ethereal',
    opts = {
      transparent = vim.g.transparent_enabled,
    },
  },
  hackerman = {
    repo = 'bjarneo/hackerman.nvim',
    name = 'hackerman.nvim',
    colorscheme = 'hackerman',
    dependencies = { 'bjarneo/aether.nvim' },
    -- hackerman.nvim only ships colors/hackerman.lua, which calls aether's
    -- loader, so transparency is set on aether.
    config = function()
      require('aether').setup({ transparent = vim.g.transparent_enabled })
    end,
  },
  lumon = {
    repo = 'omacom/lumon.nvim',
    name = 'lumon',
    colorscheme = 'lumon',
    opts = {
      transparent = vim.g.transparent_enabled,
    },
  },
}

-- Variants share another theme's plugin and options and differ only in the
-- colorscheme, so their plugin options cannot conflict.
for name, variant in pairs({
  duskfox = { 'carbonfox', 'duskfox' },
  terafox = { 'carbonfox', 'terafox' },
  ['kanagawa-dragon'] = { 'kanagawa', 'kanagawa-dragon' },
  ristretto = { 'monokai-pro', 'monokai-pro-ristretto' },
  ['ayu-light'] = { 'ayu-mirage', 'ayu-light' },
  ['modus-vivendi'] = { 'modus-operandi', 'modus_vivendi' },
}) do
  local base, colorscheme = unpack(variant)
  theme_specs[name] = vim.tbl_extend('force', theme_specs[base], { colorscheme = colorscheme })
end

local function spec_for(name)
  return theme_specs[name] or theme_specs['rose-pine']
end

local active_spec = spec_for(theme)

-- Light themes carry a light.mode marker. Many colorschemes pick their
-- variant from 'background', so set it before any of them load.
vim.o.background = Util.get_background()

-- Every theme is installed; only the active one loads at startup. lazy.nvim
-- loads the others when `:colorscheme` asks for them. Variants of one plugin
-- (carbonfox, duskfox, ...) share a single plugin spec; the active theme's
-- options win.
local plugins = {}
for _, spec in pairs(theme_specs) do
  if not plugins[spec.repo] or spec == active_spec then
    plugins[spec.repo] = {
      spec.repo,
      name = spec.name,
      lazy = spec ~= active_spec,
      priority = 1000,
      build = spec.build,
      dependencies = spec.dependencies,
      opts = spec.opts,
      config = spec.config,
    }
  end
end
for _, plugin in pairs(plugins) do
  table.insert(M, plugin)
end

table.insert(M, {
  'LazyVim/LazyVim',
  opts = { colorscheme = active_spec.colorscheme },
})

-- Follow `set-theme` live: it swaps the `theme` link, so watch its directory
-- and reapply the colorscheme when the link changes. Util outlives spec
-- reloads, so the guard keeps one watcher per Neovim.
local function apply_theme()
  local background = Util.get_background()
  if vim.o.background ~= background then
    vim.o.background = background
  end
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
