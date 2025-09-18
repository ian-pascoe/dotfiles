return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ---@type vim.lsp.ClientConfig
        ---@diagnostic disable-next-line: missing-fields
        powershell_es = {
          enabled = vim.fn.executable("pwsh") == 1,
          capabilities = require("blink-cmp").get_lsp_capabilities(nil, true),
          init_options = {
            enableProfileLoading = false,
          },
          settings = {
            powershell = {
              codeFormatting = {
                preset = "OTBS",
              },
            },
          },
        },
      },
    },
  },
}
