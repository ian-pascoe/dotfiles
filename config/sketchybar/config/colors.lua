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
local M = {}

---@type "rose-pine" | "nord" | nil
M.theme = nil

M.setup = function()
	local get_theme_handle = io.popen("readlink ~/.config/theme | xargs basename")
	M.theme = "rose-pine"
	if get_theme_handle then
		M.theme = get_theme_handle:read("*a"):gsub("\n", "")
		get_theme_handle:close()
	end
	print("Using theme: " .. M.theme)

	local colors
	if M.theme == "nord" then
		colors = require("config.themes").nord.toColors()
	else
		colors = require("config.themes").rose_pine.toColors()
	end

	for k, v in pairs(colors) do
		M[k] = v
	end
end

M.transparent = 0x00000000
M.white = 0xffffffff
M.black = 0xff000000

---@type fun(color: integer, alpha?: number): integer
function M.with_alpha(color, alpha)
	if alpha > 1.0 or alpha < 0.0 then
		return color
	end
	return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
end

return M
