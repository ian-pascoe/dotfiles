-- Start input volume change event provider
Sbar.exec(
	"killall input_volume_change >/dev/null; $HOME/.config/sketchybar/helpers/event_providers/input_volume_change/bin/input_volume_change"
)

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

---@param input_volume number
local function update_microphone_display(input_volume)
	local icon = icons.microphone._0

	if input_volume == 0 then
		icon = icons.microphone._0
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
			color = (input_volume == 0) and colors.muted.background or colors.foreground,
		},
		label = {
			drawing = input_volume > 0,
			string = tostring(input_volume) .. "%",
		},
	})
	microphone_slider:set({ slider = { percentage = input_volume } })
end

-- Subscribe to the event provider trigger
microphone_icon:subscribe("input_volume_change", function(env)
	local input_volume = tonumber(env.volume) or 0
	local is_muted = env.muted == "true"
	update_microphone_display(input_volume)
end)
microphone_icon:subscribe({ "forced" }, function(_)
	Sbar.exec("osascript -e 'get volume settings'", function(volume_info)
		local input_volume_match = volume_info:match("input volume:(%d+)")
		local input_volume = tonumber(input_volume_match or 0)
		update_microphone_display(math.floor(input_volume or 0))
	end)
end)

return microphone_icon
