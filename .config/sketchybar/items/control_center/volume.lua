local colors = require("config.colors")
local icons = require("config.icons")

local M = {}

M.button = Sbar.add("item", "M.icon", {
	position = "right",
	padding_left = 4,
	padding_right = 4,
	icon = {
		padding_left = 4,
		padding_right = 4,
	},
	label = {
		drawing = false,
		padding_left = 0,
		padding_right = 4,
	},
	popup = {
		align = "center",
	},
	background = {
		color = colors.transparent,
		corner_radius = 10,
	},
})
M.button:subscribe("mouse.clicked", function()
	Sbar.exec("osascript -e 'get volume settings'", function(volume_info)
		local output_volume_match = volume_info:match("output volume:(%d+)")
		local output_volume = tonumber(output_volume_match or 0)

		if output_volume == 0 then
			-- Unmute by setting to 50%
			Sbar.exec("osascript -e 'set volume output volume 50'")
		else
			-- Mute by setting to 0
			Sbar.exec("osascript -e 'set volume output volume 0'")
		end

		Sbar.trigger("forced")
	end)
end)
M.button:subscribe("mouse.entered", function()
	M.button:set({
		popup = { drawing = true },
		background = { color = colors.with_alpha(colors.secondary.background, 0.25) },
	})
end)
M.button:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
	M.button:set({
		popup = { drawing = false },
		background = { color = colors.transparent },
	})
end)
M.button:subscribe("mouse.scrolled", function(env)
	local delta = env.INFO.delta
	if not (env.INFO.modifier == "ctrl") then
		delta = delta * 10.0
	end
	Sbar.exec('osascript -e "set volume output volume (output volume of (get volume settings) + ' .. delta .. ')"')
end)

M.slider = Sbar.add("slider", "volume_slider", 100, {
	width = 100,
	position = "popup." .. M.button.name,
	padding_left = 10,
	padding_right = 10,
	icon = { drawing = false },
	label = { drawing = false },
	slider = {
		highlight_color = colors.accent.background,
		width = 100,
		background = {
			height = 6,
			corner_radius = 3,
			color = colors.border,
		},
		knob = {
			string = "􀀁",
			drawing = true,
		},
	},
	updates = "when_shown",
})
M.slider:subscribe("mouse.clicked", function(env)
	Sbar.exec("osascript -e 'set volume output volume " .. env["PERCENTAGE"] .. "'")
end)

M.button:subscribe({ "volume_change", "forced" }, function(env)
	local new_volume = tonumber(env.INFO or 0)
	local icon = icons.volume._0

	if new_volume > 60 then
		icon = icons.volume._100
	elseif new_volume > 30 then
		icon = icons.volume._66
	elseif new_volume > 10 then
		icon = icons.volume._33
	elseif new_volume > 0 then
		icon = icons.volume._10
	end

	M.button:set({
		icon = {
			string = icon,
			color = (new_volume == 0) and colors.muted.background or colors.foreground,
		},
		label = {
			drawing = new_volume > 0,
			string = tostring(new_volume) .. "%",
		},
	})
	M.slider:set({ slider = { percentage = new_volume } })
end)

return M
