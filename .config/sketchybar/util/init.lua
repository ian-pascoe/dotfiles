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

return M
