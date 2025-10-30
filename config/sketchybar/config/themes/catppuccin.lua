---@class config.themes.catppuccin
local M = {
	base = 0xff1e1e2e,
	mantle = 0xff181825,
	crust = 0xff11111b,
	surface0 = 0xff313244,
	surface1 = 0xff45475a,
	surface2 = 0xff585b70,
	overlay0 = 0xff6c7086,
	overlay1 = 0xff7f849c,
	overlay2 = 0xff9399b2,
	subtext0 = 0xffa6adc8,
	subtext1 = 0xffbac2de,
	text = 0xffcdd6f4,
	lavender = 0xffb4befe,
	blue = 0xff89b4fa,
	sapphire = 0xff74c7ec,
	sky = 0xff89dceb,
	teal = 0xff94e2d5,
	green = 0xffa6e3a1,
	yellow = 0xfff9e2af,
	peach = 0xfffab387,
	maroon = 0xffeba0ac,
	red = 0xfff38ba8,
	mauve = 0xffcba6f7,
	pink = 0xfff5c2e7,
	flamingo = 0xfff2cdcd,
	rosewater = 0xfff5e0dc,
}

function M.toColors()
	---@type config.colors
	return {
		background = M.base,
		foreground = M.text,
		card = { background = M.surface0, foreground = M.text },
		popup = { background = M.surface1, foreground = M.text },
		primary = { background = M.mauve, foreground = M.base },
		secondary = { background = M.blue, foreground = M.base },
		tertiary = { background = M.sky, foreground = M.base },
		accent = { background = M.lavender, foreground = M.base },
		muted = { background = M.overlay0, foreground = M.base },
		destructive = { background = M.red, foreground = M.base },
		warning = { background = M.yellow, foreground = M.base },
		info = { background = M.sky, foreground = M.base },
		success = { background = M.green, foreground = M.base },
		border = M.overlay1,
	}
end

return M
