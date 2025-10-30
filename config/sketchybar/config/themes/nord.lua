---@class config.themes.nord
local M = {
	nord0 = 0xff2e3440,
	nord1 = 0xff3b4252,
	nord2 = 0xff434c5e,
	nord3 = 0xff4c566a,
	nord4 = 0xffd8dee9,
	nord5 = 0xffe5e9f0,
	nord6 = 0xffeceff4,
	nord7 = 0xff8fbcbb,
	nord8 = 0xff88c0d0,
	nord9 = 0xff81a1c1,
	nord10 = 0xff5e81ac,
	nord11 = 0xffbf616a,
	nord12 = 0xffd08770,
	nord13 = 0xffebcb8b,
	nord14 = 0xffa3be8c,
	nord15 = 0xffb48ead,
}

function M.toColors()
	---@type config.colors
	return {
		background = M.nord0,
		foreground = M.nord6,
		card = { background = M.nord1, foreground = M.nord6 },
		popup = { background = M.nord2, foreground = M.nord6 },
		primary = { background = M.nord8, foreground = M.nord0 },
		secondary = { background = M.nord9, foreground = M.nord0 },
		tertiary = { background = M.nord10, foreground = M.nord0 },
		accent = { background = M.nord7, foreground = M.nord0 },
		muted = { background = M.nord3, foreground = M.nord0 },
		info = { background = M.nord7, foreground = M.nord0 },
		success = { background = M.nord14, foreground = M.nord0 },
		warning = { background = M.nord13, foreground = M.nord0 },
		destructive = { background = M.nord11, foreground = M.nord0 },
		border = M.nord3,
	}
end

return M
