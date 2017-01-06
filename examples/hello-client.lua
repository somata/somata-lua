local somata = require 'somata'

local client = somata.Client.create()

client:remote("hello", "sayHello", {"world"}, function(err, response)
    print('Got response:', response)
end)

client.loop:start()

