return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "alejandra" },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        nix = { "alejandra" },
      },
    },
  },
}
