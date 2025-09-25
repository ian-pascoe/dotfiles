-- Start input volume change event provider
Sbar.exec(
	"killall input_volume >/dev/null; $HOME/.config/sketchybar/helpers/event_providers/input_volume/bin/input_volume input_volume_change"
)

local config = require("config")
local colors = config.colors
local icons = config.icons

---@class items.control_center.microphone
local M = {}

local last_volume = 0

---@param volume number
local set_last_volume = function(volume)
	if volume > 0 then
		last_volume = volume
	end
end

M.button = Sbar.add("item", "microphone.button", {
	position = "right",
	padding_left = 0,
	padding_right = 0,
	icon = {
		padding_left = 8,
		padding_right = 8,
	},
	label = {
		drawing = false,
		padding_left = 0,
		padding_right = 8,
	},
	popup = {
		align = "right",
	},
	background = {
		color = colors.transparent,
		corner_radius = 10,
	},
})

M.button:subscribe("mouse.clicked", function()
	Sbar.exec("osascript -e 'get volume settings'", function(volume_info)
		local input_volume_match = volume_info:match("input volume:(%d+)")
		local input_volume = tonumber(input_volume_match or 0)

		if input_volume == 0 then
			-- Unmute by setting to last_volume
			Sbar.exec("osascript -e 'set volume input volume " .. last_volume .. "'")
		else
			-- Mute by setting to 0
			Sbar.exec("osascript -e 'set volume input volume 0'")
		end
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
	Sbar.exec('osascript -e "set volume input volume (input volume of (get volume settings) + ' .. delta .. ')"')
end)

M.slider = Sbar.add("slider", "M.slider", 100, {
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
})

M.slider:subscribe("mouse.clicked", function(env)
	Sbar.exec("osascript -e 'set volume input volume " .. env["PERCENTAGE"] .. "'")
end)

---@param input_volume number
local function update_microphone_display(input_volume)
	set_last_volume(input_volume)

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

	local is_muted = input_volume == 0
	Sbar.animate("tanh", 10, function()
		M.button:set({
			icon = {
				string = icon,
				padding_right = is_muted and 8 or 4,
				color = is_muted and colors.muted.background or colors.foreground,
			},
			label = {
				drawing = not is_muted,
				string = tostring(input_volume) .. "%",
			},
		})
		M.slider:set({
			slider = { percentage = input_volume },
		})
	end)
end

-- Subscribe to the event provider trigger
M.button:subscribe("input_volume_change", function(env)
	local input_volume = tonumber(env.volume) or 0
	update_microphone_display(input_volume)
end)

M.button:subscribe({ "forced" }, function(_)
	Sbar.exec("osascript -e 'get volume settings'", function(volume_info)
		local input_volume_match = volume_info:match("input volume:(%d+)")
		local input_volume = tonumber(input_volume_match or 0)
		update_microphone_display(input_volume or 0)
	end)
end)

return M
