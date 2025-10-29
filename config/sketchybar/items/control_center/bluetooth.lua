local config = require("config")
local icons = config.icons
local colors = config.colors

---@class items.control_center.bluetooth
local M = {}

local popup_width = 200

M.button = Sbar.add("item", "bluetooth.button", {
	drawing = false,
	position = "right",
	width = 0,
	padding_left = 0,
	padding_right = 0,
	icon = {
		drawing = true,
		string = icons.bluetooth.on,
		padding_left = 8,
		padding_right = 8,
	},
	label = {
		drawing = false,
		padding_left = 0,
		padding_right = 8,
	},
	background = {
		color = colors.transparent,
	},
	popup = {
		drawing = false,
	},
	update_freq = 60,
})

M.button:subscribe("mouse.entered", function()
	M.button:set({
		popup = { drawing = true },
		background = { color = colors.with_alpha(colors.secondary.background, 0.25) },
	})
end)

M.button:subscribe({
	"mouse.exited.global",
	"mouse.exited",
}, function()
	M.button:set({
		popup = { drawing = false },
		background = { color = colors.transparent },
	})
end)

-- Toggle bluetooth with mouse click
M.button:subscribe("mouse.clicked", function()
	Sbar.exec("blueutil -p", function(state)
		if tonumber(state) == 0 then
			Sbar.exec("blueutil -p 1")
			M.button:set({
				icon = {
					string = icons.bluetooth.on,
					color = colors.foreground,
				},
			})
		else
			Sbar.exec("blueutil -p 0")
			M.button:set({
				icon = {
					string = icons.bluetooth.off,
					color = colors.muted.background,
				},
			})
		end

		Util.sleep(1)
		Sbar.trigger("bluetooth_update")
	end)
end)

---@type table<string, any>
M.popup = {}

---@type table<string, Sketchybar.Item>
M.popup.paired = {}

---@type table<string, Sketchybar.Item>
M.popup.connected = {}

-- Sanitize a string so it can be safely used as a SketchyBar item name
local function sanitize_name(s)
	return (s or "")
		:gsub("%s+", "_") -- spaces -> underscore
		:gsub("[^%w_%-%./]", "_") -- any disallowed character -> underscore
end

-- Parse a device line to extract its MAC address (supports '-' or ':')
local function parse_address(line)
	local addr = line:match("address%s+([%x%-%:]+)")
	if not addr then
		addr = line:match("([%x][%x:%-][%x:%-][%x:%-][%x:%-][%x:%-][%x:%-]+)") -- very loose fallback
	end
	return addr
end

-- Fetch bluetooth status and devices
M.button:subscribe({
	"routine",
	"forced",
	"bluetooth_update",
	"system_woke",
}, function()
	Sbar.exec("blueutil -p", function(state)
		-- Clear existing devices in tooltip
		local existingEvents = M.button:query()
		if existingEvents.popup and next(existingEvents.popup.items) ~= nil then
			for _, item in pairs(existingEvents.popup.items) do
				Sbar.remove(item)
			end
		end

		if tonumber(state) == 0 then
			M.button:set({
				icon = {
					string = icons.bluetooth.off,
					color = colors.muted.background,
				},
			})
			return
		end

		M.button:set({
			icon = {
				string = icons.bluetooth.on,
				color = colors.foreground,
			},
		})

		-- Get paired and connected devices
		Sbar.exec("blueutil --paired", function(paired)
			M.popup.paired.header = Sbar.add("item", "bluetooth.popup.paired.header", {
				width = popup_width,
				icon = {
					drawing = false,
				},
				label = {
					string = "Paired Devices",
					font = {
						style = "Bold",
						size = 14,
					},
				},
				position = "popup." .. M.button.name,
			})

			-- Iterate over the list of paired devices
			for device in paired:gmatch("[^\n]+") do
				local label = device:match('"(.*)"')
				local safe_label = sanitize_name(label)
				local address = parse_address(device)
				local paired_device = Sbar.add("item", "bluetooth.popup.paired.device." .. safe_label, {
					width = popup_width,
					icon = {
						drawing = false,
					},
					label = {
						string = label .. (address and "" or " (no addr)"),
					},
					background = {
						color = colors.transparent,
					},
					position = "popup." .. M.button.name,
					click_script = address
							and ('if [ "$(blueutil --is-connected ' .. address .. ')" = 1 ]; then blueutil --disconnect ' .. address .. "; else blueutil --connect " .. address .. "; fi; sketchybar --trigger bluetooth_update")
						or nil,
				})
				M.popup.paired[safe_label] = paired_device
				paired_device:subscribe({ "mouse.entered" }, function()
					paired_device:set({
						background = { color = colors.with_alpha(colors.primary.background, 0.25) },
					})
				end)
				paired_device:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
					paired_device:set({
						background = { color = colors.transparent },
					})
				end)
			end

			-- Fetch connected devices
			Sbar.exec("blueutil --connected", function(connected)
				M.popup.connected.header = Sbar.add("item", "bluetooth.popup.connected.header", {
					width = popup_width,
					icon = {
						drawing = false,
					},
					label = {
						string = "Connected Devices",
						font = {
							style = "Bold",
							size = 14,
						},
					},
					position = "popup." .. M.button.name,
				})

				for device in connected:gmatch("[^\n]+") do
					local label = device:match('"(.*)"')
					local safe_label = sanitize_name(label)
					local address = parse_address(device)
					local connected_device = Sbar.add("item", "bluetooth.popup.connected.device." .. safe_label, {
						width = popup_width,
						icon = {
							drawing = false,
						},
						label = {
							string = label .. (address and "" or " (no addr)"),
						},
						background = {
							color = colors.transparent,
						},
						position = "popup." .. M.button.name,
						click_script = address
								and ('if [ "$(blueutil --is-connected ' .. address .. ')" = 1 ]; then blueutil --disconnect ' .. address .. "; else blueutil --connect " .. address .. "; fi; sketchybar --trigger bluetooth_update")
							or nil,
					})
					M.popup.connected[safe_label] = connected_device
					connected_device:subscribe({ "mouse.entered" }, function()
						connected_device:set({
							background = { color = colors.with_alpha(colors.primary.background, 0.25) },
						})
					end)
					connected_device:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
						connected_device:set({
							background = { color = colors.transparent },
						})
					end)
				end
			end)
		end)
	end)
end)

return M
