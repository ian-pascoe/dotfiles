local config = require("config")
local settings = config.settings

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

M.padding = Sbar.add("item", "control_center.padding", {
	position = "right",
	padding_left = config.settings.paddings.xs,
	padding_right = config.settings.paddings.xs,
	icon = { drawing = false },
	label = { drawing = false },
})

M.button = require("components.button"):new("control_center.button", "ghost", {
	position = "right",
	icon = { string = config.icons.control_center },
	label = { drawing = false },
})

local microphone = require("items.control_center.microphone")
local volume = require("items.control_center.volume")
local bluetooth = require("items.control_center.bluetooth")
local battery = require("items.control_center.battery")
local wifi = require("items.control_center.wifi")

local controls_shown = false
M.button:on_click(function()
	if controls_shown then
		controls_shown = false
		Sbar.animate("tanh", 20, function()
			microphone.button:set({ width = 0 })
			volume.button:set({ width = 0 })
			bluetooth.button:set({ width = 0 })
			battery.button:set({ width = 0 })
			wifi.button:set({ width = 0 })
			M.button:set({
				icon = {
					string = config.icons.control_center,
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
		controls_shown = true
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
		color = config.colors.with_alpha(config.colors.background, 0.8),
	},
})

return M
