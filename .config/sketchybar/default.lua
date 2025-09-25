local settings = require("config.settings")
local colors = require("config.colors")

Sbar.default({
	updates = "when_shown",
	padding_left = settings.paddings.md,
	padding_right = settings.paddings.md,
	icon = {
		color = colors.foreground,
		font = {
			family = settings.fonts.nerd,
			style = "Bold",
			size = 14.0,
		},
		padding_left = settings.paddings.xs,
		padding_right = settings.paddings.xs,
	},
	label = {
		color = colors.foreground,
		font = {
			family = settings.fonts.regular,
			size = 11.0,
		},
		padding_left = settings.paddings.xs,
		padding_right = settings.paddings.xs,
	},
	background = {
		corner_radius = 10,
		height = settings.heights.widget,
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
