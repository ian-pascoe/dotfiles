-- Execute the event provider binary which provides the event "displays_change"
Sbar.exec(
  "killall display_connection >/dev/null; $HOME/.config/sketchybar/helpers/event_providers/display_connection/bin/display_connection displays_change"
)

local colors = require("config.colors")
local icons = require("config.icons")
local settings = require("config.settings")
local front_app = require("items.front_app")

---@class items.spaces
local M = {}

M.root = Sbar.add("item", "spaces.root", {
  drawing = false,
  updates = true,
  update_freq = 2,
})

---@type Sketchybar.Item[][]
M.spaces = {}

---@type Sketchybar.Item[]
M.groups = {}

M.mode = Sbar.add("item", "spaces.mode", {
  position = "left",
  padding_left = 0,
  padding_right = 0,
  icon = { drawing = false },
  label = {
    string = "main",
    color = colors.primary.foreground,
    padding_left = settings.paddings.md,
    padding_right = settings.paddings.md,
  },
  blur_radius = 10,
})
M.mode:subscribe("aerospace_mode_change", function(env)
  local mode = env.MODE or "main"
  M.mode:set({
    label = { string = mode },
  })
end)

local function update_windows()
  for _, spaces in pairs(M.spaces) do
    for wnum, space in pairs(spaces) do
      Sbar.exec("aerospace list-windows --workspace " .. wnum .. ' --format "%{app-name}"', function(result)
        local icon_line = ""

        if result and result ~= "" then
          local apps = {}
          for app in result:gmatch("[^\n]+") do
            if app and app ~= "" and app ~= "None" then
              apps[app] = true -- Use as set to avoid duplicates
            end
          end

          -- Convert to icon line
          local i = 1
          local max_icons = 4
          for app, _ in pairs(apps) do
            if i > max_icons then
              icon_line = icon_line .. " " .. icons.ellipsis
              break
            end

            if i > 1 and i ~= #apps then
              icon_line = icon_line .. " " .. icons.map(app)
            else
              icon_line = icon_line .. icons.map(app)
            end
            i = i + 1
          end
        end

        space:set({ label = { drawing = icon_line ~= "", string = icon_line } })
      end)
    end
  end
end

local function update_spaces()
  Sbar.exec("aerospace list-monitors --format '%{monitor-id}'", function(monitor_result)
    local mids = {}
    for mid in monitor_result:gmatch("[^\n]+") do
      mid = Util.trim(mid)
      if mid ~= "" then
        table.insert(mids, mid)
      end
    end

    for _, mid in ipairs(mids) do
      mid = Util.trim(mid)
      local mnum = tonumber(mid) or 0
      M.spaces[mnum] = {}
      Sbar.exec("aerospace list-workspaces --monitor " .. mnum, function(workspace_result)
        local wids = {}
        for wid in workspace_result:gmatch("[^\n]+") do
          wid = Util.trim(wid)
          if wid ~= "" then
            table.insert(wids, wid)
          end
        end

        for widx, wid in ipairs(wids) do
          wid = Util.trim(wid)
          local wnum = tonumber(wid) or 0
          local space = Sbar.add("item", "spaces.space." .. wnum, {
            position = "left",
            padding_left = 0,
            padding_right = (widx == #wids) and settings.paddings.xl or 0,
            icon = {
              string = wid,
              padding_left = 8,
              padding_right = 8,
              color = colors.foreground,
              highlight_color = colors.secondary.background,
              font = {
                family = settings.fonts.regular,
                size = 14,
              },
            },
            label = {
              drawing = false,
              padding_left = 0,
              padding_right = 8,
              color = colors.foreground,
              highlight_color = colors.secondary.background,
              font = {
                family = settings.fonts.nerd,
                size = 10,
              },
              y_offset = 1,
            },
            background = {
              height = settings.heights.widget - 3,
              color = colors.with_alpha(colors.card.background, 0.9),
              border_color = colors.border,
              border_width = 1,
              corner_radius = 0,
            },
            associated_display = mnum,
            blur_radius = 10,
            updates = true,
          })
          M.spaces[mnum][wnum] = space

          local function set_focused(result)
            local focused_num = tonumber(result)
            local is_focused = focused_num == wnum
            local color = is_focused and colors.secondary.background or colors.border
            Sbar.animate("tanh", 5, function()
              space:set({
                icon = { highlight = is_focused },
                label = { highlight = is_focused },
                background = { border_color = color },
              })
            end)
          end

          space:subscribe({ "aerospace_workspace_change", "forced" }, function(env)
            if env.FOCUSED ~= nil then
              set_focused(env.FOCUSED)
            else
              Sbar.exec("aerospace list-workspaces --focused", function(result)
                local focused = Util.trim(result)
                set_focused(focused)
              end)
            end
          end)

          space:subscribe("mouse.clicked", function(env)
            if env.BUTTON == "left" then
              Sbar.exec("aerospace workspace " .. wnum)
            elseif env.BUTTON == "right" then
              -- TODO: destroy / create?
              -- For right-click, just focus the workspace
              Sbar.exec("aerospace workspace " .. wnum)
            end
          end)
        end

        -- Create group after all workspaces for this monitor are processed.
        -- Workspace numbers can be global/sparse (not starting at 1 per monitor), so we cannot rely on ipairs.
        local ordered_workspace_nums = {}
        for wnum, _ in pairs(M.spaces[mnum]) do
          table.insert(ordered_workspace_nums, wnum)
        end
        table.sort(ordered_workspace_nums)
        local group_items = {}
        for _, wnum in ipairs(ordered_workspace_nums) do
          table.insert(group_items, M.spaces[mnum][wnum].name)
        end
        table.insert(group_items, 1, M.mode.name)
        M.groups[mnum] = Sbar.add("bracket", "spaces.group." .. mnum, group_items, {
          position = "left",
          background = {
            color = colors.with_alpha(colors.primary.background, 0.9),
            border_width = 1,
            border_color = colors.border,
          },
          associated_display = mnum,
        })
        -- Move the front_app to the end of the group
        Sbar.exec("sketchybar --move " .. front_app.widget.name .. " after " .. M.groups[mnum].name)

        update_windows() -- update windows for the newly created spaces
      end)
    end
  end)
end

M.root:subscribe({ "displays_change", "forced" }, function(env)
  -- ignore the initial displays_change event to avoid double execution on startup
  if env.action == "initial" then
    return
  end
  -- remove all existing spaces and groups
  for _, group in pairs(M.groups) do
    Sbar.remove(group.name)
  end
  for _, space_groups in pairs(M.spaces) do
    for _, space in pairs(space_groups) do
      Sbar.remove(space.name)
    end
  end
  update_spaces()
end)
M.root:subscribe({ "aerospace_workspace_change", "routine" }, update_windows)

return M
