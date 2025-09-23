local colors = require("config.colors")
local icons = require("config.icons")

local volume_icon = Sbar.add("item", "volume_icon", {
	position = "right",
	padding_left = 0,
	padding_right = 0,
	icon = {
		align = "left",
		padding_left = 10,
		padding_right = 10,
		font = {
			style = "Regular",
			size = 14.0,
		},
	},
	label = {
		drawing = false,
	},
	click_script = "sketchybar --set $NAME popup.drawing=toggle",
	popup = {
		align = "right",
	},
	background = {
		color = colors.transparent,
		corner_radius = 10,
	},
	updates = true,
})
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
		icon = { string = icon },
		label = { drawing = new_volume > 0, string = tostring(new_volume) .. "%" },
	})
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
	updates = true,
})
volume_slider:subscribe("mouse.clicked", function(env)
	Sbar.exec("osascript -e 'set volume output volume " .. env["PERCENTAGE"] .. "'")
end)
volume_slider:subscribe({ "volume_change", "forced" }, function(env)
	local new_volume = tonumber(env.INFO or 0)
	volume_slider:set({ slider = { percentage = new_volume } })
end)

return volume_icon
