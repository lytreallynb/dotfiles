local colors = require("colors")

-- Equivalent to the --bar domain
sbar.bar({
	topmost = "window",
	height = 36,
	y_offset = 0,
	color = colors.bar.bg,
	border_color = colors.bar.border,
	border_width = 0,
	corner_radius = 12,
	padding_right = 4,
	padding_left = 4,
	margin = 8,
	shadow = true,
	blur_radius = 24,
})
