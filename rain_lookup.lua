-- Function to log data for debugging
function logger(t) 
  local outf = io.open("/www/logs/sprinkler_monitor.log", "a")
  outf:write(os.date("%Y-%m-%d %H:%M:%S: "))
  outf:write(t)
  outf:write("\r\n")
  outf:close()
end

-- Refer to: http://w3.impa.br/~diego/software/luasocket/http.html
local function httpRequest(precip_date)
    -- This forces a GET instead of a POST
    request_body = ""

    http = require("socket.http")
    http.TIMEOUT = 5

    local response_body = {}

    -- r is 1, c is return status and h are the returned headers in a table variable
    local r, c, h = http.request {
          url = "http://api.wunderground.com/api/" .. dancer.sprinklers.wu_api_key .. "/history_" .. os.date("%Y%m%d", precip_date) .. "/q/MI/White%20Lake.xml",
          method = "POST",
          headers = {
            ["Content-Type"]   = "application/x-www-form-urlencoded",
            ['Content-Length'] = string.len(request_body)
          },
          source = ltn12.source.string(request_body),
          sink   = ltn12.sink.table(response_body)
    }

    local page = ""
    if type(response_body) == "table" then
       page = table.concat(response_body)
       return true, page
    end

    return false, page
end

local WEATHER_PATTERN = string.gsub([[<dailysummary>.*<mintempi>(.*)</mintempi>.*<precipi>(.*)</precipi>]], "%s*", "")
local mintemp_day_three, precip_day_three, mintemp_day_two, precip_day_two, mintemp_day_one, precip_day_one, mintemp_today, precip_today

