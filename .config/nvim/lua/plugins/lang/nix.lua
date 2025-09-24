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
          enabled = not LazyVim.is_win(), -- disable on windows
          cmd = { "nil", "--stdio" },
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
