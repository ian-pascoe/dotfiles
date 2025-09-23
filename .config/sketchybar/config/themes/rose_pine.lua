---@class config.themes.rose_pine
local M = {
	base = 0xff191724,
	surface = 0xff1f1d2e,
	overlay = 0xff26233a,
	muted = 0xff6e6a86,
	subtle = 0xff908caa,
	text = 0xffe0def4,
	love = 0xffeb6f92,
	gold = 0xfff6c177,
	rose = 0xffebbcba,
	pine = 0xff31748f,
	foam = 0xff9ccfd8,
	iris = 0xffc4a7e7,
	highlight_low = 0xff21202e,
	highlight_med = 0xff403d52,
	highlight_high = 0xff524f67,
}

function M.toColors()
	---@type config.colors
	return {
		background = M.base,
		foreground = M.text,
		card = { background = M.surface, foreground = M.text },
		popup = { background = M.overlay, foreground = M.text },
		primary = { background = M.rose, foreground = M.base },
		secondary = { background = M.pine, foreground = M.base },
		tertiary = { background = M.foam, foreground = M.base },
		accent = { background = M.iris, foreground = M.base },
		muted = { background = M.muted, foreground = M.base },
		destructive = { background = M.love, foreground = M.base },
		warning = { background = M.gold, foreground = M.base },
		info = { background = M.foam, foreground = M.base },
		success = { background = M.pine, foreground = M.base },
		border = M.highlight_med,
	}
end

return M
