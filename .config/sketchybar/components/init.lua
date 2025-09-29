---@class components
---@field button components.button
local M = {}

setmetatable(M, {
	__index = function(_, key)
		local ok, module = pcall(require, "components." .. key)
		if ok then
			rawset(M, key, module)
			return module
		else
			error("Module 'components." .. key .. "' not found")
		end
	end,
})

return M
