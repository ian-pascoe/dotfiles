local config = require("config")

---@class items.monitoring.disk
local M = {}

M.graph = Sbar.add("graph", "monitoring.disk", 52, {
	drawing = false,
	position = "right",
	width = 0,
	padding_left = 4,
	padding_right = 8,
	graph = {
		color = config.colors.accent.background,
	},
	icon = {
		string = config.icons.disk,
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
	update_freq = 30,
})
M.graph:subscribe("mouse.entered", function()
	M.graph:set({
		background = { color = config.colors.with_alpha(config.colors.secondary.background, 0.25) },
	})
end)
M.graph:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
	M.graph:set({
		background = { color = config.colors.transparent },
	})
end)

M.graph:subscribe({ "routine", "forced" }, function()
	Sbar.exec("df -h /System/Volumes/Data | tail -1 | awk '{print $5}'", function(result)
		local disk_used = tonumber(result:match("(%d+)%%"))

		M.graph:push({
			disk_used / 100,
		})

		local color = config.colors.success.background
		if disk_used > 50 then
			if disk_used < 70 then
				color = config.colors.info.background
			elseif disk_used < 85 then
				color = config.colors.warning.background
			else
				color = config.colors.destructive.background
			end
		end

		M.graph:set({
			graph = { color = color },
			label = { string = string.format("%.1f%%", disk_used) },
		})
	end)
end)

M.graph:subscribe("mouse.clicked", function()
	Sbar.exec("open -a 'Disk Utility'")
end)

return M
