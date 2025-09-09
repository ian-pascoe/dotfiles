Util = require("util")

---@class config
---@field colors config.colors
---@field icons config.icons
---@field settings config.settings
local M = {}

setmetatable(M, {
	__index = function(t, k)
		local ok, mod = pcall(require, "config." .. k)
		if ok then
			rawset(t, k, mod)
			return mod
		else
			error("No such config module: " .. k)
		end
	end,
})

return M
