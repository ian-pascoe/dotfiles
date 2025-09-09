---@class util
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

return M
