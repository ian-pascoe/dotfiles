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
    -- Picks its light or dark palette from 'background' when applied.
    config = function(_, opts)
      vim.o.termguicolors = true
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
      -- onedark switches itself to its light style when 'background' is light
      -- but never back, so pick the style each time it is applied.
      vim.api.nvim_create_autocmd('ColorSchemePre', {
        pattern = 'onedark',
        callback = function()
          require('onedark').set_options('style', vim.o.background == 'light' and 'light' or 'dark')
        end,
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
    -- Its no-clown-fiesta-light colorscheme resets every other option, so pick
    -- the theme from 'background' each time it is applied instead.
    config = function()
      local function setup()
        require('no-clown-fiesta').setup({
          theme = vim.o.background == 'light' and 'light' or 'dark',
          transparent = vim.g.transparent_enabled,
        })
      end
      setup()
      vim.api.nvim_create_autocmd('ColorSchemePre', { pattern = 'no-clown-fiesta', callback = setup })
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
  github = {
    repo = 'projekt0n/github-nvim-theme',
    name = 'github-nvim-theme',
    colorscheme = 'github_dark_default',
    config = function()
      require('github-theme').setup({
        options = { transparent = vim.g.transparent_enabled },
      })
    end,
  },
  vscode = {
    repo = 'Mofiqul/vscode.nvim',
    name = 'vscode.nvim',
    colorscheme = 'vscode',
    -- Picks its dark or light style from 'background' when applied.
    config = function()
      require('vscode').setup({
        transparent = vim.g.transparent_enabled,
      })
    end,
  },
  ['xcode-dark'] = {
    repo = 'lunacookies/vim-colors-xcode',
    name = 'vim-colors-xcode',
    colorscheme = 'xcodedark',
    -- No transparency option; transparent.nvim clears the backgrounds.
  },
  darcula = {
    repo = 'xiantang/darcula-dark.nvim',
    name = 'darcula-dark.nvim',
    colorscheme = 'darcula-dark',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    -- No transparency option; transparent.nvim clears the backgrounds.
  },
  horizon = {
    repo = 'akinsho/horizon.nvim',
    name = 'horizon.nvim',
    colorscheme = 'horizon',
    -- No transparency option; transparent.nvim clears the backgrounds. It picks
    -- its dark or light palette from 'background', which light.mode sets, but
    -- palette-light.lua lacks the syntax colors the highlights read and
    -- crashes, so fill them in from the Horizon Bright VS Code theme.
    config = function()
      local palette = require('horizon.palette-light').palette
      palette.syntax = vim.tbl_extend('keep', palette.syntax, {
        apricot = '#DC3318',
        cranberry = '#DA103F',
        gray = '#333333',
        lavender = '#8A31B9',
        rosebud = '#F6661E',
        tacao = '#F77D26',
        turquoise = '#1D8991',
      })
      require('horizon').setup()
    end,
  },
  cobalt2 = {
    repo = 'lalitmee/cobalt2.nvim',
    name = 'cobalt2.nvim',
    colorscheme = 'cobalt2',
    -- colorbuddy's v1.0.0 requires the colorscheme's Lua module; later commits
    -- dropped that, which leaves cobalt2.nvim's own colors/cobalt2.vim empty.
    dependencies = { { 'tjdevries/colorbuddy.nvim', tag = 'v1.0.0' } },
    -- No transparency option; transparent.nvim clears the backgrounds. The
    -- colors/ file is empty, so apply it through colorbuddy, again on every
    -- :colorscheme (the Lua modules are cached and highlights are not cleared).
    config = function()
      local function apply()
        vim.cmd.highlight('clear')
        for module in pairs(package.loaded) do
          if module:match('^cobalt2') then
            package.loaded[module] = nil
          end
        end
        require('colorbuddy').colorscheme('cobalt2')
      end
      apply()
      vim.api.nvim_create_autocmd('ColorSchemePre', { pattern = 'cobalt2', callback = apply })
    end,
  },
  ['shades-of-purple'] = {
    repo = 'necrogoru/shades-of-purple.nvim',
    name = 'shades-of-purple.nvim',
    colorscheme = 'shades-of-purple',
    -- No transparency option; transparent.nvim clears the backgrounds.
  },
  ['night-owl'] = {
    repo = 'oxfist/night-owl.nvim',
    name = 'night-owl.nvim',
    colorscheme = 'night-owl',
    opts = {
      transparent_background = vim.g.transparent_enabled,
    },
  },
  ['light-owl'] = {
    -- The only Neovim port of Light Owl (Night Owl Light); oxfist/night-owl.nvim
    -- is dark only. It sets 'background' to light itself.
    repo = 'macguirerintoul/night_owl_light.vim',
    name = 'night_owl_light.vim',
    colorscheme = 'night_owl_light',
    -- No transparency option; transparent.nvim clears the backgrounds.
  },
  ['synthwave-84'] = {
    -- A maintained fork of LunarVim/synthwave84.nvim; its retrowave theme uses
    -- SynthWave '84's palette (bg #262335).
    repo = 'maxmx03/fluoromachine.nvim',
    name = 'fluoromachine.nvim',
    colorscheme = 'fluoromachine',
    opts = {
      theme = 'retrowave',
      glow = true,
      transparent = vim.g.transparent_enabled,
    },
  },
  everblush = {
    repo = 'Everblush/nvim',
    name = 'everblush',
    colorscheme = 'everblush',
    opts = {
      transparent_background = vim.g.transparent_enabled,
    },
  },
  ['material-ocean'] = {
    repo = 'marko-cerovac/material.nvim',
    name = 'material.nvim',
    colorscheme = 'material',
    -- material-lighter and palenight share this spec (see nvim-aliases.lua), and
    -- the plugin picks its palette from vim.g.material_style when the colorscheme
    -- loads, so choose the style from the active theme each time it is applied.
    config = function()
      local styles = {
        ['material-lighter'] = 'lighter',
        palenight = 'palenight',
      }
      local function setup()
        vim.g.material_style = styles[Util.get_theme()] or 'deep ocean'
        require('material').setup({
          disable = { background = vim.g.transparent_enabled },
        })
      end
      setup()
      vim.api.nvim_create_autocmd('ColorSchemePre', { pattern = 'material', callback = setup })
    end,
  },
  zenburn = {
    repo = 'phha/zenburn.nvim',
    name = 'zenburn.nvim',
    colorscheme = 'zenburn',
    -- No transparency option; transparent.nvim clears the backgrounds.
  },
  alabaster = {
    repo = 'dchinmay2/alabaster.nvim',
    name = 'alabaster.nvim',
    colorscheme = 'alabaster',
    -- Picks its light or dark palette from 'background' when applied.
    -- No transparency option; transparent.nvim clears the backgrounds.
  },
  ['selenized-dark'] = {
    repo = 'calind/selenized.nvim',
    name = 'selenized.nvim',
    colorscheme = 'selenized',
    -- Picks its light or dark palette from 'background' when applied.
    -- No transparency option; transparent.nvim clears the backgrounds.
  },
  ['vitesse-dark'] = {
    repo = 'qshan-li/neovim-theme-vitesse',
    name = 'vitesse.nvim',
    colorscheme = 'vitesse-dark',
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
  ['catppuccin-latte'] = { 'catppuccin', 'catppuccin-latte' },
  ['rose-pine-dawn'] = { 'rose-pine', 'rose-pine-dawn' },
  ['tokyo-night-day'] = { 'tokyo-night', 'tokyonight-day' },
  -- These follow 'background', which light.mode sets, so the variant keeps its
  -- sibling's colorscheme name.
  ['gruvbox-light'] = { 'gruvbox', 'gruvbox' },
  ['gruvbox-material-light'] = { 'gruvbox-material', 'gruvbox-material' },
  ['everforest-light'] = { 'everforest', 'everforest' },
  ['solarized-light'] = { 'solarized', 'solarized' },
  ['iceberg-light'] = { 'iceberg', 'iceberg' },
  ['melange-light'] = { 'melange', 'melange' },
  ['oxocarbon-light'] = { 'oxocarbon', 'oxocarbon' },
  ['one-light'] = { 'one-dark', 'onedark' },
  ['zenbones-dark'] = { 'zenbones-light', 'zenbones' },
  ['flexoki-light'] = { 'flexoki', 'flexoki-light' },
  ['kanagawa-lotus'] = { 'kanagawa', 'kanagawa-lotus' },
  ['kanso-pearl'] = { 'kanso', 'kanso-pearl' },
  ['bluloco-light'] = { 'bluloco', 'bluloco-light' },
  ['monokai-pro-light'] = { 'monokai-pro', 'monokai-pro-light' },
  dawnfox = { 'carbonfox', 'dawnfox' },
  ['no-clown-fiesta-light'] = { 'no-clown-fiesta', 'no-clown-fiesta' },
  ['cyberdream-light'] = { 'cyberdream', 'cyberdream-light' },
  ['github-dark'] = { 'github', 'github_dark_default' },
  ['github-light'] = { 'github', 'github_light_default' },
  -- These follow 'background', which light.mode sets, so the variant keeps its
  -- sibling's colorscheme name.
  ['vscode-dark'] = { 'vscode', 'vscode' },
  ['vscode-light'] = { 'vscode', 'vscode' },
  -- xcodelight is its own colorscheme, so it does not depend on 'background'.
  ['xcode-light'] = { 'xcode-dark', 'xcodelight' },
  -- Follows 'background', which light.mode sets, so it keeps its sibling's colorscheme name.
  ['horizon-bright'] = { 'horizon', 'horizon' },
  -- The material.nvim style comes from the theme name (see the material-ocean
  -- spec), and the plugin sets 'background' itself, so the colorscheme is shared.
  ['material-lighter'] = { 'material-ocean', 'material' },
  palenight = { 'material-ocean', 'material' },
  -- Follows 'background', which light.mode sets (alabaster is the light variant and the spec); dark has no light.mode.
  ['alabaster-dark'] = { 'alabaster', 'alabaster' },
  -- Follows 'background', which light.mode sets.
  ['selenized-light'] = { 'selenized-dark', 'selenized' },
  nightfox = { 'carbonfox', 'nightfox' },
  -- dayfox is nightfox.nvim's light colorscheme; it does not depend on 'background'.
  dayfox = { 'carbonfox', 'dayfox' },
  nordfox = { 'carbonfox', 'nordfox' },
  ['ayu-dark'] = { 'ayu-mirage', 'ayu-dark' },
  bamboo = { 'osaka-jade', 'bamboo' },
  ['bamboo-light'] = { 'osaka-jade', 'bamboo-light' },
  ['vitesse-light'] = { 'vitesse-dark', 'vitesse-light' },
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
