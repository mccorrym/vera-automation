-- Function to log data for debugging
function logger(t) 
  local outf = io.open('/www/logs/landscape_monitor.log', 'a')
  outf:write(os.date('%Y-%m-%d %H:%M:%S: '))
  outf:write(t)
  outf:write('\r\n')
  outf:close()
end

-- To keep the lights off (during Halloween) set this to TRUE
local is_halloween = false
-- To control the front light switch during Christmas, set this to TRUE
local is_christmas = false

-- Find the status of the switch
local power_switch = "urn:upnp-org:serviceId:SwitchPower1"
local power_switch_status = luup.variable_get(power_switch, "Status", 10) or "Not available"

-- Get current time
local t = os.date('*t')
local current_hour = t.hour

if (tonumber(power_switch_status) == 1) then
  -- Lights are currently on

  if (tonumber(t.hour) < 12) then
    -- It's midnight. Turn the lights off

    -- Front lights OFF
    luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget", { newTargetValue="0" }, 10)
    -- Rear lights OFF
    luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget", { newTargetValue="0" }, 11)
    -- Garage lights OFF
	luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget", { newTargetValue="0" }, 28)
	
    if (is_christmas == true) then 
        -- During Christmas, also turn the front light switch OFF
		luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget", { newTargetValue="0" }, 6)
    end

    -- Log activity
    logger('Lights OFF')

  else
    -- Get the value of the light sensor
    local light_sensor = "urn:micasaverde-com:serviceId:LightSensor1"
    local light_sensor_value = luup.variable_get(light_sensor, "CurrentLevel", 9) or "Not available"

    if (light_sensor_value == "Not available") then
      -- Light sensor value can't be retrieved. Log an error.
      logger('ERROR: Light sensor value cannot be retrieved!')

    elseif (tonumber(light_sensor_value) >= dancer.maximum_light_value) then
      -- The sensor is too high for the lights to be on. Turn the lights off.

      -- Front lights OFF
      luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget", { newTargetValue="0" }, 10)
      -- Rear lights OFF
      luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget", { newTargetValue="0" }, 11)
	  -- Garage lights OFF
	  luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget", { newTargetValue="0" }, 28)
	  
      if (is_christmas == true) then 
          -- During Christmas, also turn the front light switch OFF
	  	  luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget", { newTargetValue="0" }, 6)
      end

      -- Log activity
      logger('Lights OFF due to sensor reading: ' .. light_sensor_value)

    end

  end
 
elseif (tonumber(power_switch_status) == 0) then
  -- Lights are currently off

  -- Get the value of the light sensor
  local light_sensor = "urn:micasaverde-com:serviceId:LightSensor1"
  local light_sensor_value = luup.variable_get(light_sensor, "CurrentLevel", 9) or "Not available"

  if (light_sensor_value == "Not available") then
    -- Light sensor value can't be retrieved. Log an error.
    logger('ERROR: Light sensor value cannot be retrieved!')

  elseif (tonumber(light_sensor_value) <= dancer.minimum_light_value) then

    if (tonumber(t.hour) > 12) then

      -- The sensor has reached the target value. Turn the lights on.
      
      if (is_halloween == false) then
      	-- Front lights ON
      	luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget", { newTargetValue="1" }, 10)
      	-- Rear lights ON
      	luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget", { newTargetValue="1" }, 11)

		-- Find the status of the garage door sensor
		local service_id = "urn:micasaverde-com:serviceId:SecuritySensor1"
		local switch_status = luup.variable_get(service_id, "Tripped", 8) or "Not available"
		
		if (tonumber(switch_status) == 1) then
			-- The garage door is open. Turn the garage lights ON
			luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget", { newTargetValue="1" }, 28)
		end
		
    	if (is_christmas == true) then 
            -- During Christmas, also turn the front light switch ON
	    	luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget", { newTargetValue="1" }, 6)
    	end

      	-- Log activity
      	logger('Lights ON due to sensor reading: ' .. light_sensor_value)

      else

      	-- Log activity
      	logger('Lights KEPT OFF due to override.')

      end

    end

  end

elseif (power_switch_status == "Not available") then
  -- Could not get switch status. Log an error.
  logger('ERROR: Power switch status cannot be retrieved!')

end