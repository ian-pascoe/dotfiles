local config = require("config")
local settings = config.settings

---@class items.apps
local M = {}

local helium = require("items.apps.helium")
local ghostty = require("items.apps.ghostty")

M.group = Sbar.add("bracket", "apps.group", {
	helium.button.name,
	ghostty.button.name,
}, {
	position = "left",
})

M.spacer = Sbar.add("item", "apps.spacer", {
	position = "left",
	padding_left = settings.paddings.xs,
	padding_right = settings.paddings.xs,
	icon = { drawing = false },
	label = { drawing = false },
})

return M
