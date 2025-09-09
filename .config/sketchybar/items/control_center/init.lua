local battery = require("items.control_center.battery")
local wifi = require("items.control_center.wifi")
local volume = require("items.control_center.volume")

local items = {
	battery.name,
	wifi.name,
	volume.icon.name,
}

Sbar.add("bracket", items, {
	position = "right",
	align = "right",
})
