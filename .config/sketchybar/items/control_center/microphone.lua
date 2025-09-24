local colors = require("config.colors")
local icons = require("config.icons")

local microphone_icon = Sbar.add("item", "microphone_icon", {
	position = "right",
	padding_left = 4,
	padding_right = 8,
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
		align = "right",
	},
	background = {
		color = colors.transparent,
		corner_radius = 10,
	},
	update_freq = 10,
})
microphone_icon:subscribe("mouse.clicked", function()
	Sbar.exec("osascript -e 'get volume settings'", function(volume_info)
		local input_volume_match = volume_info:match("input volume:(%d+)")
		local input_volume = tonumber(input_volume_match or 0)

		if input_volume == 0 then
			-- Unmute by setting to 50%
			Sbar.exec("osascript -e 'set volume input volume 50'")
		else
			-- Mute by setting to 0
			Sbar.exec("osascript -e 'set volume input volume 0'")
		end

		Sbar.trigger("forced")
	end)
end)
microphone_icon:subscribe("mouse.entered", function()
	microphone_icon:set({
		popup = { drawing = true },
		background = { color = colors.with_alpha(colors.secondary.background, 0.25) },
	})
end)
microphone_icon:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
	microphone_icon:set({
		popup = { drawing = false },
		background = { color = colors.transparent },
	})
end)

local microphone_slider = Sbar.add("slider", "microphone_slider", 100, {
	width = 100,
	position = "popup." .. microphone_icon.name,
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
microphone_slider:subscribe("mouse.clicked", function(env)
	Sbar.exec("osascript -e 'set volume input volume " .. env["PERCENTAGE"] .. "'")
end)

microphone_icon:subscribe({ "routine", "forced" }, function(_)
	Sbar.exec("osascript -e 'get volume settings'", function(volume_info)
		local input_volume_match = volume_info:match("input volume:(%d+)")
		local is_muted = volume_info:match("input muted") ~= nil

		local input_volume = tonumber(input_volume_match or 0)
		local icon = icons.microphone._0
		local label_color = colors.foreground

		if is_muted or input_volume == 0 then
			icon = icons.microphone._0
			label_color = colors.secondary.foreground
		elseif input_volume > 60 then
			icon = icons.microphone._100
		elseif input_volume > 30 then
			icon = icons.microphone._66
		elseif input_volume > 10 then
			icon = icons.microphone._33
		else
			icon = icons.microphone._10
		end

		microphone_icon:set({
			icon = {
				string = icon,
				color = is_muted and colors.secondary.foreground or colors.foreground,
			},
			label = {
				drawing = input_volume > 0 and not is_muted,
				string = tostring(input_volume) .. "%",
				color = label_color,
			},
		})
		microphone_slider:set({ slider = { percentage = input_volume } })
	end)
end)

return microphone_icon
