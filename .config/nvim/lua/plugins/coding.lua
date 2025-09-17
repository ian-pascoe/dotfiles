return {
  { -- disable auto pairs
    "nvim-mini/mini.pairs",
    enabled = false,
  },
  { -- override blink keymap preset
    "saghen/blink.cmp",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = "default",
      },
    },
  },
}
