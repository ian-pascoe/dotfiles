local config = require("config")

-- Equivalent to the --default domain
Sbar.default({
	updates = "when_shown",
	icon = {
		font = {
			family = config.settings.font,
			style = "Bold",
			size = 14.0,
		},
		color = config.colors.white,
		padding_left = config.settings.paddings,
		padding_right = config.settings.paddings,
	},
	label = {
		font = {
			family = config.settings.font,
			style = "Semibold",
			size = 13.0,
		},
		color = config.colors.white,
		padding_left = config.settings.paddings,
		padding_right = config.settings.paddings,
	},
	background = {
		height = 26,
		corner_radius = 9,
		border_width = 2,
	},
	popup = {
		background = {
			border_width = 2,
			corner_radius = 9,
			border_color = config.colors.popup.border,
			color = config.colors.popup.bg,
			shadow = { drawing = true },
		},
		blur_radius = 20,
	},
	padding_left = 5,
	padding_right = 5,
})
