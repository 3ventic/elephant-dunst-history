--[[
    Elephant Dunst History is a custom menu provider for Elephant to access notification history from Dunst.
    Copyright (C) 2025 3v

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

Name = "notification-history"
NamePretty = "Notification History"
Icon = "applications-other"
Cache = true
Action = "dunstctl history-pop %VALUE%"
HideFromProviderlist = false
Description = "Show recent notifications from Dunst notification daemon."
SearchName = true

local function get_uptime()
	local f = io.open("/proc/uptime", "r")
	if not f then return nil end
	local line = f:read("*l")
	f:close()
	if not line then return nil end
	local uptime = line:match("^(%S+)")
	return tonumber(uptime)
end

-- Convert Dunst timestamp (microseconds since boot) to Unix timestamp
local function dunst_ts_to_time(ts)
	local ts_num = tonumber(ts) or 0
	local dunst_ts = ts_num / 1000 / 1000
	local seconds_uptime = get_uptime() or 0
	local now = os.time()
	local unix_ts = math.floor(now) - math.floor(seconds_uptime) + math.floor(dunst_ts)
	return unix_ts
end

function GetEntries()
	local entries = {}
	local seen_ids = {}

	local handle = io.popen("dunstctl history | jq '.data[][]|.timestamp.data,.appname.data,.body.data,.id.data'")

	if handle then
		local entry = {}
		local linecount = 0
		local time = os.date("%H:%M:%S", os.time())
		for line in handle:lines() do
			linecount = linecount + 1
			if linecount % 4 == 0 then
				entry["Value"] = line
				time = ""
				entries[#entries + 1] = entry
				entry = {}
			elseif linecount % 4 == 1 then
				time = os.date("%H:%M:%S", dunst_ts_to_time(line))
			elseif linecount % 4 == 2 then
				entry["Subtext"] = time .. " - " .. line:gsub('"', ''):gsub("\\\"", '"')
			elseif linecount % 4 == 3 then
				entry["Text"] = line:gsub('"', ''):gsub("\\\"", '"')
			end
		end
		handle:close()
	end

	return entries
end
