local config = require("config")
local icons = config.icons

local Button = require("components.button")

---@class items.apps.helium
local M = {}

--- Keeps track of whether the mouse is still hovering over the button
local still_hovering = false

M.button = Button:new("apps.helium.button", "outline", {
	position = "left",
	icon = { string = icons.map("Helium") },
	label = { drawing = false },
	popup = {
		drawing = false,
		align = "center",
	},
})

M.tooltip = Sbar.add("item", "apps.helium.tooltip", {
	position = "popup." .. M.button.name,
	icon = { drawing = false },
	label = {
		string = "Helium Browser",
	},
})

M.button:on_hover(function(hovering)
	still_hovering = hovering
	if hovering then
		Sbar.delay(0.5, function()
			if still_hovering then
				M.button:set({
					popup = { drawing = true },
				})
			end
		end)
	else
		M.button:set({
			popup = { drawing = false },
		})
	end
end)

M.button:on_click(function()
	Sbar.exec("open -na Helium")
end)

return M