local function parseData()
	-- Retrieve the timestamp for the last time the sprinklers were run
	local f = io.open("/www/logs/sprinkler_timestamp.log", "rb")
	local last_timestamp = tonumber(f:read("*all"))
	f:close()
	
	-- Don't run the sprinklers unless it has been at least 48 hours since the last run
	if (os.time()-last_timestamp) > (60*60*23*2) then
		-- It has been at least 48 hours since the last run. Let's check for rain now
		logger("Sprinklers last run " .. (os.time()-last_timestamp) .. " seconds ago. Continuing...")
		
		logger("Weather data pulled:")
		-- Get data for three days ago
			local success, webRequest = httpRequest((os.time()-60*60*24*3))
			
			if (success) then
				-- Strip out line feeds and tabs
				local xml = webRequest:gsub(">%s*<", "><")
				
				mintemp_day_three, precip_day_three = xml:match(WEATHER_PATTERN)
				if (mintemp_day_three == nil or string.len(mintemp_day_three) ~= 2) then
					local error_filename = "weather_xml_" .. os.date("%Y%m%d", (os.time()-60*60*24*3)) .. "_" .. os.time() .. ".log"
					local f = io.open("/www/logs/" .. error_filename, "w")
					f:write(webRequest)
					f:close()
					error({code="Temperature data was NULL or an invalid string for " .. os.date("%m/%d/%Y", (os.time()-60*60*24*3)) .. ". XML written to file: " .. error_filename})
				elseif (precip_day_three == nil or string.len(precip_day_three) ~= 4) then
					local error_filename = "weather_xml_" .. os.date("%Y%m%d", (os.time()-60*60*24*3)) .. "_" .. os.time() .. ".log"
					local f = io.open("/www/logs/" .. error_filename, "w")
					f:write(webRequest)
					f:close()
					error({code="Precipitation data was NULL or an invalid string for " .. os.date("%m/%d/%Y", (os.time()-60*60*24*3)) .. ". XML written to file: " .. error_filename})
				else
					logger(os.date("%m/%d/%Y", (os.time()-60*60*24*3)) .. ': ' .. precip_day_three .. '", ' .. mintemp_day_three .. ' low')
				end
			else
				error({code="Could not retrieve weather data for " .. os.date("%m/%d/%Y", (os.time()-60*60*24*3))})
			end


		-- Get data for two days ago
			local success, webRequest = httpRequest((os.time()-60*60*24*2))
			
			if (success) then
				-- Strip out line feeds and tabs
				local xml = webRequest:gsub(">%s*<", "><")
				
				mintemp_day_two, precip_day_two = xml:match(WEATHER_PATTERN)
				if (mintemp_day_two == nil or string.len(mintemp_day_two) ~= 2) then
					local error_filename = "weather_xml_" .. os.date("%Y%m%d", (os.time()-60*60*24*2)) .. "_" .. os.time() .. ".log"
					local f = io.open("/www/logs/" .. error_filename, "w")
					f:write(webRequest)
					f:close()
					error({code="Temperature data was NULL or an invalid string for " .. os.date("%m/%d/%Y", (os.time()-60*60*24*2)) .. ". XML written to file: " .. error_filename})
				elseif (precip_day_two == nil or string.len(precip_day_two) ~= 4) then
					local error_filename = "weather_xml_" .. os.date("%Y%m%d", (os.time()-60*60*24*2)) .. "_" .. os.time() .. ".log"
					local f = io.open("/www/logs/" .. error_filename, "w")
					f:write(webRequest)
					f:close()
					error({code="Precipitation data was NULL or an invalid string for " .. os.date("%m/%d/%Y", (os.time()-60*60*24*2)) .. ". XML written to file: " .. error_filename})
				else
					logger(os.date("%m/%d/%Y", (os.time()-60*60*24*2)) .. ': ' .. precip_day_two .. '", ' .. mintemp_day_two .. ' low')
				end
			else
				error({code="Could not retrieve weather data for " .. os.date("%m/%d/%Y", (os.time()-60*60*24*2))})
			end
			
		-- Get data for yesterday
			local success, webRequest = httpRequest((os.time()-60*60*24))
			
			if (success) then
				-- Strip out line feeds and tabs
				local xml = webRequest:gsub(">%s*<", "><")
				
				mintemp_day_one, precip_day_one = xml:match(WEATHER_PATTERN)
				if (mintemp_day_one == nil or string.len(mintemp_day_one) ~= 2) then
					local error_filename = "weather_xml_" .. os.date("%Y%m%d", (os.time()-60*60*24)) .. "_" .. os.time() .. ".log"
					local f = io.open("/www/logs/" .. error_filename, "w")
					f:write(webRequest)
					f:close()
					error({code="Temperature data was NULL or an invalid string for " .. os.date("%m/%d/%Y", (os.time()-60*60*24)) .. ". XML written to file: " .. error_filename})
				elseif (precip_day_one == nil or string.len(precip_day_one) ~= 4) then
					local error_filename = "weather_xml_" .. os.date("%Y%m%d", (os.time()-60*60*24)) .. "_" .. os.time() .. ".log"
					local f = io.open("/www/logs/" .. error_filename, "w")
					f:write(webRequest)
					f:close()
					error({code="Precipitation data was NULL or an invalid string for " .. os.date("%m/%d/%Y", (os.time()-60*60*24)) .. ". XML written to file: " .. error_filename})
				else
					logger(os.date("%m/%d/%Y", (os.time()-60*60*24)) .. ': ' .. precip_day_one .. '", ' .. mintemp_day_one .. ' low')
				end
			else
				error({code="Could not retrieve weather data for " .. os.date("%m/%d/%Y", (os.time()-60*60*24))})
			end
			
		-- Get data for today
			local success, webRequest = httpRequest(os.time())
			
			if (success) then
				-- Strip out line feeds and tabs
				local xml = webRequest:gsub(">%s*<", "><")
				
				mintemp_today, precip_today = xml:match(WEATHER_PATTERN)
				if ((mintemp_today == nil or string.len(mintemp_today) ~= 2) or (precip_today == nil or string.len(precip_today) ~= 4)) then
					local error_filename = "weather_xml_" .. os.date("%Y%m%d", os.time()) .. "_" .. os.time() .. ".log"
					local f = io.open("/www/logs/" .. error_filename, "w")
					f:write(webRequest)
					f:close()
					logger("Precipitation/temperature data was NULL or an invalid string for " .. os.date("%m/%d/%Y", os.time()) .. ". XML written to file: " .. error_filename)

					mintemp_today = 100
					precip_today = 0
				else
					logger(os.date("%m/%d/%Y", os.time()) .. ': ' .. precip_today .. '", ' .. mintemp_today .. ' low')
				end
			else
				error({code="Could not retrieve weather data for " .. os.date("%m/%d/%Y", (os.time()))})
			end

		-- If it has rained more than 1.0" in the last 72 hours, do not run the sprinklers
		local three_day_limit = 1.00
		-- If it has rained more than 0.5" in the last 48 hours, do not run the sprinklers
		local two_day_limit = 0.50
		-- If it has rained more than 0.25" in the last 24 hours, do not run the sprinklers
		local one_day_limit = 0.25
		-- If the low temperature in the last 48 hours was below 50 degrees, do not run the sprinklers
		local min_temperature = 50
		
		if tonumber(precip_day_three) + tonumber(precip_day_two) + tonumber(precip_day_one) + tonumber(precip_today) >= three_day_limit then
			-- Too much rain over 72 hours. Leave sprinkers OFF
			luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Sprinkler Notification", Description='Sprinklers OFF: 72-hour rain total of ' .. tonumber(precip_day_three) + tonumber(precip_day_two) + tonumber(precip_day_one) + tonumber(precip_today) .. '" exceeds ' .. three_day_limit .. '" limit.', Priority=0, URL=""}, 17)
			logger('Sprinklers OFF: 72-hour rain total of ' .. tonumber(precip_day_three) + tonumber(precip_day_two) + tonumber(precip_day_one) + tonumber(precip_today) .. '" exceeds ' .. three_day_limit .. '" limit.')
		else
			if tonumber(precip_day_two) + tonumber(precip_day_one) + tonumber(precip_today) >= two_day_limit then
				-- Too much rain over 48 hours. Leave sprinkers OFF
				luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Sprinkler Notification", Description='Sprinklers OFF: 48-hour rain total of ' .. tonumber(precip_day_two) + tonumber(precip_day_one) + tonumber(precip_today) .. '" exceeds ' .. two_day_limit .. '" limit.', Priority=0, URL=""}, 17)
				logger('Sprinklers OFF: 48-hour rain total of ' .. tonumber(precip_day_two) + tonumber(precip_day_one) + tonumber(precip_today) .. '" exceeds ' .. two_day_limit .. '" limit.')
			else
				if tonumber(precip_day_one) + tonumber(precip_today) >= one_day_limit then
					-- Too much rain over 24 hours. Leave sprinklers OFF
					luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Sprinkler Notification", Description='Sprinklers OFF: 24-hour rain total of ' .. tonumber(precip_day_one) + tonumber(precip_today) .. '" exceeds ' .. one_day_limit .. '" limit.', Priority=0, URL=""}, 17)
					logger('Sprinklers OFF: 24-hour rain total of ' .. tonumber(precip_day_one) + tonumber(precip_today) .. '" exceeds ' .. one_day_limit .. '" limit.')
				else
					if tonumber(mintemp_day_two) < min_temperature or tonumber(mintemp_day_one) < min_temperature or tonumber(mintemp_today) < min_temperature then
						-- Too cold over 48 hours. Leave sprinklers OFF
						luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Sprinkler Notification", Description="Sprinklers OFF: Low temperatures of (" .. mintemp_day_two .. "°F, " .. mintemp_day_one .. "°F, " .. mintemp_today .. "°F) exceeds " .. min_temperature .. "°F limit.", Priority=0, URL=""}, 17)
						logger("Sprinklers OFF: Low temperatures of (" .. mintemp_day_two .. ", " .. mintemp_day_one .. ", " .. mintemp_today .. ") exceeds " .. min_temperature .. " limit.")
					else
						-- Make sure this scene isn't running out of its normal timeframe
						if tonumber(os.date("%H")) == 4 then
							-- Turn the sprinklers ON
							logger("Sprinklers ON: Calling sprinkler scene now")
							dancer.sprinklers.trigger_time = os.time()
							dancer.sprinklers.status_check_count = 0
							lul_resultcode = luup.call_action("urn:micasaverde-com:serviceId:HomeAutomationGateway1", "RunScene", { SceneNum=10 }, 0)
							if (lul_resultcode == -1) then
								error({code="Error received when attempting to start the run sprinklers scene."})
							end
						else
							luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Sprinkler Notification", Description="Sprinklers OFF: Scene was triggered at an illegal time (" .. os.date("%I:%M%p") .. ")", Priority=1, URL=""}, 17)
							logger("Sprinklers OFF: Scene was triggered at an illegal time (" .. os.date("%I:%M%p") .. ")")
						end
					end
				end
			end
		end
	else
		luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Sprinkler Notification", Description="Sprinklers OFF. Last run on " .. os.date("%m/%d/%Y", last_timestamp), Priority=0, URL=""}, 17)
		logger("Sprinklers OFF. Last run on " .. os.date("%m/%d/%Y", last_timestamp))
	end	
end

local function_status, function_error = pcall(parseData)
if (function_status) then
	-- No errors detected
else 
	luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Sprinkler Error", Description="There was an error with the rain monitor when running the parseData() function. See the log for details.", Priority=1, URL=""}, 17)
	logger("There was an error running the parseData() function in the rain monitor scene. Error returned: " .. function_error.code)
end

return true