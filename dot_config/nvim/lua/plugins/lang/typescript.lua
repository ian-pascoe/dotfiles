-- TypeScript's language server on tsrs, the Rust port of TypeScript 7: about half tsc's memory and a third of its time
-- to first diagnostics. `tsrs-lsp` (~/.local/bin) takes an Effect project's own Effect-patched tsrs, else tsrs or tsc
-- on PATH. lspconfig's `tsc` config still picks the root (the nearest lockfile) and attaches only where some tsc 7
-- can serve.
return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        tsc = {
          cmd = function(dispatchers, config)
            return vim.lsp.rpc.start({ 'tsrs-lsp', '--lsp', '--stdio' }, dispatchers, { cwd = config.root_dir })
          end,
        },
      },
    },
  },
}
