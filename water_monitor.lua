luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="***** ALERT *****", Description="Water has been detected near the " .. dancer.water_trigger .. " at " .. os.date('%I:%M:%S %p'), Priority=2, URL=""}, 17)
luup.call_action("urn:upnp-org:serviceId:IOSPush1", "SendProwlNotification", {Event="***** ALERT *****", Description="Water has been detected near the " .. dancer.water_trigger .. " at " .. os.date('%I:%M:%S %p'), Priority=2, URL=""}, 30)