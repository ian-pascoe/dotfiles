local colors = require("config.colors")
local settings = require("config.settings")

Sbar.bar({
	position = "top",
	sticky = true,
	topmost = false,
	height = settings.bar_height,
	margin = 10,
	y_offset = 10,
	corner_radius = 8,
	padding_right = 0,
	padding_left = 0,
	color = colors.with_alpha(colors.background, 0.8),
	blur_radius = 20,
	border_color = colors.border,
	border_width = 1,
	shadow = true,
})
