local config = require("config")
local colors = config.colors

local percent = 0

local battery = Sbar.add("item", "battery", {
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
	click_script = "sketchybar --set $NAME popup.drawing=toggle",
	popup = {
		align = "center",
	},
	update_freq = 30,
})
battery:subscribe({
	"mouse.exited",
	"mouse.exited.global",
}, function(_)
	battery:set({
		popup = { drawing = false },
		background = { color = colors.transparent },
	})
end)
battery:subscribe("mouse.entered", function(_)
	battery:set({
		popup = { drawing = true },
		background = { color = colors.with_alpha(colors.secondary.background, 0.25) },
	})
end)

local battery_details = Sbar.add("item", "battery_details", {
	position = "popup." .. battery.name,
	padding_left = 4,
	padding_right = 4,
})

battery:subscribe({
	"routine",
	"forced",
	"power_source_change",
	"system_woke",
}, function(_)
	Sbar.exec("pmset -g batt", function(batt_info)
		local icon = "!"
		local color = colors.success.background
		local charging = string.find(batt_info, "AC Power")

		local found, _, charge = batt_info:find("(%d+)%%")
		if found then
			percent = math.floor(tonumber(charge) or 0)
		end

		for _, threshold in ipairs(Util.battery.thresholds) do
			if percent >= threshold.percent then
				icon = charging and threshold.charging_icon or threshold.non_charging_icon
				color = threshold.color
				break
			end
		end

		local show_label = percent < 50
		battery:set({
			icon = {
				string = icon,
				padding_right = show_label and 4 or 8,
				color = color,
			},
			label = {
				drawing = show_label,
				string = percent .. "%",
			},
		})
		battery_details:set({
			label = {
				string = (charging and "Charging" or "On Battery") .. " - " .. percent .. "%",
			},
		})
	end)
end)

return battery
