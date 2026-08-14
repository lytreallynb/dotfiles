local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local iface = "en0"
local popup_width = 250
local connected = false
local rate_label = "idle"
local down_rate = "---"
local up_rate = "---"
local down_value = 0
local up_value = 0

sbar.add("event", "network_update")

local wifi = sbar.add("item", "widgets.wifi", {
	position = "right",
	update_freq = 10,
	icon = {
		string = icons.wifi.connected,
		color = colors.accent_secondary,
	},
	label = {
		drawing = true,
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 9.5,
		},
		string = rate_label,
		width = 44,
		align = "center",
		color = colors.muted,
		padding_left = 2,
		padding_right = 6,
	},
})

local wifi_bracket = sbar.add("bracket", "widgets.wifi.bracket", { wifi.name }, {
	background = {
		color = colors.bg1,
		height = settings.chip_height,
		corner_radius = settings.chip_corner_radius,
		border_width = settings.chip_border_width,
		border_color = colors.border,
	},
	popup = { align = "center", height = 24, drawing = false },
})

sbar.add("item", "widgets.wifi.padding", {
	position = "right",
	width = settings.group_paddings,
})

local ssid = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = { color = colors.accent_secondary, font = { style = settings.font.style_map["Bold"] }, string = icons.wifi.router },
	width = popup_width,
	align = "center",
	label = { font = { size = 15, style = settings.font.style_map["Bold"] }, max_chars = 18, string = "????????????" },
	background = { height = 1, color = colors.border, y_offset = -15 },
})

local download = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = { align = "left", string = "Download:", width = popup_width / 2 },
	label = { string = "---", width = popup_width / 2, align = "right", color = colors.accent_secondary },
})

local upload = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = { align = "left", string = "Upload:", width = popup_width / 2 },
	label = { string = "---", width = popup_width / 2, align = "right", color = colors.muted },
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

local function compact_rate(value)
	local amount, unit = trim(value):match("0*(%d+)%s*(%a+)")
	if not amount then return "---", 0, "---" end
	local suffix = unit == "MBps" and "M" or unit == "KBps" and "K" or "B"
	local multiplier = unit == "MBps" and 1000000 or unit == "KBps" and 1000 or 1
	local numeric = tonumber(amount) or 0
	local detailed_suffix = unit == "MBps" and "MB/s" or unit == "KBps" and "KB/s" or "B/s"
	return tostring(numeric) .. suffix, numeric * multiplier, tostring(numeric) .. " " .. detailed_suffix
end

local function render_rate()
	if not connected then
		rate_label = "offline"
	elseif down_value == 0 and up_value == 0 then
		rate_label = "idle"
	elseif down_value >= up_value then
		rate_label = "↓" .. down_rate
	else
		rate_label = "↑" .. up_rate
	end

	wifi:set({
		label = {
			string = rate_label,
			color = connected and colors.muted or colors.red,
		},
	})
end

local function refresh_connection()
	sbar.exec("ipconfig getifaddr " .. iface, function(result)
		connected = trim(result) ~= ""
		wifi:set({
			icon = {
				string = connected and icons.wifi.connected or icons.wifi.disconnected,
				color = connected and colors.accent_secondary or colors.red,
			},
		})
		render_rate()
	end)
end

local function start_network_monitor()
	sbar.exec("pkill -x network_load >/dev/null 2>&1; $CONFIG_DIR/helpers/event_providers/network_load/bin/network_load "
		.. iface .. " network_update 2.0")
end

wifi:subscribe({ "forced", "routine", "wifi_change", "system_woke" }, refresh_connection)

wifi:subscribe("network_update", function(env)
	if not connected then return end
	local down_detail
	local up_detail
	down_rate, down_value, down_detail = compact_rate(env.download)
	up_rate, up_value, up_detail = compact_rate(env.upload)
	download:set({ label = { string = down_detail } })
	upload:set({ label = { string = up_detail } })
	render_rate()
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

-- Resolve the Wi-Fi hardware interface instead of assuming it is always en0.
sbar.exec("networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/ {getline; print $2; exit}'", function(result)
	local detected = trim(result)
	if detected ~= "" then iface = detected end
	refresh_connection()
	start_network_monitor()
end)
