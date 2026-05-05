return {
	-- Core palette: warm midnight glass with a restrained amber accent.
	black = 0xff11131a,
	white = 0xfff5f0e8,
	red = 0xffff6b7a,
	green = 0xff9adf8f,
	blue = 0xff8aadf4,
	cyan = 0xff7dcfff,
	yellow = 0xfff3c677,
	orange = 0xffffa066,
	magenta = 0xffcba6f7,
	grey = 0xff7c879d,
	muted = 0xffa4adbd,
	transparent = 0x00000000,
	accent = 0xfff3c677,
	accent_secondary = 0xff8aadf4,

	-- Bar / popups / backgrounds
	bar = {
		bg = 0x0011131a,
		border = 0x33f5f0e8,
	},
	popup = {
		bg = 0xe011131a,
		border = 0x66f5f0e8,
	},

	-- Shared surfaces for chips/brackets.
	bg1 = 0x66181b24,
	bg2 = 0x88222631,
	bg3 = 0xaa2a2f3a,
	border = 0x33f5f0e8,
	border_active = 0xfff3c677,
	shadow = 0x66000000,

	-- Alpha helper unchanged
	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,
}
