return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "alejandra" },
    },
  },
  { -- Use nixd instead of nil_ls for nix files
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nil_ls = { enabled = false, mason = false },
        nixd = {
          mason = false,
          cmd = { "nixd" },
          filetypes = { "nix" },
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
