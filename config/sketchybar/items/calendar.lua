local settings = require("settings")
local colors = require("colors")

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

local cal = sbar.add("item", {
	icon = {
		color = colors.accent,
		padding_left = 9,
		padding_right = 5,
		font = {
			style = settings.font.style_map["Black"],
			size = 12.0,
		},
	},
	label = {
		color = colors.white,
		padding_right = 9,
		width = 68,
		align = "right",
		font = { family = settings.font.numbers },
	},
	position = "right",
	update_freq = 1,
	padding_left = 1,
	padding_right = 1,
	background = {
		color = colors.bg2,
		height = settings.chip_height,
		corner_radius = settings.chip_corner_radius,
		border_color = colors.border,
		border_width = settings.chip_border_width,
	},
	click_script = "open -a 'Calendar'",
})

-- Double border for calendar using a single item bracket
sbar.add("bracket", { cal.name }, {
	background = {
		color = colors.transparent,
		height = settings.chip_height,
	},
})

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
	cal:set({ icon = os.date("%a. %d %b."), label = os.date("%H:%M:%S") })
end)
