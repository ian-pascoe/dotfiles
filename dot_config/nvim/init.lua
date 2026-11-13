-- Enable the module loader before anything is required
vim.loader.enable()

-- Global Utilities
Util = require('util')

-- bootstrap lazy.nvim, LazyVim and your plugins
require('config.lazy')
