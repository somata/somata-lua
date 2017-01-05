local cjson = require 'cjson'
local somata = require './somata'

local client = somata.Client.create()

client:remote("luatest", "try2", "test", function(err, response)
    print('response', response)
    os.exit()
end)

client.loop:start()

