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
  {
    'neovim/nvim-lspconfig',
    opts = function(_, opts)
      ---@module "lazyvim"
      ---@type lazyvim.lsp.Config
      opts.servers.lua_ls = (opts.servers or {}).lua_ls or {}

      -- Use local lua-language-server if it exists
      local local_lsp = vim.fn.expand(os.getenv('HOME') .. '/code/lua-language-server/bin/lua-language-server')
      if vim.fn.executable(local_lsp) == 1 then
        opts.servers.lua_ls.cmd = { local_lsp }
      end
    end,
  },
}
