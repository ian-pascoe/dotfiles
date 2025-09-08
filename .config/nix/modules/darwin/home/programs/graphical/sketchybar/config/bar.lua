local colors = require("colors")

local bar_height = 40

-- Equivalent to the --bar domain
Sbar.bar({
	blur_radius = 30,
	border_color = colors.bar.border,
	border_width = 2,
	color = colors.bar.bg,
	corner_radius = 9,
	height = bar_height,
	margin = 10,
	notch_width = 0,
	padding_left = 18,
	padding_right = 10,
	position = "top",
	shadow = true,
	sticky = true,
	topmost = false,
	y_offset = 10,
})
