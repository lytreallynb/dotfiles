local colors = require("colors")
local settings = require("settings")

local stack_height = 30
local stack_width = 62

-- Start the cpu_load event provider
sbar.exec("killall cpu_load >/dev/null; $CONFIG_DIR/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 2.0")

local cpu_label = sbar.add("item", "widgets.cpuram.cpu", {
	position = "right",
	padding_left = 8,
	padding_right = 8,
	width = 0,
	icon = { drawing = false },
	label = {
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 9.5,
		},
		string = "CPU --%",
		color = colors.muted,
		width = stack_width,
		align = "center",
	},
	y_offset = 7,
})

local ram_label = sbar.add("item", "widgets.cpuram.ram", {
	position = "right",
	padding_left = 8,
	padding_right = 8,
	icon = { drawing = false },
	label = {
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 9.5,
		},
		string = "RAM --%",
		color = colors.muted,
		width = stack_width,
		align = "center",
	},
	y_offset = -7,
})

sbar.add("bracket", "widgets.cpuram.bracket", { cpu_label.name, ram_label.name }, {
	background = {
		color = colors.bg1,
		height = stack_height,
		corner_radius = settings.chip_corner_radius,
		border_width = settings.chip_border_width,
		border_color = colors.border,
	},
})

sbar.add("item", "widgets.cpuram.padding", {
	position = "right",
	width = settings.group_paddings,
})

local function color_for(load)
	if load > 80 then return colors.red end
	if load > 60 then return colors.orange end
	if load > 40 then return colors.yellow end
	return colors.muted
end

cpu_label:subscribe("cpu_update", function(env)
	local load = tonumber(env.total_load) or 0
	local color = color_for(load)
	cpu_label:set({ label = { string = "CPU " .. env.total_load .. "%", color = color } })
end)

cpu_label:subscribe("mouse.clicked", function() sbar.exec("open -a 'Activity Monitor'") end)
ram_label:subscribe("mouse.clicked", function() sbar.exec("open -a 'Activity Monitor'") end)

ram_label:subscribe({ "forced", "routine", "system_woke" }, function()
	sbar.exec([[
		PAGE=$(vm_stat | head -1 | awk '{print $8}')
		ACT=$(vm_stat | awk '/Pages active/ {gsub("\\.","",$NF); print $NF}')
		WIR=$(vm_stat | awk '/Pages wired down/ {gsub("\\.","",$NF); print $NF}')
		COM=$(vm_stat | awk '/Pages occupied by compressor/ {gsub("\\.","",$NF); print $NF}')
		TOT=$(sysctl -n hw.memsize)
		USED=$(( (ACT + WIR + COM) * PAGE ))
		echo $(( USED * 100 / TOT ))
	]], function(percent)
		percent = percent:gsub("%s+", "")
		local n = tonumber(percent) or 0
		local color = color_for(n)
		ram_label:set({ label = { string = "RAM " .. n .. "%", color = color } })
	end)
end)
