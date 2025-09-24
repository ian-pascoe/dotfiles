local config = require("config")

local memory = Sbar.add("graph", "monitoring.memory", 52, {
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
		height = config.settings.bar_height - 20,
	},
	update_freq = 5,
})

memory:subscribe({ "routine", "forced" }, function()
	Sbar.exec("memory_pressure", function(result)
		local total_memory = tonumber(result:match("System%-wide memory free percentage: (%d+)%%"))
		local memory_used = 100 - (total_memory or 0)

		memory:push({
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

		memory:set({
			graph = { color = color },
			label = { string = string.format("%.1f%%", memory_used) },
		})
	end)
end)

memory:subscribe("mouse.clicked", function()
	Sbar.exec("open -a 'Activity Monitor'")
end)

return memory
