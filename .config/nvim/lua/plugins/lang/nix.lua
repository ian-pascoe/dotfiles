return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "alejandra" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nil_ls = {
          enabled = false, -- use nixd instead
        },
        nixd = {
          mason = false, -- nix handles install
          enabled = not LazyVim.is_win(), --disable on windows
          cmd = { "nixd" },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        nix = { "alejandra" },
      },
    },
  },
}
