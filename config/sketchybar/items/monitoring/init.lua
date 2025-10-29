local config = require("config")
local icons = config.icons
local colors = config.colors
local settings = config.settings

local Button = require("components.button")

---@class items.monitoring
local M = {}

setmetatable(M, {
	__index = function(_, key)
		local ok, module = pcall(require, "items.monitoring." .. key)
		if ok then
			rawset(M, key, module)
			return module
		else
			error("Module 'items.monitoring." .. key .. "' not found")
		end
	end,
})

--- Whether the monitoring items are currently shown
local items_shown = false

--- Keeps track of whether the mouse is still hovering over the button
local still_hovering = false

M.spacer = Sbar.add("item", "monitoring.spacer", {
	position = "right",
	padding_left = settings.paddings.xs,
	padding_right = settings.paddings.xs,
	icon = { drawing = false },
	label = { drawing = false },
})

M.button = Button:new("monitoring.button", "ghost", {
	position = "right",
	icon = { string = icons.monitoring },
	label = { drawing = false },
	popup = {
		drawing = false,
		align = "center",
	},
})

M.tooltip = Sbar.add("item", "monitoring.tooltip", {
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
					label = { string = items_shown and "Collapse" or "Monitoring" },
				})
			end
		end)
	else
		M.button:set({
			popup = { drawing = false },
		})
	end
end)

local disk = require("items.monitoring.disk")
local memory = require("items.monitoring.memory")
local cpu = require("items.monitoring.cpu")

M.button:on_click(function()
	if items_shown then
		items_shown = false
		Sbar.animate("tanh", 20, function()
			disk.graph:set({ width = 0 })
			memory.graph:set({ width = 0 })
			cpu.graph:set({ width = 0 })
			M.button:set({
				icon = {
					string = icons.monitoring,
				},
			})
		end)
		Sbar.delay(0.21, function()
			disk.graph:set({ drawing = false })
			memory.graph:set({ drawing = false })
			cpu.graph:set({ drawing = false })
		end)
	else
		items_shown = true
		Sbar.animate("tanh", 20, function()
			M.button:set({
				icon = {
					string = "",
				},
			})
			disk.graph:set({ drawing = true })
			memory.graph:set({ drawing = true })
			cpu.graph:set({ drawing = true })

			disk.graph:set({ width = "dynamic" })
			memory.graph:set({ width = "dynamic" })
			cpu.graph:set({ width = "dynamic" })
		end)
	end
end)

Sbar.add("bracket", "monitoring", {
	cpu.graph.name,
	memory.graph.name,
	disk.graph.name,
	M.button.name,
}, {
	position = "right",
	background = {
		color = colors.background,
	},
})

return M
