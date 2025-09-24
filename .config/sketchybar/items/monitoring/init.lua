local config = require("config")

Sbar.add("item", "spacer." .. math.random(1, 1000), {
	position = "right",
	padding_left = config.settings.paddings / 2,
	padding_right = config.settings.paddings / 2,
	icon = { drawing = false },
	label = { drawing = false },
})

local disk = require("items.monitoring.disk")
local memory = require("items.monitoring.memory")
local cpu = require("items.monitoring.cpu")

Sbar.add("bracket", "monitoring", {
	cpu.name,
	memory.name,
	disk.name,
}, {
	position = "right",
	background = {
		color = config.colors.background,
	},
})
