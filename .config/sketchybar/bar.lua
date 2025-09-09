local config = require("config")

-- Equivalent to the --bar domain
Sbar.bar({
	height = 40,
	color = config.colors.with_alpha(config.colors.background, 0.5),
	border_color = config.colors.border,
	border_width = 1,
	margin = 10,
	y_offset = 10,
	corner_radius = 10,
	shadow = true,
	sticky = true,
	padding_right = 10,
	padding_left = 10,
	blur_radius = 20,
	topmost = false,
})
