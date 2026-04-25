local colors = require("colors")
local settings = require("settings")

local ram = sbar.add("item", "widgets.ram", {
	position = "right",
	icon = {
		string = "RAM",
		color = colors.white,
	},
	label = {
		string = "??%",
		font = { family = settings.font.numbers },
	},
	update_freq = 5,
})

ram:subscribe({ "forced", "routine", "system_woke" }, function()
	sbar.exec([[
		top -l 1 -s 0 | awk '/PhysMem/ {
			used = $2; unused = $6
			if (used ~ /G/) { sub(/G/, "", used); used *= 1024 } else { sub(/M/, "", used) }
			if (unused ~ /G/) { sub(/G/, "", unused); unused *= 1024 } else { sub(/M/, "", unused) }
			total = used + unused
			if (total > 0) printf "%d", used / total * 100
			else printf "0"
		}'
	]], function(percent)
		percent = percent:gsub("%s+", "")
		local n = tonumber(percent) or 0
		local color = colors.white
		if n > 80 then
			color = colors.red
		elseif n > 60 then
			color = colors.orange
		elseif n > 40 then
			color = colors.yellow
		end
		ram:set({
			icon = { color = color },
			label = { string = n .. "%", color = color },
		})
	end)
end)

ram:subscribe("mouse.clicked", function()
	sbar.exec("open -a 'Activity Monitor'")
end)

sbar.add("bracket", "widgets.ram.bracket", { ram.name }, {
	background = {
		color = colors.bg1,
		height = 24,
	},
})

sbar.add("item", "widgets.ram.padding", {
	position = "right",
	width = settings.group_paddings,
})
