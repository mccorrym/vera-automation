-- Function to log data for debugging
function logger(t) 
  local outf = io.open("/www/logs/sprinkler_monitor.log", "a")
  outf:write(os.date("%Y-%m-%d %H:%M:%S: "))
  outf:write(t)
  outf:write("\r\n")
  outf:close()
end

function restartScene()
	lul_resultcode = luup.call_action("urn:micasaverde-com:serviceId:HomeAutomationGateway1", "RunScene", { SceneNum=10 }, 0)
	if (lul_resultcode == -1) then
		logger("Error received when attempting to restart the sprinkler trigger scene.")
	end
end

dancer.sprinklers.error_count = 0

-- Check to make sure the sprinkler scene was called less than 30 seconds ago
if ((os.time()-dancer.sprinklers.trigger_time) < 30) then
	local http = require("socket.http")
	http.TIMEOUT = 5
	
	local lul_cmd = "http://192.168.7.5:8080/cr?pw=" .. dancer.sprinklers.password .. "&t=[420,420,1200,900,900,0,0,0]"
	local res, status_code = http.request(lul_cmd)
	
	if (status_code == 200) then
		logger("Sprinklers have been started.")
		luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Sprinkler Notification", Description="Sprinklers have been started!", Priority=-2, URL=""}, 17)
		
		-- Write current timestamp to the log
		local current_timestamp = os.time()
		local f = io.open("/www/logs/sprinkler_timestamp.log", "w")
		f:write(current_timestamp)
		f:close()
		logger("Wrote timestamp " .. current_timestamp .. " to sprinkler_timestamp.log")
		
		logger("Sleeping for 30 seconds before starting 55-second status checks")
		luup.sleep(30000)
		logger("Beginning 55-second status checks...")
		dancer.sprinklers.error_count = 0
		
		-- Start the sprinkler monitor scene
		lul_resultcode = luup.call_action("urn:micasaverde-com:serviceId:HomeAutomationGateway1", "RunScene", { SceneNum=12 }, 0)
		if (lul_resultcode == -1) then
			logger("Error received when attempting to start the sprinkler monitor scene.")
		end
	else
		dancer.sprinklers.error_count = dancer.sprinklers.error_count + 1
		if (dancer.sprinklers.error_count < 3) then 
			logger("Check code = " .. status_code .. " (Error " .. dancer.sprinklers.error_count .. " of 3)")
			luup.call_delay("restartScene", 5, nil, true)
		else
			logger("Error count threshold exceeded. Check code = " .. status_code .. ", result returned = " .. res)
			luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Sprinkler Error", Description="Unable to start sprinklers. Check the log for details.", Priority=1, URL=""}, 17)
		end
	end
else
	logger("There was an error starting the sprinklers. The rain monitor scene was called >30 seconds prior. (OS time: " .. os.time() .. ", trigger time: " .. dancer.sprinklers.trigger_time .. ")")
	luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Sprinkler Error", Description="Unable to start sprinklers. Check the log for details.", Priority=1, URL=""}, 17)
end