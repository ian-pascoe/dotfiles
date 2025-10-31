------------------------------------
--- Tokyo Night Moon Color Palette
--- https://github.com/folke/tokyonight.nvim
--- Background      #222436
--- Surface         #1e2030
--- Surface Bright  #2f334d
--- Foreground      #c8d3f5
--- Muted           #828bb8
--- Border          #589ed7
--- Blue            #82aaff
--- Cyan            #0db9d7
--- Sky Blue        #86e1fc
--- Green           #c3e88d
--- Orange          #ff966c
--- Yellow          #ffc777
--- Pink            #fca7ea
--- Purple          #c099ff
--- Red             #ff757f
--- Teal            #4fd6be
-------------------------------------

---@class config.themes.tokyonight
local M = {
	background = 0xff222436,
	surface = 0xff1e2030,
	surface_bright = 0xff2f334d,
	foreground = 0xffc8d3f5,
	muted = 0xff828bb8,
	border = 0xff589ed7,
	blue = 0xff82aaff,
	cyan = 0xff0db9d7,
	sky_blue = 0xff86e1fc,
	green = 0xffc3e88d,
	orange = 0xffff966c,
	yellow = 0xffffc777,
	pink = 0xfffca7ea,
	purple = 0xffc099ff,
	red = 0xffff757f,
	teal = 0xff4fd6be,
}

function M.toColors()
	---@type config.colors
	return {
		background = M.background,
		foreground = M.foreground,
		card = { background = M.surface, foreground = M.foreground },
		popup = { background = M.surface_bright, foreground = M.foreground },
		primary = { background = M.blue, foreground = M.background },
		secondary = { background = M.cyan, foreground = M.background },
		tertiary = { background = M.purple, foreground = M.background },
		accent = { background = M.pink, foreground = M.background },
		muted = { background = M.muted, foreground = M.background },
		info = { background = M.sky_blue, foreground = M.background },
		success = { background = M.green, foreground = M.background },
		warning = { background = M.yellow, foreground = M.background },
		destructive = { background = M.red, foreground = M.background },
		border = M.border,
	}
end

return M
