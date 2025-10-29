local config = require("config")
local colors = config.colors
local icons = config.icons
local settings = config.settings

local Button = require("components.button")

---@class items.control_center
local M = {}

setmetatable(M, {
	__index = function(_, key)
		local ok, module = pcall(require, "items.control_center." .. key)
		if ok then
			rawset(M, key, module)
			return module
		else
			error("Module 'items.control_center." .. key .. "' not found")
		end
	end,
})

--- Whether the control center items are currently shown.
local items_shown = false

--- Keeps track of whether the mouse is still hovering over the button.
local still_hovering = false

M.spacer = Sbar.add("item", "control_center.spacer", {
	position = "right",
	padding_left = settings.paddings.xs,
	padding_right = settings.paddings.xs,
	icon = { drawing = false },
	label = { drawing = false },
})

M.button = Button:new("control_center.button", "ghost", {
	position = "right",
	icon = { string = icons.control_center },
	label = { drawing = false },
	popup = {
		drawing = false,
		align = "center",
	},
})

M.tooltip = Sbar.add("item", "control_center.tooltip", {
	position = "popup." .. M.button.name,
	icon = { drawing = false },
})

M.button:on_hover(function(hovering)
	still_hovering = hovering
	if hovering then
		Sbar.delay(0.5, function()
			if still_hovering then
				M.button:set({
					popup = { drawing = true },
				})
				M.tooltip:set({
					label = { string = items_shown and "Collapse" or "Control Center" },
				})
			end
		end)
	else
		M.button:set({
			popup = { drawing = false },
		})
	end
end)

local microphone = require("items.control_center.microphone")
local volume = require("items.control_center.volume")
local bluetooth = require("items.control_center.bluetooth")
local battery = require("items.control_center.battery")
local wifi = require("items.control_center.wifi")

M.button:on_click(function()
	if items_shown then
		items_shown = false
		Sbar.animate("tanh", 20, function()
			microphone.button:set({ width = 0 })
			volume.button:set({ width = 0 })
			bluetooth.button:set({ width = 0 })
			battery.button:set({ width = 0 })
			wifi.button:set({ width = 0 })
			M.button:set({
				icon = {
					string = icons.control_center,
				},
			})
		end)
		Sbar.delay(0.21, function()
			microphone.button:set({ drawing = false })
			volume.button:set({ drawing = false })
			bluetooth.button:set({ drawing = false })
			battery.button:set({ drawing = false })
			wifi.button:set({ drawing = false })
		end)
	else
		items_shown = true
		Sbar.animate("tanh", 20, function()
			M.button:set({
				icon = {
					string = "",
				},
			})
			microphone.button:set({ drawing = true })
			volume.button:set({ drawing = true })
			bluetooth.button:set({ drawing = true })
			battery.button:set({ drawing = true })
			wifi.button:set({ drawing = true })

			microphone.button:set({ width = "dynamic" })
			volume.button:set({ width = "dynamic" })
			bluetooth.button:set({ width = "dynamic" })
			battery.button:set({ width = "dynamic" })
			wifi.button:set({ width = "dynamic" })
		end)
	end
end)

M.group = Sbar.add("bracket", "control_center.group", {
	wifi.button.name,
	battery.button.name,
	bluetooth.button.name,
	volume.button.name,
	microphone.button.name,
	M.button.name,
}, {
	position = "right",
	background = {
		color = colors.with_alpha(colors.background, 0.8),
	},
})

return M
