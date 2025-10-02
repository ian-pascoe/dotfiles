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
    keys = {
      {
        "<leader>fd",
        function()
          require("snacks").picker.files({
            cwd = LazyVim.root(),
            hidden = true,
            follow = true,
            cmd = "fd",
            args = { "--type", "d" },
            transform = function(entry)
              return vim.fn.isdirectory(entry.file) == 1
            end,
          })
        end,
        desc = "Find directories",
      },
      {
        "<leader>fD",
        function()
          require("snacks").picker.files({
            cwd = vim.fn.getcwd(),
            hidden = true,
            follow = true,
            cmd = "fd",
            args = { "--type", "d" },
            transform = function(entry)
              return vim.fn.isdirectory(entry.file) == 1
            end,
          })
        end,
        desc = "Find directories (cwd)",
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
      win_options = {
        signcolumn = "yes:2",
        statuscolumn = "",
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
  {
    "FerretDetective/oil-git-signs.nvim",
    ft = "oil",
    ---@module "oil-git-signs"
    ---@type oil_git_signs.Config
    opts = {},
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
      {
        "<leader>gg",
        function()
          require("neogit").open({ cwd = LazyVim.root.git() })
        end,
        desc = "Neogit",
      },
      {
        "<leader>gG",
        function()
          require("neogit").open({ cwd = vim.fn.getcwd() })
        end,
        desc = "Neogit (cwd)",
      },
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
  {
    "epwalsh/obsidian.nvim",
    lazy = true,
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    ---@module "obsidian"
    ---@type obsidian.config.ClientOpts
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      workspaces = {
        {
          name = "personal",
          path = "~/vaults/personal",
        },
        {
          name = "family",
          path = "~/vaults/family",
        },
      },
    },
  },
}
