local data = require("stoic.data")

local N = {}

-- Cache for today's date
local today_date_cache = nil
local today_date_cached = false

-- Get today's date with proper formatting (cached)
local function get_today_date()
	if today_date_cached and today_date_cache then
		return today_date_cache
	end

	local date_table = os.date("*t")
	local months = {
		"January",
		"February",
		"March",
		"April",
		"May",
		"June",
		"July",
		"August",
		"September",
		"October",
		"November",
		"December",
	}

	local month_name = months[date_table.month]
	local day = date_table.day

	-- Handle ordinal suffixes
	local suffix = "th"
	if day == 1 or day == 21 or day == 31 then
		suffix = "st"
	elseif day == 2 or day == 22 then
		suffix = "nd"
	elseif day == 3 or day == 23 then
		suffix = "rd"
	end

	today_date_cache = month_name .. " " .. day .. suffix
	today_date_cached = true
	return today_date_cache
end

-- Get today's entry
function N.get_today_entry()
	local today_date = get_today_date()
	local entry = data.get_data_by_date(today_date)

	-- If no entry for today, get the first entry
	if not entry then
		local all_data = data.get_all_data()
		entry = all_data[1]
	end

	return entry
end

-- Get entry for specific date with flexible parsing
function N.get_date_entry(date_str)
	-- Try to find exact match
	local entry = data.get_data_by_date(date_str)
	if entry then
		return entry
	end

	-- Try to parse flexible date formats
	local month, day = date_str:match("(%a+)%s+(%d+)")
	if month and day then
		local months = {
			"January",
			"February",
			"March",
			"April",
			"May",
			"June",
			"July",
			"August",
			"September",
			"October",
			"November",
			"December",
		}

		-- Normalize month name
		for _, month_name in ipairs(months) do
			if month_name:lower():sub(1, 3) == month:lower():sub(1, 3) then
				month = month_name
				break
			end
		end

		local day_num = tonumber(day)
		if day_num then
			-- Handle ordinal suffixes
			local suffix = "th"
			if day_num == 1 or day_num == 21 or day_num == 31 then
				suffix = "st"
			elseif day_num == 2 or day_num == 22 then
				suffix = "nd"
			elseif day_num == 3 or day_num == 23 then
				suffix = "rd"
			end

			local formatted_date = month .. " " .. day_num .. suffix
			entry = data.get_data_by_date(formatted_date)
			if entry then
				return entry
			end
		end
	end

	return nil
end

-- Get next entry
function N.get_next_entry(current_idx)
	return data.get_next_data(current_idx)
end

-- Get previous entry
function N.get_prev_entry(current_idx)
	return data.get_prev_data(current_idx)
end

-- Clear today's date cache (useful for testing)
function N.clear_today_cache()
	today_date_cache = nil
	today_date_cached = false
end

return N

