return {
  { -- disable builtin explorer
    "folke/snacks.nvim",
    opts = {
      explorer = { enabled = false },
    },
  },
  { -- use oil instead
    "stevearc/oil.nvim",
    dependencies = { "echasnovski/mini.icons" },
    lazy = false,
    opts = {},
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "File Explorer" },
    },
  },
  { -- neogit
    "NeogitOrg/neogit",
    event = "VeryLazy",
    cmd = "Neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim", -- diff integration
      "folke/snacks.nvim", -- picker integration
    },
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit" },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "LazyFile",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
  },
}
