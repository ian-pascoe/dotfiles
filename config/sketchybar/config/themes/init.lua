---@class Theme
---@field toColors fun(): config.colors

---@class config.themes
---@field rose_pine config.themes.rose_pine
---@field nord config.themes.nord
local M = {}

setmetatable(M, {
	__index = function(t, k)
		local ok, mod = pcall(require, "config.themes." .. k)
		if ok then
			rawset(t, k, mod)
			return mod
		else
			error("No such theme: " .. k)
		end
	end,
})

return M
