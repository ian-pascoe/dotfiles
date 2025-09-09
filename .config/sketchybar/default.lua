local settings = require("config.settings")
local colors = require("config.colors")

-- Equivalent to the --default domain
Sbar.default({
	updates = "when_shown",
	icon = {
		color = colors.foreground,
		font = {
			family = settings.nerd_font,
			style = "Bold",
			size = 18.0,
		},
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	label = {
		color = colors.foreground,
		font = {
			family = settings.font,
			size = 14.0,
		},
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	background = {
		corner_radius = 9,
		height = 30,
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	popup = {
		height = 30,
		horizontal = false,
		background = {
			border_color = colors.border,
			border_width = 2,
			color = colors.popup.background,
			corner_radius = 11,
			shadow = {
				drawing = true,
			},
		},
	},
})
