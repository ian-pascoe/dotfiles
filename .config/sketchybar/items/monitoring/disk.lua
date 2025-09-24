local config = require("config")

local disk = Sbar.add("graph", "monitoring.disk", 42, {
	position = "right",
	padding_left = 4,
	padding_right = 4,
	graph = {
		color = config.colors.accent.background,
	},
	icon = {
		string = config.icons.disk,
		y_offset = -5,
	},
	label = {
		string = "??%",
		font = {
			size = 8.0,
		},
		width = 0,
		align = "right",
		padding_left = 0,
		padding_right = 0,
		y_offset = 2,
	},
	background = {
		height = config.settings.bar_height - 10,
	},
	y_offset = 5,
	update_freq = 30,
})

disk:subscribe({ "routine", "forced" }, function()
	Sbar.exec("df -h /System/Volumes/Data | tail -1 | awk '{print $5}'", function(result)
		local disk_used = tonumber(result:match("(%d+)%%"))

		disk:push({
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

		disk:set({
			graph = { color = color },
			label = { string = string.format("%.0f%%", disk_used) },
		})
	end)
end)

disk:subscribe("mouse.clicked", function()
	Sbar.exec("open -a 'Disk Utility'")
end)

return disk
