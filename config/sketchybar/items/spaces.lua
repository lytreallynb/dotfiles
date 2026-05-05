local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- Register aerospace custom event
sbar.add("event", "aerospace_workspace_change")

local spaces = {}

for i = 1, 9, 1 do
	local space = sbar.add("item", "space." .. i, {
		icon = {
			font = { family = settings.font.numbers },
			string = i,
			padding_left = 9,
			padding_right = 9,
			color = colors.muted,
		},
		label = { drawing = false },
		padding_right = 1,
		padding_left = 1,
		background = {
			color = colors.bg1,
			height = settings.chip_height,
			corner_radius = settings.chip_corner_radius,
			border_width = settings.chip_border_width,
			border_color = colors.border,
		},
	})

	spaces[i] = space

	space:subscribe("mouse.clicked", function()
		sbar.exec("aerospace workspace " .. i)
	end)
end

-- Single bracket wrapping all spaces
sbar.add("bracket", { "/space\\..*/" }, {
	background = {
		color = colors.transparent,
		height = settings.chip_height,
		border_color = { alpha = 0 },
	},
})

-- Padding after spaces
sbar.add("item", "space.padding", {
	width = settings.group_paddings,
})

-- Show only workspaces that are non-empty or focused
local function update_spaces()
	sbar.exec("aerospace list-workspaces --monitor all --empty no", function(nonempty)
		sbar.exec("aerospace list-workspaces --focused", function(focused)
			focused = focused:gsub("%s+", "")
			local visible = {}
			for line in nonempty:gmatch("[^\r\n]+") do
				local n = tonumber(line:match("%d+"))
				if n then visible[n] = true end
			end
			local fnum = tonumber(focused)
			if fnum then visible[fnum] = true end

			for i = 1, 9 do
				local selected = (tostring(i) == focused)
				spaces[i]:set({
					drawing = visible[i] == true,
					icon = { color = selected and colors.black or colors.muted },
					background = {
						color = selected and colors.accent or colors.bg1,
						border_color = selected and colors.border_active or colors.border,
					},
				})
			end
		end)
	end)
end

-- Listen for aerospace workspace changes and app focus changes
local space_observer = sbar.add("item", {
	drawing = false,
	updates = true,
})

space_observer:subscribe("aerospace_workspace_change", function()
	update_spaces()
end)

space_observer:subscribe("front_app_switched", function()
	update_spaces()
end)

-- Spaces toggle indicator
local spaces_indicator = sbar.add("item", {
	padding_left = -3,
	padding_right = 0,
	icon = {
		padding_left = 8,
		padding_right = 9,
		color = colors.accent,
		string = icons.switch.on,
	},
	label = {
		width = 0,
		padding_left = 0,
		padding_right = 8,
		string = "Spaces",
		color = colors.muted,
	},
	background = {
		color = colors.with_alpha(colors.bg1, 0.0),
		height = settings.chip_height,
		corner_radius = settings.chip_corner_radius,
		border_width = settings.chip_border_width,
		border_color = { alpha = 0 },
	},
})

spaces_indicator:subscribe("swap_menus_and_spaces", function()
	local currently_on = spaces_indicator:query().icon.value == icons.switch.on
	spaces_indicator:set({
		icon = currently_on and icons.switch.off or icons.switch.on,
	})
end)

spaces_indicator:subscribe("mouse.entered", function()
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = colors.bg2,
				border_color = colors.border,
			},
			label = { width = "dynamic" },
		})
	end)
end)

spaces_indicator:subscribe("mouse.exited", function()
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = colors.with_alpha(colors.bg1, 0.0),
				border_color = { alpha = 0 },
			},
			label = { width = 0 },
		})
	end)
end)

spaces_indicator:subscribe("mouse.clicked", function()
	sbar.trigger("swap_menus_and_spaces")
end)

update_spaces()
