-- Web formatters: oxfmt, Biome and Prettier come from LazyVim extras
-- (typescript.oxc, typescript.biome, formatting.prettier), and each is gated
-- on its own config file. In a repo with more than one config, conform would
-- run them back to back, so only the first available one runs, in this order.
local exclusive = { 'oxfmt', 'biome-check', 'prettier' }

-- oxfmt formats more than the oxc extra registers it for.
local oxfmt_extra_fts = {
  'angular',
  'css',
  'ember',
  'graphql',
  'handlebars',
  'html',
  'less',
  'markdown',
  'markdown.mdx',
  'scss',
  'yaml',
}

-- conform's oxfmt also treats vite.config.* as a config, which would run it in
-- any Vite project; require oxfmt's own config instead.
local oxfmt_configs = { '.oxfmtrc.json', '.oxfmtrc.jsonc', 'oxfmt.config.ts' }

---@param list string[]
---@return string[]
local function dedupe(list)
  local seen, ret = {}, {}
  for _, name in ipairs(list) do
    if not seen[name] then
      seen[name] = true
      ret[#ret + 1] = name
    end
  end
  return ret
end

--- Formatters for `list` with only the first available exclusive one, in the
--- place of the first exclusive entry.
---@param list string[]
---@return fun(bufnr: integer): string[]
local function one_web_formatter(list)
  return function(bufnr)
    local conform = require('conform')
    local chosen
    for _, name in ipairs(exclusive) do
      if vim.tbl_contains(list, name) and conform.get_formatter_info(name, bufnr).available then
        chosen = name
        break
      end
    end
    local ret, placed = {}, false
    for _, name in ipairs(list) do
      if not vim.tbl_contains(exclusive, name) then
        ret[#ret + 1] = name
      elseif not placed then
        placed = true
        ret[#ret + 1] = chosen
      end
    end
    return ret
  end
end

return {
  {
    'stevearc/conform.nvim',
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs(oxfmt_extra_fts) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        table.insert(opts.formatters_by_ft[ft], 'oxfmt')
      end

      opts.formatters = opts.formatters or {}
      opts.formatters.oxfmt = vim.tbl_extend('force', opts.formatters.oxfmt or {}, {
        condition = function(_, ctx)
          return vim.fs.root(ctx.filename, oxfmt_configs) ~= nil
        end,
      })

      for ft, list in pairs(opts.formatters_by_ft) do
        if type(list) == 'table' and vim.islist(list) then
          list = dedupe(list)
          local count = 0
          for _, name in ipairs(list) do
            count = count + (vim.tbl_contains(exclusive, name) and 1 or 0)
          end
          opts.formatters_by_ft[ft] = count > 1 and one_web_formatter(list) or list
        end
      end
    end,
  },
}
