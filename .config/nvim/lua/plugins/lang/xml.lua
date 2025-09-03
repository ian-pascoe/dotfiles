return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "xml" },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "xmlformatter" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lemminx = {
          filetypes = { "xml", "xsd", "wsdl", "svg", "plist" },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        xml = { "xmlformatter" },
      },
    },
  },
}
