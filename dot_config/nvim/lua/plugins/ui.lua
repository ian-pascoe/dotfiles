return {
  { -- custom dashboard header
    'folke/snacks.nvim',
    opts = {
      dashboard = {
        preset = {
          header = [[
 █████╗          ██╗          ██████╗  
██╔══██╗       ██████╗       ██╔═══██╗ 
███████║       ╚═██╔═╝       ██║   ██║ 
██╔══██║         ██║         ╚██╗ ██╔╝ 
██║  ██║         ██║         ███╔╝╚███╗
╚═╝  ╚═╝         ╚═╝         ╚══╝  ╚══╝
                                       
    THE BEGINNING  ·  AND THE END      
]],
        },
      },
    },
  },
  { -- under neopane every window is its own Rex pane, which Neovim can't place
    -- on its screen, so the smear's floats land at the pane's left edge
    'sphamba/smear-cursor.nvim',
    cond = vim.g.neopane == nil,
  },
}
