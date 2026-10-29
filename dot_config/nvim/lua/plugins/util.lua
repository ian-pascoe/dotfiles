local function in_herdr()
  return vim.env.HERDR_PANE_ID ~= nil or vim.env.HERDR_ENV == '1' or vim.env.HERDR_SOCKET_PATH ~= nil
end

local function in_tmux()
  return vim.env.TMUX ~= nil
end

local function in_tern()
  return vim.env.TERN_PANE ~= nil and not in_herdr() and not in_tmux()
end

local function in_rex()
  return vim.env.REX_BLOCK ~= nil and not in_herdr() and not in_tmux() and not in_tern()
end

local function herdr_navigate(wincmd, dir)
  return function()
    local prev = vim.api.nvim_get_current_win()
    vim.cmd('wincmd ' .. wincmd)
    if vim.api.nvim_get_current_win() ~= prev then
      return
    end

    local herdr = vim.env.HERDR_BIN_PATH or 'herdr'
    if vim.fn.executable(herdr) ~= 1 then
      return
    end

    vim.fn.system({ herdr, 'pane', 'focus', '--direction', dir, '--current' })
  end
end

local herdr_navigation_keys = {
  { '<c-h>', herdr_navigate('h', 'left'), desc = 'Navigate left' },
  { '<c-j>', herdr_navigate('j', 'down'), desc = 'Navigate down' },
  { '<c-k>', herdr_navigate('k', 'up'), desc = 'Navigate up' },
  { '<c-l>', herdr_navigate('l', 'right'), desc = 'Navigate right' },
}

-- Rex hands ctrl+h/j/k/l to Vim (dot_config/rex/init.lua); at a split edge,
-- `rex focus` moves to the Rex pane beside this terminal.
local function rex_navigate(wincmd, dir)
  return function()
    local prev = vim.api.nvim_get_current_win()
    vim.cmd('wincmd ' .. wincmd)
    if vim.api.nvim_get_current_win() ~= prev or vim.fn.executable('rex') ~= 1 then
      return
    end
    vim.system({ 'rex', 'focus', dir })
  end
end

local rex_navigation_keys = {
  { '<c-h>', rex_navigate('h', 'left'), desc = 'Navigate left' },
  { '<c-j>', rex_navigate('j', 'down'), desc = 'Navigate down' },
  { '<c-k>', rex_navigate('k', 'up'), desc = 'Navigate up' },
  { '<c-l>', rex_navigate('l', 'right'), desc = 'Navigate right' },
}

-- Tern has no directional focus command, so find the pane beside ours in the
-- tab's split tree (`tern ls --json`) and `tern focus` it. Rects are in tab
-- fractions: a Row split is side by side, a Column split stacked.
local function tern_leaves(node, x0, y0, x1, y1, out)
  if node.Leaf then
    out[#out + 1] = { id = node.Leaf, x0 = x0, y0 = y0, x1 = x1, y1 = y1 }
    return out
  end
  local split = node.Split
  local ratio = split.ratio or 0.5
  if split.axis == 'Row' then
    local mid = x0 + (x1 - x0) * ratio
    tern_leaves(split.a, x0, y0, mid, y1, out)
    tern_leaves(split.b, mid, y0, x1, y1, out)
  else
    local mid = y0 + (y1 - y0) * ratio
    tern_leaves(split.a, x0, y0, x1, mid, out)
    tern_leaves(split.b, x0, mid, x1, y1, out)
  end
  return out
end

local function tern_neighbor(leaves, me, dir)
  local eps = 1e-6
  local horizontal = dir == 'left' or dir == 'right'
  local center = horizontal and (me.y0 + me.y1) / 2 or (me.x0 + me.x1) / 2
  local best, best_score
  for _, leaf in ipairs(leaves) do
    local touches = (dir == 'left' and math.abs(leaf.x1 - me.x0) < eps)
      or (dir == 'right' and math.abs(leaf.x0 - me.x1) < eps)
      or (dir == 'up' and math.abs(leaf.y1 - me.y0) < eps)
      or (dir == 'down' and math.abs(leaf.y0 - me.y1) < eps)
    local lo = horizontal and math.max(leaf.y0, me.y0) or math.max(leaf.x0, me.x0)
    local hi = horizontal and math.min(leaf.y1, me.y1) or math.min(leaf.x1, me.x1)
    if touches and hi - lo > eps then
      -- Prefer the pane level with our middle, then the widest overlap.
      local a, b = horizontal and leaf.y0 or leaf.x0, horizontal and leaf.y1 or leaf.x1
      local score = (a <= center and center < b and 1 or 0) + (hi - lo)
      if not best_score or score > best_score then
        best, best_score = leaf, score
      end
    end
  end
  return best
end

local function tern_navigate(wincmd, dir)
  return function()
    local prev = vim.api.nvim_get_current_win()
    vim.cmd('wincmd ' .. wincmd)
    if vim.api.nvim_get_current_win() ~= prev or vim.fn.executable('tern') ~= 1 then
      return
    end

    local result = vim.system({ 'tern', 'ls', '--json' }, { text = true }):wait(2000)
    local ok, ls = pcall(vim.json.decode, result.stdout or '')
    if result.code ~= 0 or not ok or type(ls) ~= 'table' then
      return
    end
    local pane = tonumber(vim.env.TERN_PANE)
    for _, session in ipairs(ls.sessions or {}) do
      for _, tab in ipairs(session.tabs or {}) do
        local leaves = tern_leaves(tab.splits, 0, 0, 1, 1, {})
        for _, leaf in ipairs(leaves) do
          if leaf.id == pane then
            local target = not tab.zoomed and tern_neighbor(leaves, leaf, dir)
            if target then
              vim.system({ 'tern', 'focus', string.format('%d', target.id) })
            end
            return
          end
        end
      end
    end
  end
end

local tern_navigation_keys = {
  { '<c-h>', tern_navigate('h', 'left'), desc = 'Navigate left' },
  { '<c-j>', tern_navigate('j', 'down'), desc = 'Navigate down' },
  { '<c-k>', tern_navigate('k', 'up'), desc = 'Navigate up' },
  { '<c-l>', tern_navigate('l', 'right'), desc = 'Navigate right' },
}

local tmux_navigation_keys = {
  { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
  { '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
  { '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
  { '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
}

return {
  {
    'christoomey/vim-tmux-navigator',
    enabled = in_tmux() or in_herdr() or in_tern() or in_rex(),
    lazy = false,
    init = function()
      if in_herdr() or in_tern() or in_rex() then
        vim.g.tmux_navigator_no_mappings = 1
      end
    end,
    keys = in_herdr() and herdr_navigation_keys or in_tern() and tern_navigation_keys or in_rex() and rex_navigation_keys or tmux_navigation_keys,
  },
  { -- vim learning game
    'ThePrimeagen/vim-be-good',
    cmd = 'VimBeGood',
  },
  {
    'ThePrimeagen/refactoring.nvim',
    dependencies = {
      'lewis6991/async.nvim',
    },
    lazy = false,
  },
}
