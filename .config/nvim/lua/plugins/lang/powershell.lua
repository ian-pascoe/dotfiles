return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        powershell_es = {
          enabled = vim.fn.executable("powershell") == 1,
          filetypes = { "ps1", "psm1", "psd1", "pwsh" },
          settings = {
            powershell = {
              codeFormatting = {
                autoCorrectAliases = true,
                openBraceOnSameLine = true,
                useCorrectCasing = true,
              },
            },
          },
        },
      },
    },
  },
}
