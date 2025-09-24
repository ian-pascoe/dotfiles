local colors = require("config.colors")
local icons = require("config.icons")

local volume_icon = Sbar.add("item", "volume_icon", {
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
volume_icon:subscribe("mouse.clicked", function()
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
volume_icon:subscribe("mouse.entered", function()
	volume_icon:set({
		popup = { drawing = true },
		background = { color = colors.with_alpha(colors.secondary.background, 0.25) },
	})
end)
volume_icon:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
	volume_icon:set({
		popup = { drawing = false },
		background = { color = colors.transparent },
	})
end)

local volume_slider = Sbar.add("slider", "volume_slider", 100, {
	width = 100,
	position = "popup." .. volume_icon.name,
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
})
volume_slider:subscribe("mouse.clicked", function(env)
	Sbar.exec("osascript -e 'set volume output volume " .. env["PERCENTAGE"] .. "'")
end)

volume_icon:subscribe({ "volume_change", "forced" }, function(env)
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

	volume_icon:set({
		icon = {
			string = icon,
			color = (new_volume == 0) and colors.muted.background or colors.foreground,
		},
		label = {
			drawing = new_volume > 0,
			string = tostring(new_volume) .. "%",
		},
	})
	volume_slider:set({ slider = { percentage = new_volume } })
end)

return volume_icon
