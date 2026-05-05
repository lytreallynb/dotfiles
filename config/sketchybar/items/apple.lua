local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- Padding item required because of bracket
sbar.add("item", { width = 5 })

local apple = sbar.add("item", {
	icon = {
		font = { size = 16.0 },
		string = icons.apple,
		color = colors.accent,
		padding_right = 8,
		padding_left = 8,
	},
	label = { drawing = false },
	background = {
		color = colors.bg2,
		height = settings.chip_height,
		corner_radius = settings.chip_corner_radius,
		border_color = colors.border,
		border_width = settings.chip_border_width,
	},
	padding_left = 1,
	padding_right = 1,
	click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0",
})

-- Double border for apple using a single item bracket
sbar.add("bracket", { apple.name }, {
	background = {
		color = colors.transparent,
		height = settings.chip_height,
	},
})

-- Padding item required because of bracket
sbar.add("item", { width = 7 })
