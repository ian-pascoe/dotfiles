return {
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
      local nls = require("null-ls")
      vim.list_extend(opts.sources or {}, {
        nls.builtins.code_actions.refactoring,
        nls.builtins.hover.printenv,
      })
    end,
  },
  { import = "plugins.lang" },
}
