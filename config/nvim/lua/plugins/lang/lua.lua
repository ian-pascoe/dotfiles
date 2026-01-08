return {
  {
    'mason-org/mason.nvim',
    opts = {
      ensure_installed = { 'selene' },
    },
  },
  {
    'nvimtools/none-ls.nvim',
    ft = { 'lua' },
    opts = function(_, opts)
      local nls = require('null-ls')
      opts.sources = vim.list_extend(opts.sources or {}, {
        nls.builtins.diagnostics.selene,
      })
    end,
  },
}
