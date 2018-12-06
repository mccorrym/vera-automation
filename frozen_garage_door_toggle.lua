function turnSwitchOff()
	luup.call_action("urn:upnp-org:serviceId:SwitchPower1", "SetTarget", { newTargetValue="0" }, 21)
end

function turnSwitchOn()
	luup.call_action("urn:upnp-org:serviceId:SwitchPower1", "SetTarget", { newTargetValue="1" }, 21)
end

function checkDoorSensor()
	-- Find the status of the garage door sensor
	local service_id = "urn:micasaverde-com:serviceId:SecuritySensor1"
	local switch_status = luup.variable_get(service_id, "Tripped", 8) or "Not available"
	
	if (switch_status == "Not available") then
		-- Can't find the sensor. Bail out and turn the switch off.
		luup.call_delay("turnSwitchOff", 2, nil, true)
	elseif (tonumber(switch_status) == 1) then
		luup.call_delay("checkDoorSensor", 1, nil, true)
	else
		-- The door is closed. Turn the switch off.
		luup.call_delay("turnSwitchOff", 2, nil, true)
	end
end

luup.call_action("urn:upnp-org:serviceId:SwitchPower1", "SetTarget", { newTargetValue="1" }, 21)
luup.call_delay("turnSwitchOff", 1, nil, true)
luup.call_delay("turnSwitchOn", 2, nil, true)
luup.call_delay("checkDoorSensor", 3, nil, true)