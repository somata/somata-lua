local somata = require 'somata'

local service = somata.Service.create('hello', {
    sayHello = function(name, cb) cb(nil, "Hello, " .. name .. "!") end,
})

