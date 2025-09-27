---@class util
---@field sketchybar util.sketchybar
---@field battery util.battery
---@field json util.json
local M = {}

setmetatable(M, {
	__index = function(_, key)
		local ok, module = pcall(require, "util." .. key)
		if ok then
			rawset(M, key, module)
			return module
		else
			error("Module 'util." .. key .. "' not found")
		end
	end,
})

--- Splits a string into a table based on a given separator.
---@param inputstr string
---@param sep string|nil
---@return string[]
function M.split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

--- Applies a function to each element of a table and returns a new table with the results.
---@generic T, U
---@param func fun(T): U
---@param tbl T[]
---@return U[]
function M.map(func, tbl)
	local result = {}
	for i, v in ipairs(tbl) do
		result[i] = func(v)
	end
	return result
end

--- Removes duplicate values from a table while preserving order.
---@generic T
---@param t T[]
---@return T[]
function M.deduplicate(t)
	local seen = {}
	local res = {}

	for _, v in ipairs(t) do
		if not seen[v] then
			seen[v] = true
			res[#res + 1] = v
		end
	end

	return res
end

--- Trims leading and trailing whitespace from a string.
---@param s string
---@return string
function M.trim(s)
	return s:match("^%s*(.-)%s*$") or s
end

--- Sleeps for a specified number of seconds (blocking).
---@param seconds number
function M.sleep(seconds)
	local start = os.time()
	while os.time() - start < seconds do
	end
end

--- Deeply extends a destination table with one or more source tables.
---@param dest table
---@param ... table
---@return table
function M.tbl_deep_extend(dest, ...)
	local sources = { ... }
	for i = 1, #sources do
		local src = sources[i]
		for k, v in pairs(src) do
			if type(v) == "table" then
				if type(dest[k] or false) == "table" then
					M.tbl_deep_extend(dest[k], v)
				else
					dest[k] = v
				end
			else
				dest[k] = v
			end
		end
	end
	return dest
end

--- Creates a deep copy of a table.
---@param orig table
---@return table
function M.tbl_deep_copy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == "table" then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[M.tbl_deep_copy(orig_key)] = M.tbl_deep_copy(orig_value)
		end
		setmetatable(copy, M.tbl_deep_copy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

--- Creates a shallow copy of a table.
---@param orig table
---@return table
function M.tbl_shallow_copy(orig)
	local copy = {}
	for k, v in pairs(orig) do
		copy[k] = v
	end
	return copy
end

--- Returns a list of keys in a table.
---@param t table
---@return string[]
function M.tbl_keys(t)
	local keys = {}
	for k, _ in pairs(t) do
		table.insert(keys, k)
	end
	return keys
end

--- Checks if a table is empty.
---@param t table
---@return boolean
function M.tbl_is_empty(t)
	return next(t) == nil
end

return M
