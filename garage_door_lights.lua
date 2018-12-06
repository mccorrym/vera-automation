-- Find the status of the garage door sensor
local service_id = "urn:micasaverde-com:serviceId:SecuritySensor1"
local switch_status = luup.variable_get(service_id, "Tripped", 8) or "Not available"

if (switch_status == "Not available") then
  -- Send message
  luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Garage Light Error", Description="I can't find the garage lights. You may want to check to make sure they're off.", Priority=1, URL=""}, 17)
  luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Garage Light Error", Description="I can't find the garage lights. You may want to check to make sure they're off.", Priority=1, URL=""}, 30)

elseif (tonumber(switch_status) == 1) then
	-- Turn the garage lights on if the light sensor detects that it's dark enough for them
	
	-- Get the value of the light sensor
	local light_sensor = "urn:micasaverde-com:serviceId:LightSensor1"
	local light_sensor_value = luup.variable_get(light_sensor, "CurrentLevel", 9) or "Not available"
	
	if (light_sensor_value == "Not available") then
	  -- Light sensor value can't be retrieved. Don't do anything.
	elseif (tonumber(light_sensor_value) < dancer.minimum_light_value) then
	  -- The sensor is low enough for the lights to be on. Turn the lights on.
	
	  -- Garage lights ON
	  luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget", { newTargetValue="1" }, 28)
	end
else
	-- Turn the lights off if they're on
	
	-- Find the status of the switch
	local power_switch = "urn:upnp-org:serviceId:SwitchPower1"
	local power_switch_status = luup.variable_get(power_switch, "Status", 28) or "Not available"
	
	if (power_switch_status == "Not available") then
	  -- Send message
	  luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Garage Light Error", Description="I can't find the garage lights. You may want to check to make sure they're off.", Priority=1, URL=""}, 17)
	  luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="Garage Light Error", Description="I can't find the garage lights. You may want to check to make sure they're off.", Priority=1, URL=""}, 30)

	elseif (tonumber(power_switch_status) == 1) then
		-- Lights are currently on. Turn them off.
		luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget", { newTargetValue="0" }, 28)
	end
end