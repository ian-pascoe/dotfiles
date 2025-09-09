local config = require("config")

-- Equivalent to the --bar domain
Sbar.bar({
	height = 40,
	color = config.colors.bar.bg,
	border_color = config.colors.bar.border,
	shadow = true,
	sticky = true,
	padding_right = 10,
	padding_left = 10,
	blur_radius = 20,
	topmost = "window",
})
