local config = require("config")

---@class items.monitoring.disk
local M = {}

M.button = Sbar.add("graph", "monitoring.disk", 52, {
	position = "right",
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
	Sbar.exec("df -h /System/Volumes/Data | tail -1 | awk '{print $5}'", function(result)
		local disk_used = tonumber(result:match("(%d+)%%"))

		M.button:push({
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

		M.button:set({
			graph = { color = color },
			label = { string = string.format("%.1f%%", disk_used) },
		})
	end)
end)

M.button:subscribe("mouse.clicked", function()
	Sbar.exec("open -a 'Disk Utility'")
end)

return M
