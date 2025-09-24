local icons = require("config.icons")
local colors = require("config.colors")

local thresholds = {
	{
		percent = 100,
		charging_icon = icons.battery.charging._100,
		non_charging_icon = icons.battery.non_charging._100,
		color = colors.success.background,
	},
	{
		percent = 90,
		charging_icon = icons.battery.charging._90,
		non_charging_icon = icons.battery.non_charging._90,
		color = colors.success.background,
	},
	{
		percent = 80,
		charging_icon = icons.battery.charging._80,
		non_charging_icon = icons.battery.non_charging._80,
		color = colors.success.background,
	},
	{
		percent = 70,
		charging_icon = icons.battery.charging._70,
		non_charging_icon = icons.battery.non_charging._70,
		color = colors.success.background,
	},
	{
		percent = 60,
		charging_icon = icons.battery.charging._60,
		non_charging_icon = icons.battery.non_charging._60,
		color = colors.info.background,
	},
	{
		percent = 50,
		charging_icon = icons.battery.charging._50,
		non_charging_icon = icons.battery.non_charging._50,
		color = colors.info.background,
	},
	{
		percent = 40,
		charging_icon = icons.battery.charging._40,
		non_charging_icon = icons.battery.non_charging._40,
		color = colors.warning.background,
	},
	{
		percent = 30,
		charging_icon = icons.battery.charging._30,
		non_charging_icon = icons.battery.non_charging._30,
		color = colors.warning.background,
	},
	{
		percent = 20,
		charging_icon = icons.battery.charging._20,
		non_charging_icon = icons.battery.non_charging._20,
		color = colors.destructive.background,
	},
	{
		percent = 10,
		charging_icon = icons.battery.charging._10,
		non_charging_icon = icons.battery.non_charging._10,
		color = colors.destructive.background,
	},
	{
		percent = 0,
		charging_icon = icons.battery.charging._0,
		non_charging_icon = icons.battery.non_charging._0,
		color = colors.destructive.background,
	},
}

local percent = 0

local battery = Sbar.add("item", "battery", {
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

		for _, threshold in ipairs(thresholds) do
			if percent >= threshold.percent then
				icon = charging and threshold.charging_icon or threshold.non_charging_icon
				color = threshold.color
				break
			end
		end

		battery:set({
			icon = {
				string = icon,
				color = color,
			},
			label = {
				drawing = percent < 50,
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
