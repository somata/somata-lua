local cjson = require 'cjson'
local somata = require './somata'

local client = somata.Client.create()

client:remote("logger:data", "findEvents", {{user_id="56f46c8d1c3fbba738edb449"}, 500}, function(err, events)
    print("Found " .. #events .. " events")
    print(events[5])
    table.sort(events, function(a, b) return a.timestamp < b.timestamp end)
    events_file = io.open("events.json", "w")
    events_json = cjson.encode(events)
    events_file:write(events_json)
    events_file:close()
    print("Done")
    os.exit()
end)

client.loop:start()

