---@class config.icons
local M = {
	apple = "",
	settings = "󰒓",
	signout = "󰍃",
	power = "󰐥",
	service = "󰢍",
	resize = "󰩨",
	clock = "",
	wifi = "󰖩",
	wifi_router = "󰑩",
	wifi_off = "󱚼",
	clipboard = "󰅇",

	volume = {
		_100 = "􀊩",
		_59 = "􀊥",
		_29 = "􀊡",
		_0 = "􀊣",
	},
	battery = {
		non_charging = {
			_100 = "󰁹",
			_90 = "󰂂",
			_80 = "󰂁",
			_70 = "󰂀",
			_60 = "󰁿",
			_50 = "󰁾",
			_40 = "󰁽",
			_30 = "󰁼",
			_20 = "󰁻",
			_10 = "󰁺",
			_0 = "󰂃",
		},
		charging = {
			_100 = "󰂅",
			_90 = "󰂋",
			_80 = "󰂊",
			_70 = "󰢞",
			_60 = "󰂉",
			_50 = "󰢝",
			_40 = "󰂈",
			_30 = "󰂇",
			_20 = "󰂆",
			_10 = "󰢜",
			_0 = "󰢟",
		},
	},
}

M.app_icons = {
	["Font Book"] = "",
	["Google Chrome"] = " ",
	["Ghostty"] = "󰊠 ",
	["Messages"] = "󰍡 ",
}

function M.map(app_name)
	if M.app_icons[app_name] then
		return M.app_icons[app_name]
	else
		return " "
	end
end

return M
