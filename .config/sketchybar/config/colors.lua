---@class config.colors
---@field background integer
---@field foreground integer
---@field card {background: integer, foreground: integer}
---@field popup {background: integer, foreground: integer}
---@field primary {background: integer, foreground: integer}
---@field secondary {background: integer, foreground: integer}
---@field tertiary {background: integer, foreground: integer}
---@field accent {background: integer, foreground: integer}
---@field muted {background: integer, foreground: integer}
---@field destructive {background: integer, foreground: integer}
---@field warning {background: integer, foreground: integer}
---@field info {background: integer, foreground: integer}
---@field success {background: integer, foreground: integer}
---@field border integer
local M = require("config.themes").rose_pine.toColors()

M.transparent = 0x00000000

---@type fun(color: integer, alpha?: number): integer
function M.with_alpha(color, alpha)
	if alpha > 1.0 or alpha < 0.0 then
		return color
	end
	return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
end

return M
