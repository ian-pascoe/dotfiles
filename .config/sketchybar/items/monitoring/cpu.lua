-- Execute the event provider binary which provides the event "cpu_update" for
-- the cpu load data, which is fired every 2.0 seconds.
Sbar.exec(
	"killall cpu_load >/dev/null; $HOME/.config/sketchybar/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 2.0"
)

local config = require("config")

---@class items.monitoring.cpu
local M = {}

M.graph = Sbar.add("graph", "monitoring.cpu", 52, {
	drawing = false,
	position = "right",
	width = 0,
	padding_left = 8,
	padding_right = 4,
	graph = {
		color = config.colors.accent.background,
	},
	icon = {
		string = config.icons.cpu,
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

M.graph:subscribe("cpu_update", function(env)
	-- Also available: env.user_load, env.sys_load
	local load = tonumber(env.total_load)
	M.graph:push({ load / 100. })

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

	M.graph:set({
		graph = { color = color },
		label = { string = string.format("%.1f%%", load) },
	})
end)

M.graph:subscribe("mouse.clicked", function()
	Sbar.exec("open -a 'Activity Monitor'")
end)

return M
