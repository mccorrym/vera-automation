function turnSwitchOff()
  luup.call_action("urn:upnp-org:serviceId:SwitchPower1", "SetTarget", { newTargetValue="0" }, 21)
end

luup.call_action("urn:upnp-org:serviceId:SwitchPower1", "SetTarget", { newTargetValue="1" }, 21)
luup.call_delay("turnSwitchOff", 3, nil, true)