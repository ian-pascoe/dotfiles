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
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim", -- diff integration
      "folke/snacks.nvim", -- picker integration
    },
    event = "VeryLazy",
    cmd = "Neogit",
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit" },
    },
  },
}
