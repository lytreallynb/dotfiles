local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local iface = "en0"
local popup_width = 250

local wifi = sbar.add("item", "widgets.wifi", {
	position = "right",
	icon = {
		string = icons.wifi.connected,
		color = colors.white,
	},
	label = { drawing = false },
})

local wifi_bracket = sbar.add("bracket", "widgets.wifi.bracket", { wifi.name }, {
	background = {
		color = colors.bg1,
		height = 24,
	},
	popup = { align = "center", height = 24, drawing = false },
})

sbar.add("item", "widgets.wifi.padding", {
	position = "right",
	width = settings.group_paddings,
})

local ssid = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = { font = { style = settings.font.style_map["Bold"] }, string = icons.wifi.router },
	width = popup_width,
	align = "center",
	label = { font = { size = 15, style = settings.font.style_map["Bold"] }, max_chars = 18, string = "????????????" },
	background = { height = 2, color = colors.grey, y_offset = -15 },
})

local hostname = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = { align = "left", string = "Hostname:", width = popup_width / 2 },
	label = { max_chars = 20, string = "????????????", width = popup_width / 2, align = "right" },
})

local ip = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = { align = "left", string = "IP:", width = popup_width / 2 },
	label = { string = "???.???.???.???", width = popup_width / 2, align = "right" },
})

local mask = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = { align = "left", string = "Subnet mask:", width = popup_width / 2 },
	label = { string = "???.???.???.???", width = popup_width / 2, align = "right" },
})

local router = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = { align = "left", string = "Router:", width = popup_width / 2 },
	label = { string = "???.???.???.???", width = popup_width / 2, align = "right" },
})

local function trim(s)
	if not s then return "" end
	return s:match("^%s*(.-)%s*$") or s
end

wifi:subscribe({ "wifi_change", "system_woke" }, function()
	sbar.exec("ipconfig getifaddr " .. iface, function(result)
		local connected = trim(result) ~= ""
		wifi:set({
			icon = {
				string = connected and icons.wifi.connected or icons.wifi.disconnected,
				color = connected and colors.white or colors.red,
			},
		})
	end)
end)

local function hide_details()
	wifi_bracket:set({ popup = { drawing = false } })
end

local function toggle_details()
	local q = wifi_bracket:query()
	local cur = q and q.popup and q.popup.drawing
	local should_draw = not (cur == true or cur == "on")

	if should_draw then
		wifi_bracket:set({ popup = { drawing = true } })
		sbar.exec("networksetup -getcomputername", function(r) hostname:set({ label = { string = trim(r) } }) end)
		sbar.exec("ipconfig getifaddr " .. iface, function(r) ip:set({ label = { string = trim(r) } }) end)
		sbar.exec("ipconfig getsummary " .. iface .. " | awk -F ' SSID : '  '/ SSID : / {print $2}'",
			function(r) ssid:set({ label = { string = trim(r) } }) end)
		sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Subnet mask: ' '/^Subnet mask: / {print $2}'",
			function(r) mask:set({ label = { string = trim(r) } }) end)
		sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'",
			function(r) router:set({ label = { string = trim(r) } }) end)
	else
		hide_details()
	end
end

wifi:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.exited.global", hide_details)

local function copy_label_to_clipboard(env)
	local q = sbar.query(env.NAME)
	local label_str = q and q.label and (q.label.string or q.label.value) or ""
	label_str = trim(label_str)
	if label_str == "" then return end
	sbar.exec('echo "' .. label_str .. '" | pbcopy')
	sbar.set(env.NAME, { label = { string = icons.clipboard, align = "center" } })
	sbar.delay(1, function() sbar.set(env.NAME, { label = { string = label_str, align = "right" } }) end)
end

ssid:subscribe("mouse.clicked", copy_label_to_clipboard)
hostname:subscribe("mouse.clicked", copy_label_to_clipboard)
ip:subscribe("mouse.clicked", copy_label_to_clipboard)
mask:subscribe("mouse.clicked", copy_label_to_clipboard)
router:subscribe("mouse.clicked", copy_label_to_clipboard)
