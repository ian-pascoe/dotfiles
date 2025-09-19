return {
  {
    "folke/snacks.nvim",
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
  },
  { -- better file explorer
    "stevearc/oil.nvim",
    dependencies = { "nvim-mini/mini.icons" },
    lazy = false,
    ---@module "oil"
    ---@type oil.setupOpts
    opts = {
      delete_to_trash = true,
      view_options = {
        show_hidden = true,
        is_always_hidden = function(name)
          -- always hide .git directory
          if name:match("^%.git$") then
            return true
          end
          return false
        end,
      },
    },
    keys = {
      {
        "-",
        function()
          require("oil").open()
        end,
        desc = "File Explorer",
      },
      {
        "<leader>e",
        function()
          require("oil").open(LazyVim.root())
        end,
        desc = "Explorer oil (root dir)",
      },
      {
        "<leader>E",
        function()
          require("oil").open(vim.fn.getcwd())
        end,
        desc = "Explorer oil (cwd)",
      },
    },
  },
  { -- neogit
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim", -- diff integration
      "folke/snacks.nvim", -- picker integration
    },
    opts = {},
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit" },
    },
  },
  { -- yazi
    "mikavilpas/yazi.nvim",
    cmd = "Yazi",
    dependencies = { "nvim-lua/plenary.nvim" },
    ---@module "yazi"
    ---@type YaziConfig
    opts = {
      open_for_directories = true,
    },
    keys = {
      { "<leader>y", "<cmd>Yazi<cr>", desc = "yazi" },
      { "<leader>Y", "<cmd>Yazi cwd<cr>", desc = "yazi (cwd)" },
    },
  },
}
