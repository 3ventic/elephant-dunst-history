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
Cache = false
Action = "dunstctl history-pop %VALUE%"
HideFromProviderlist = false
Description = "Show recent notifications from Dunst notification daemon."
SearchName = true
History = false
FixedOrder = true

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

local function find_desktop_file(appname)
	-- appname may already be like "firefox.desktop" or just "firefox" or "org.mozilla.firefox"
	if not appname or appname == "" then return nil end
	local name = appname:gsub("^%s+", ""):gsub("%s+$", "")
	-- if provided with a .desktop name, try that first
	local try_names = {}
	if name:match("%.desktop$") then
		table.insert(try_names, name)
	else
		table.insert(try_names, name .. ".desktop")
		table.insert(try_names, "*" .. name .. ".desktop") -- match trailing names like org.foo.NAME.desktop
	end

	local home = os.getenv("HOME") or ""
	local data_home = os.getenv("XDG_DATA_HOME") or (home .. "/.local/share")
	local data_dirs = os.getenv("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"
	local search_dirs = { data_home .. "/applications" }
	for dir in data_dirs:gmatch("([^:]+)") do
		table.insert(search_dirs, dir .. "/applications")
	end

	for _, d in ipairs(search_dirs) do
		for _, pattern in ipairs(try_names) do
			-- search only at depth 1 (desktop files usually live directly in applications/)
			local cmd = string.format("find '%s' -maxdepth 1 -type f -iname '%s' -print -quit 2>/dev/null", d, pattern)
			local h = io.popen(cmd)
			if h then
				local path = h:read("*l")
				h:close()
				if path and path ~= "" then
					return path
				end
			end
		end
	end
	return nil
end

local function desktop_icon_from_file(path)
	if not path then return nil end
	local f = io.open(path, "r")
	if not f then return nil end
	for line in f:lines() do
		local v = line:match("^%s*Icon%s*=%s*(.+)")
		if v then
			f:close()
			-- trim whitespace/newline
			v = v:gsub("^%s+", ""):gsub("%s+$", "")
			return v
		end
	end
	f:close()
	return nil
end

function GetEntries()
	local entries = {}

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
				-- appname field: try to resolve a matching .desktop filename and extract its Icon
				local appname_raw = line:gsub('"', ''):gsub('\\\"', '"')
				-- build subtext
				entry["Subtext"] = time .. " - " .. appname_raw
				-- find matching .desktop and icon
				local desktop_path = find_desktop_file(appname_raw)
				if desktop_path then
					local icon = desktop_icon_from_file(desktop_path)
					if icon and icon ~= "" then
						entry["Icon"] = icon
					end
				end
			elseif linecount % 4 == 3 then
				entry["Text"] = line:gsub('"', ''):gsub("\\\"", '"')
				if entry["Text"] == "" then
					entry["Text"] = "(no message)"
				end
			end
		end
		handle:close()
	end

	-- reverse entries to have most recent first
	local rev_entries = {}
	for i = #entries, 1, -1 do
		rev_entries[#rev_entries + 1] = entries[i]
	end

	return rev_entries
end
