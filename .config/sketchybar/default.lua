local settings = require("config.settings")
local colors = require("config.colors")

Sbar.default({
	updates = "when_shown",
	padding_left = settings.paddings,
	padding_right = settings.paddings,
	icon = {
		color = colors.foreground,
		font = {
			family = settings.nerd_font,
			style = "Bold",
			size = 14.0,
		},
		padding_left = settings.paddings / 2,
		padding_right = settings.paddings / 2,
	},
	label = {
		color = colors.foreground,
		font = {
			family = settings.font,
			size = 11.0,
		},
		padding_left = settings.paddings / 2,
		padding_right = settings.paddings / 2,
	},
	background = {
		corner_radius = 10,
		height = settings.bar_height - 8,
	},
	popup = {
		height = 30,
		horizontal = false,
		background = {
			border_color = colors.border,
			border_width = 1,
			color = colors.popup.background,
			corner_radius = 10,
			shadow = { drawing = true },
		},
	},
})
