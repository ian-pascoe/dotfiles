local colors = require("config.colors")

local volume = require("items.control_center.volume")
local battery = require("items.control_center.battery")
local wifi = require("items.control_center.wifi")

Sbar.add("bracket", {
	wifi.name,
	battery.name,
	volume.name,
}, {
	position = "right",
	background = {
		color = colors.with_alpha(colors.background, 0.8),
	},
})
