local settings = require("settings")
local colors = require("colors")

-- Equivalent to the --default domain
sbar.default({
	updates = "when_shown",
	icon = {
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Semibold"],
			size = 12.0,
		},
		color = colors.white,
		padding_left = settings.paddings,
		padding_right = settings.paddings,
		background = { image = { corner_radius = 9 } },
	},
	label = {
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Semibold"],
			size = 12.0,
		},
		color = colors.white,
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	background = {
		height = settings.chip_height,
		corner_radius = settings.chip_corner_radius,
		border_width = settings.chip_border_width,
		border_color = colors.border,
		image = {
			corner_radius = settings.chip_corner_radius,
			border_color = colors.border,
			border_width = settings.chip_border_width,
		},
	},
	popup = {
		background = {
			border_width = settings.chip_border_width,
			corner_radius = settings.popup_corner_radius,
			border_color = colors.popup.border,
			color = colors.popup.bg,
			shadow = { drawing = true },
		},
		blur_radius = 60,
	},
	padding_left = 3,
	padding_right = 3,
	scroll_texts = true,
})
