local colors = require("colors")
local settings = require("settings")

local front_app = sbar.add("item", "front_app", {
  display = "active",
  icon = { drawing = false },
  padding_left = 6,
  padding_right = 6,
  label = {
    font = {
      style = settings.font.style_map["Black"],
      size = 12.0,
    },
    color = colors.white,
    max_chars = 28,
    padding_left = 10,
    padding_right = 10,
  },
  background = {
    color = colors.bg1,
    height = settings.chip_height,
    corner_radius = settings.chip_corner_radius,
    border_width = settings.chip_border_width,
    border_color = colors.border,
  },
  updates = true,
})

front_app:subscribe("front_app_switched", function(env)
  front_app:set({ label = { string = env.INFO } })
end)

front_app:subscribe("mouse.clicked", function(env)
  sbar.trigger("swap_menus_and_spaces")
end)
