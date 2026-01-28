Sbar.exec(
  "killall media_stream >/dev/null; $HOME/.config/sketchybar/helpers/event_providers/media_stream/bin/media_stream media_stream_change"
)

local config = require("config")
local icons = config.icons
local colors = config.colors

---@class items.media
local M = {}

local max_chars = 32

M.button = Sbar.add("item", "media.button", {
  position = "right",
  associated_display = "active",
  icon = {
    drawing = false,
    string = icons.media.music,
    padding_left = 8,
    padding_right = 8,
  },
  label = {
    drawing = false,
    width = 0,
    max_chars = max_chars,
    padding_left = 0,
    padding_right = 8,
  },
  background = {
    drawing = false,
    color = colors.with_alpha(colors.accent.background, 0.5),
  },
  popup = {
    drawing = false,
    align = "center",
    horizontal = true,
  },
  click_script = "sketchybar --set $NAME popup.drawing=toggle",
})

M.popup = {
  back = Sbar.add("item", "media.popup.back", {
    position = "popup." .. M.button.name,
    icon = {
      string = icons.media.back,
    },
    label = {
      drawing = false,
    },
    click_script = "media-control previous-track",
  }),
  play_pause = Sbar.add("item", "media.popup.play_pause", {
    position = "popup." .. M.button.name,
    icon = {
      string = icons.media.play_pause,
      font = {
        size = 20,
      },
    },
    label = {
      drawing = false,
    },
    click_script = "media-control toggle-play-pause",
  }),
  next = Sbar.add("item", "media.popup.next", {
    position = "popup." .. M.button.name,
    icon = {
      string = icons.media.forward,
    },
    label = {
      drawing = false,
    },
    click_script = "media-control next-track",
  }),
}

M.button:subscribe("media_stream_change", function(env)
  local playing = env.playing == "true"
  local title = env.title
  local artist = env.artist

  local drawing = title ~= nil and title ~= "" and artist ~= nil and artist ~= ""
  local title_artist = ""
  if drawing then
    title_artist = title .. " - " .. artist
    if #title_artist > max_chars then
      title_artist = title_artist:sub(1, max_chars - 3) .. "..."
    end
  end

  M.button:set({
    icon = {
      drawing = drawing,
    },
    label = {
      drawing = drawing,
      string = title_artist,
    },
    background = {
      drawing = drawing,
    },
  })

  M.popup.play_pause:set({
    icon = {
      string = playing and icons.media.pause or icons.media.play,
    },
  })
end)

local interrupt = 0
local function animate_detail(detail)
  if not detail then
    interrupt = interrupt - 1
  end
  if interrupt > 0 and not detail then
    return
  end

  Sbar.animate("tanh", 20, function()
    M.button:set({
      label = { width = detail and "dynamic" or 0 },
    })
  end)
end

M.button:subscribe("mouse.entered", function(_)
  interrupt = interrupt + 1
  animate_detail(true)
end)

M.button:subscribe("mouse.exited", function(_)
  animate_detail(false)
end)

M.button:subscribe("mouse.exited.global", function(_)
  M.button:set({
    popup = { drawing = false },
  })
end)

return M
