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
})

local disk = require("items.monitoring.disk")
local memory = require("items.monitoring.memory")
local cpu = require("items.monitoring.cpu")

local items_shown = false
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
