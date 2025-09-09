local colors = require("config.colors")
local icons = require("config.icons")
local settings = require("config.settings")

local spaces = {}

for space_num = 1, 9 do
	local space_item = Sbar.add("item", "space_item." .. space_num, {
		position = "left",
		padding_left = settings.paddings,
		padding_right = settings.paddings,
		icon = {
			string = tostring(space_num),
			padding_left = 10,
			padding_right = 3,
			color = colors.foreground,
			highlight_color = colors.secondary.background,
			font = { family = settings.font, size = 14 },
		},
		label = {
			padding_left = 3,
			padding_right = 20,
			color = colors.foreground,
			highlight_color = colors.secondary.background,
			font = {
				family = settings.nerd_font,
				size = 14,
			},
			y_offset = 1,
		},
		background = {
			drawing = true,
			color = colors.with_alpha(colors.card.background, 0.8),
			border_color = colors.border,
			border_width = 1,
			corner_radius = 25,
		},
		blur_radius = 10,
	})

	spaces[space_num] = space_item

	local function get_focused_workspace()
		Sbar.exec("aerospace list-workspaces --focused", function(result)
			local focused_num = tonumber(result)
			local is_focused = focused_num == space_num
			local color = is_focused and colors.secondary.background or colors.border
			space_item:set({
				icon = { highlight = is_focused },
				label = { highlight = is_focused },
				background = { border_color = color },
			})
		end)
	end
	space_item:subscribe("forced", get_focused_workspace)

	-- Subscribe to aerospace workspace change for focus updates
	space_item:subscribe("aerospace_workspace_change", function(env)
		local focused_num = tonumber(env.FOCUSED)
		local is_focused = focused_num == space_num
		local color = is_focused and colors.secondary.background or colors.border
		space_item:set({
			icon = { highlight = is_focused },
			label = { highlight = is_focused },
			background = { border_color = color },
		})
	end)

	space_item:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			Sbar.exec("aerospace workspace " .. space_num)
		elseif env.BUTTON == "right" then
			-- TODO: destroy / create?
			-- For right-click, just focus the workspace
			Sbar.exec("aerospace workspace " .. space_num)
		end
	end)
end

local window_tracker = Sbar.add("item", "window_tracker", {
	padding_left = 5,
	padding_right = 5,
	icon = {
		string = "󰅂",
		color = colors.muted.background,
		font = {
			size = 24,
		},
	},
	label = { drawing = false },
	associated_display = "active",
	update_freq = 2,
})

local function update_window_tracker()
	for workspace_num = 1, 9 do
		Sbar.exec("aerospace list-windows --workspace " .. workspace_num .. ' --format "%{app-name}"', function(result)
			local icon_line = ""
			local no_app = true

			if result and result ~= "" then
				local apps = {}
				for app in result:gmatch("[^\n]+") do
					if app and app ~= "" and app ~= "None" then
						apps[app] = true -- Use as set to avoid duplicates
					end
				end

				-- Convert to icon line
				for app, _ in pairs(apps) do
					no_app = false
					icon_line = icon_line .. " " .. icons.map(app)
				end
			end

			if no_app then
				icon_line = ""
			end

			-- Update the workspace label with app icons
			if spaces[workspace_num] then
				spaces[workspace_num]:set({ label = { string = icon_line } })
			end
		end)
	end
end

window_tracker:subscribe("aerospace_workspace_change", update_window_tracker)
window_tracker:subscribe("routine", update_window_tracker)
window_tracker:subscribe("forced", update_window_tracker)
