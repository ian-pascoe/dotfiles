local config = require("config")

---@class items.monitoring.memory
local M = {}

M.button = Sbar.add("graph", "monitoring.memory", 52, {
	position = "right",
	padding_left = 4,
	padding_right = 4,
	graph = {
		color = config.colors.accent.background,
	},
	icon = {
		string = config.icons.memory,
		font = {
			size = 10,
		},
		width = 0,
		align = "left",
		padding_left = 3,
		padding_right = 0,
		y_offset = 2,
	},
	label = {
		string = "??%",
		font = {
			size = 8.0,
		},
		width = 0,
		align = "right",
		padding_left = 0,
		padding_right = 3,
		y_offset = 2,
	},
	background = {
		drawing = true,
		height = config.settings.heights.graph,
		corner_radius = 5,
	},
	update_freq = 5,
})
M.button:subscribe("mouse.entered", function()
	M.button:set({
		background = { color = config.colors.with_alpha(config.colors.secondary.background, 0.25) },
	})
end)
M.button:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
	M.button:set({
		background = { color = config.colors.transparent },
	})
end)

M.button:subscribe({ "routine", "forced" }, function()
	Sbar.exec("memory_pressure", function(result)
		local total_memory = tonumber(result:match("System%-wide memory free percentage: (%d+)%%"))
		local memory_used = 100 - (total_memory or 0)

		M.button:push({
			memory_used / 100,
		})

		local color = config.colors.success.background
		if memory_used > 30 then
			if memory_used < 60 then
				color = config.colors.info.background
			elseif memory_used < 80 then
				color = config.colors.warning.background
			else
				color = config.colors.destructive.background
			end
		end

		M.button:set({
			graph = { color = color },
			label = { string = string.format("%.1f%%", memory_used) },
		})
	end)
end)

M.button:subscribe("mouse.clicked", function()
	Sbar.exec("open -a 'Activity Monitor'")
end)

return M
