local colors = require("config.colors")
local icons = require("config.icons")
local settings = require("config.settings")

local spaces_mode = Sbar.add("item", "spaces_mode", {
	position = "left",
	padding_left = settings.paddings / 2,
	padding_right = settings.paddings / 2,
	icon = { drawing = false },
	label = {
		string = "main",
		padding_left = 10,
		padding_right = 10,
	},
	background = {
		drawing = true,
		color = colors.with_alpha(colors.secondary.background, 0.8),
		border_color = colors.border,
		border_width = 1,
		corner_radius = 25,
	},
	blur_radius = 10,
})
spaces_mode:subscribe("aerospace_mode_change", function(env)
	local mode = env.MODE or "main"
	spaces_mode:set({
		label = { string = mode },
	})
end)

Sbar.exec("aerospace list-monitors --format '%{monitor-id}'", function(monitor_result)
	local monitor_ids = monitor_result:gmatch("[^\n]+")
	for m_id in monitor_ids do
		m_id = Util.trim(m_id)
		local m_num = tonumber(m_id) or 0
		Sbar.exec("aerospace list-workspaces --monitor " .. m_num, function(workspace_result)
			local workspace_ids = workspace_result:gmatch("[^\n]+")
			for w_id in workspace_ids do
				w_id = Util.trim(w_id)
				local w_num = tonumber(w_id) or 0
				local space_item = Sbar.add("item", "space_item." .. w_num, {
					position = "left",
					padding_left = settings.paddings / 4,
					padding_right = settings.paddings / 4,
					icon = {
						string = w_id,
						padding_left = 8,
						padding_right = 8,
						color = colors.foreground,
						highlight_color = colors.primary.background,
						font = { family = settings.font, size = 14 },
					},
					label = {
						drawing = false,
						padding_left = 0,
						padding_right = 8,
						color = colors.foreground,
						highlight_color = colors.primary.background,
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
					associated_display = m_num,
					blur_radius = 10,
					update_freq = 2,
				})

				local function set_focused(result)
					local focused_num = tonumber(result)
					local is_focused = focused_num == w_num
					local color = is_focused and colors.primary.background or colors.border
					space_item:set({
						icon = { highlight = is_focused },
						label = { highlight = is_focused },
						background = { border_color = color },
					})
				end

				space_item:subscribe({ "aerospace_workspace_change", "routine", "forced" }, function(env)
					if env.FOCUSED ~= nil then
						set_focused(env.FOCUSED)
					else
						Sbar.exec("aerospace list-workspaces --focused", set_focused)
					end

					Sbar.exec(
						"aerospace list-windows --workspace " .. w_num .. ' --format "%{app-name}"',
						function(result)
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
									icon_line = icon_line .. icons.map(app)
								end
							end

							if no_app then
								icon_line = ""
							end

							space_item:set({ label = { drawing = not no_app, string = icon_line } })
						end
					)
				end)

				space_item:subscribe("mouse.clicked", function(env)
					if env.BUTTON == "left" then
						Sbar.exec("aerospace workspace " .. w_num)
					elseif env.BUTTON == "right" then
						-- TODO: destroy / create?
						-- For right-click, just focus the workspace
						Sbar.exec("aerospace workspace " .. w_num)
					end
				end)
			end
		end)
	end
end)
