local config = require("config")

Sbar.add("item", "spacer." .. math.random(1, 1000), {
	position = "right",
	padding_left = config.settings.paddings / 2,
	padding_right = config.settings.paddings / 2,
	icon = { drawing = false },
	label = { drawing = false },
})

local microphone = require("items.control_center.microphone")
local volume = require("items.control_center.volume")
local battery = require("items.control_center.battery")
local wifi = require("items.control_center.wifi")

Sbar.add("bracket", {
	wifi.name,
	battery.name,
	volume.button.name,
	microphone.button.name,
}, {
	position = "right",
	background = {
		color = config.colors.with_alpha(config.colors.background, 0.8),
	},
})
