function restartScene()
  luup.call_action("urn:micasaverde-com:serviceId:HomeAutomationGateway1", "RunScene", { SceneNum=1 }, 0)
end

-- Find the status of the switch
local service_id = "urn:micasaverde-com:serviceId:SecuritySensor1"
local switch_status = luup.variable_get(service_id, "Tripped", 8) or "Not available"

if (switch_status == "Not available") then
	-- Send message
	luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Garage Door Check", Description="I can't find the garage door. You may want to check that it's closed.", Priority=1, URL=""}, 17)
	luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Garage Door Check", Description="I can't find the garage door. You may want to check that it's closed.", Priority=1, URL=""}, 30)

elseif (tonumber(switch_status) == 1) then
	-- Send message
	luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Garage Door Check", Description="ALERT: The garage door is OPEN!", Priority=2, URL=""}, 17)
	luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Garage Door Check", Description="ALERT: The garage door is OPEN!", Priority=2, URL=""}, 30)
	-- Check again in 3 minutes
	luup.call_delay("restartScene", 180, nil, true)

else
	-- Find the status of the garage lights
	local power_switch = "urn:upnp-org:serviceId:SwitchPower1"
	local power_switch_status = luup.variable_get(power_switch, "Status", 28) or "Not available"
	
	if (power_switch_status == "Not available") then
		-- Send message
		luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Garage Door Check", Description="The garage door is closed, but I can't find the garage lights. You may want to check to make sure they're off.", Priority=1, URL=""}, 17)
		luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Garage Door Check", Description="The garage door is closed, but I can't find the garage lights. You may want to check to make sure they're off.", Priority=1, URL=""}, 30)
	elseif (tonumber(power_switch_status) == 1) then
		-- Lights are currently on. Send a message.
		luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Garage Door Check", Description="The garage door is closed, but the garage lights are on.", Priority=1, URL=""}, 17)
		luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Garage Door Check", Description="The garage door is closed, but the garage lights are on.", Priority=1, URL=""}, 30)
	else
		-- Send a message.
		luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Garage Door Check", Description="The garage door is closed.", Priority=0, URL=""}, 17)
		luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Garage Door Check", Description="The garage door is closed.", Priority=0, URL=""}, 30)
	end
end