local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute the event provider binary which provides the event "cpu_update" for
-- the cpu load data, which is fired every 2.0 seconds.
sbar.exec("killall cpu_load >/dev/null; $CONFIG_DIR/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 2.0")

local cpu = sbar.add("item", "widgets.cpu", {
	position = "right",
	icon = {
		string = icons.cpu,
		color = colors.white,
	},
	label = {
		string = "??%",
		font = { family = settings.font.numbers, style = settings.font.style_map["Semibold"], size = 11.0 },
	},
})

cpu:subscribe("cpu_update", function(env)
	local load = tonumber(env.total_load)

	local color = colors.white
	if load and load > 30 then
		if load < 60 then
			color = colors.yellow
		elseif load < 80 then
			color = colors.orange
		else
			color = colors.red
		end
	end

	cpu:set({
		icon = { color = color },
		label = { string = env.total_load .. "%", color = color },
	})
end)

cpu:subscribe("mouse.clicked", function(env)
	sbar.exec("open -a 'Activity Monitor'")
end)

sbar.add("bracket", "widgets.cpu.bracket", { cpu.name }, {
	background = {
		color = colors.bg1,
		height = 24,
	},
})

sbar.add("item", "widgets.cpu.padding", {
	position = "right",
	width = settings.group_paddings,
})
