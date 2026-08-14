local colors = require("colors")

-- Equivalent to the --bar domain
sbar.bar({
	-- Keep the bar below normal application windows so it never covers their
	-- title bars on an external display. It remains visible on the desktop.
	topmost = "off",
	height = 34,
	y_offset = 0,
	color = colors.bar.bg,
	border_color = colors.bar.border,
	border_width = 0,
	corner_radius = 9,
	padding_right = 4,
	padding_left = 4,
	margin = 6,
	shadow = false,
	blur_radius = 18,
})
