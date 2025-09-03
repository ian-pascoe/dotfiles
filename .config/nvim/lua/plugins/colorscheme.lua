return {
  { -- disable default
    "folke/tokyonight.nvim",
    enabled = false,
  },
  { -- disable default
    "catppuccin/nvim",
    enabled = false,
  },
  { -- add rose-pine
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      require("rose-pine").setup({
        variant = "auto",
        extend_background_behind_borders = false,
        styles = {
          transparency = true,
        },
      })
    end,
  },
  { -- tell LazyVim to use rose-pine
    "LazyVim/LazyVim",
    opts = { colorscheme = "rose-pine" },
  },
}
