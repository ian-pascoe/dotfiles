-- Snacks picker sources backed by fff (https://github.com/dmtrKovalenko/fff).
-- fff owns indexing, frecency, and ranking; Snacks owns the UI.
-- Opening a file records frecency through fff's own BufEnter autocmd.
--
-- fff indexes one root at a time, and switching roots can hang its new scan
-- for the rest of the session (seen upstream at 8154eec, about 1 in 300
-- switches). So these pickers index the whole git repo once and scope
-- narrower searches (LazyVim root, cwd) with a path filter instead of
-- switching roots. Searching outside the current repo still switches.

local M = {}

local grep_modes = { 'plain', 'regex', 'fuzzy' }

---@param path string
local function real(path)
  return vim.fs.normalize(vim.uv.fs_realpath(path) or path)
end

---@param path string
---@param dir string
local function is_within(path, dir)
  return path == dir or vim.startswith(path, dir .. '/')
end

local initialized = false

---@param root string
local function init_fff(root)
  local core = require('fff.core')
  if not core.is_file_picker_initialized() then
    -- Build fff's first index at `root` rather than nvim's cwd.
    require('fff.conf').get().base_path = root
  end
  core.ensure_initialized()
  -- fff re-indexes on every global :cd; these pickers choose the root themselves.
  for _, au in ipairs(vim.api.nvim_get_autocmds({ group = 'fff_file_tracking', event = 'DirChanged' })) do
    vim.api.nvim_del_autocmd(au.id)
  end
  -- fff's public search API depends on `fff.file_picker` state that only fff's
  -- own UI initialises; without it, searches that switch roots fail with
  -- "timeout waiting for index scan".
  local file_picker = require('fff.file_picker')
  if not file_picker.is_initialized() then
    file_picker.setup()
  end
  initialized = true
end

---@class fff_picker.Scope
---@field root string directory fff indexes
---@field dir string directory the picker searches
---@field rel? string `dir` relative to `root`; nil when they match

--- Reuse the current index when `dir` is inside it; otherwise index `dir`'s git root.
---@param dir string
---@return fff_picker.Scope
local function scope_for(dir)
  dir = real(dir)
  local root
  local current = initialized and require('fff.conf').get().base_path
  if current and is_within(dir, real(current)) then
    root = real(current)
  else
    local git = vim.fs.root(dir, '.git')
    root = git and real(git) or dir
  end
  if not initialized then
    init_fff(root)
  end
  return { root = root, dir = dir, rel = dir ~= root and dir:sub(#root + 2) or nil }
end

--- Whether fff can filter `scope` itself with a `rel/**` glob token. Paths
--- with whitespace or glob characters fall back to filtering in Lua alone.
---@param scope fff_picker.Scope
local function fff_filters(scope)
  return scope.rel ~= nil and not scope.rel:find('[%s%*%?%[%]{}!]')
end

--- fff query for `search` within `scope`.
---@param search string
---@param scope fff_picker.Scope
local function scoped_query(search, scope)
  if fff_filters(scope) then
    return vim.trim(search .. ' ' .. scope.rel .. '/**')
  end
  return search
end

--- Path relative to `scope.dir`, or nil when outside it.
---@param path string path relative to `scope.root`
---@param scope fff_picker.Scope
local function scoped_path(path, scope)
  if not scope.rel then
    return path
  end
  local prefix = scope.rel .. '/'
  return vim.startswith(path, prefix) and path:sub(#prefix + 1) or nil
end

--- Current buffer's path relative to `root`, so fff can deprioritize it.
--- Captured before the picker opens: finders run with the picker focused.
---@param root string
---@return string?
local function current_file(root)
  local name = vim.api.nvim_buf_get_name(0)
  if name == '' or vim.bo.buftype ~= '' then
    return nil
  end
  local file = real(name)
  return is_within(file, root) and file:sub(#root + 2) or nil
end

--- fff returns whatever is indexed so far. While a scan runs, re-run the
--- finder until it settles, as fff's own picker does.
---@param picker snacks.Picker
local function refresh_while_scanning(picker)
  if picker.fff_rescan_pending or not require('fff.file_picker').get_scan_progress().is_scanning then
    return
  end
  picker.fff_rescan_pending = true
  vim.defer_fn(function()
    picker.fff_rescan_pending = nil
    if not picker.closed then
      picker:find()
    end
  end, 150)
end

--- Shared by every source: keep fff's ranking instead of re-sorting by Snacks score.
local base = {
  format = 'file',
  show_empty = true,
  sort = { fields = { 'idx' } },
}

---@param opts? snacks.picker.Config
function M.files(opts)
  opts = opts or {}
  local scope = scope_for(opts.cwd or vim.fn.getcwd())
  local current = current_file(scope.root)
  return Snacks.picker.pick(vim.tbl_deep_extend('force', base, {
    source = 'fff_files',
    title = 'Files (fff)',
    live = true,
    formatters = { file = { filename_first = true } },
    finder = function(o, ctx)
      local limit = o.limit or 100
      local res = require('fff').file_search(scoped_query(ctx.filter.search, scope), {
        cwd = scope.root,
        current_file = current,
        -- Without fff filtering, the path filter below drops out-of-scope matches.
        max_results = (scope.rel and not fff_filters(scope)) and limit * 5 or limit,
      })
      local items = {} ---@type snacks.picker.finder.Item[]
      for _, it in ipairs(res.items) do
        local file = scoped_path(it.relative_path, scope)
        if file and #items < limit then
          items[#items + 1] = { idx = #items + 1, cwd = scope.dir, file = file, text = file }
        end
      end
      refresh_while_scanning(ctx.picker)
      return items
    end,
  }, opts, { cwd = scope.dir }))
end

---@param m table fff grep match
---@param file string path relative to `cwd`
---@param cwd string
---@param idx integer
local function grep_item(m, file, cwd, idx)
  local first = (m.match_ranges or {})[1]
  local positions = {} ---@type integer[]
  for _, r in ipairs(m.match_ranges or {}) do
    -- fff ranges are 0-based, end-exclusive byte offsets; Snacks wants 1-based columns.
    for col = r[1] + 1, r[2] do
      positions[#positions + 1] = col
    end
  end
  return {
    idx = idx,
    cwd = cwd,
    file = file,
    line = m.line_content,
    positions = positions,
    pos = { m.line_number, first and first[1] or 0 },
    end_pos = first and { m.line_number, first[2] } or nil,
    text = file .. ':' .. m.line_number .. ':' .. m.line_content,
  }
end

---@param opts? snacks.picker.Config|{ fff_grep_mode?: integer }
function M.grep(opts)
  opts = opts or {}
  local scope = scope_for(opts.cwd or vim.fn.getcwd())
  return Snacks.picker.pick(vim.tbl_deep_extend('force', base, {
    source = 'fff_grep',
    title = 'Grep (fff: plain)',
    live = true,
    fff_grep_mode = 1,
    finder = function(o, ctx)
      if ctx.filter.search == '' then
        return {}
      end
      local res = require('fff').content_search(scoped_query(ctx.filter.search, scope), {
        cwd = scope.root,
        mode = grep_modes[o.fff_grep_mode],
        page_size = o.limit or 200,
      })
      local items = {} ---@type snacks.picker.finder.Item[]
      for _, m in ipairs(res.items) do
        local file = scoped_path(m.relative_path, scope)
        if file then
          items[#items + 1] = grep_item(m, file, scope.dir, #items + 1)
        end
      end
      refresh_while_scanning(ctx.picker)
      return items
    end,
    actions = {
      fff_cycle_grep_mode = function(picker)
        picker.opts.fff_grep_mode = picker.opts.fff_grep_mode % #grep_modes + 1
        picker.title = 'Grep (fff: ' .. grep_modes[picker.opts.fff_grep_mode] .. ')'
        picker:refresh()
      end,
    },
    win = {
      input = {
        keys = {
          ['<S-Tab>'] = { 'fff_cycle_grep_mode', mode = { 'n', 'i' }, desc = 'Cycle fff grep mode' },
        },
      },
    },
  }, opts, { cwd = scope.dir }))
end

--- Grep the word under the cursor (whole word) or the visual selection (literal).
---@param opts? snacks.picker.Config
function M.grep_word(opts)
  local mode = vim.fn.mode()
  local visual = mode == 'v' or mode == 'V' or mode == '\22'
  local query
  if visual then
    query = table.concat(vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'), { type = mode }), '\n')
    vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'nx', false)
  else
    local word = vim.fn.expand('<cword>')
    -- Escape regex metacharacters so the word matches literally between word boundaries.
    query = word ~= '' and ('\\b' .. word:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?%{%}|\\]', '\\%0') .. '\\b') or ''
  end
  return M.grep(vim.tbl_deep_extend('force', {
    title = 'Grep word (fff)',
    live = false,
    search = query,
    fff_grep_mode = visual and 1 or 2,
  }, opts or {}))
end

return M
