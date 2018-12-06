-- Function to log data for debugging
function logger(t) 
  local outf = io.open("/www/logs/sprinkler_monitor.log", "a")
  outf:write(os.date("%Y-%m-%d %H:%M:%S: "))
  outf:write(t)
  outf:write("\r\n")
  outf:close()
end

function restartScene()
	lul_resultcode = luup.call_action("urn:micasaverde-com:serviceId:HomeAutomationGateway1", "RunScene", { SceneNum=12 }, 0)
	if (lul_resultcode == -1) then
		logger("Error received when attempting to restart the sprinkler monitor scene.")
	end
end

local check_result
local check_code

function checkStatus()
	local http = require("socket.http")
	http.TIMEOUT = 5
	
	local lul_cmd = "http://192.168.7.5:8080/sn0"
	check_result, check_code = http.request(lul_cmd)
	
	if check_code == 401 then
		return -1
	elseif check_code == 200 then
		return check_result
	else
		return -1
	end
end

local status = checkStatus()
dancer.sprinklers.status_check_count = dancer.sprinklers.status_check_count + 1

if tostring(status) == "00000000" then
	if dancer.sprinklers.status_check_count == 1 then
		-- The sprinklers weren't started correctly due to the AP Client and the controller being in sleep mode. Wake it up and try again.
		logger("First status check returned invalid 00000000 response. Attempting to start the sprinklers again...")
		dancer.sprinklers.trigger_time = os.time()
		lul_resultcode = luup.call_action("urn:micasaverde-com:serviceId:HomeAutomationGateway1", "RunScene", { SceneNum=10 }, 0)
		if (lul_resultcode == -1) then
			logger("Error received when attempting to start the run sprinklers scene.")
			luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Sprinkler Error", Description="Error restarting the sprinklers!", Priority=1, URL=""}, 17)
		end
	else
		logger("Sprinklers finished!")
		luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Sprinkler Notification", Description="Sprinklers are finished running!", Priority=-2, URL=""}, 17)
	end
elseif tostring(status) == "-1" then
	dancer.sprinklers.error_count = dancer.sprinklers.error_count + 1
	if (dancer.sprinklers.error_count < 3) then 
		logger("Check code = " .. check_code .. " (Error " .. dancer.sprinklers.error_count .. " of 3)")
		luup.call_delay("restartScene", 5, nil, true)
	else
		logger("Error count threshold exceeded. Check code = " .. check_code .. ", result returned = " .. check_result)
		luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Sprinkler Error", Description="There was an error retrieving the sprinkler status. Check the log for details.", Priority=1, URL=""}, 17)
	end
else
	logger(status)
	luup.call_delay("restartScene", 55, nil, true)
end
