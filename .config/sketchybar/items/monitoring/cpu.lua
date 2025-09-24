local config = require("config")

local cpu = Sbar.add("graph", "monitoring.cpu", 42, {
	position = "right",
	padding_left = 8,
	padding_right = 4,
	graph = {
		color = config.colors.accent.background,
	},
	icon = {
		string = config.icons.cpu,
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
		height = config.settings.bar_height - 20,
	},
	y_offset = 5,
	update_freq = 2,
})

cpu:subscribe({ "routine", "forced" }, function()
	Sbar.exec("iostat -c 2 | tail -1", function(result)
		local user, sys, _ = result:match("%s+(%d+)%s+(%d+)%s+(%d+)")
		local user_num, sys_num = tonumber(user), tonumber(sys)
		local load = user_num + sys_num

		cpu:push({
			load / 100,
		})

		local color = config.colors.success.background
		if load > 30 then
			if load < 60 then
				color = config.colors.info.background
			elseif load < 80 then
				color = config.colors.warning.background
			else
				color = config.colors.destructive.background
			end
		end

		cpu:set({
			graph = { color = color },
			label = { string = string.format("%.0f%%", load) },
		})
	end)
end)

cpu:subscribe("mouse.clicked", function()
	Sbar.exec("open -a 'Activity Monitor'")
end)

return cpu
