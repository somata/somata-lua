local cjson = require 'cjson'
local somata = require './somata'

local service = somata.Service.create('luatest', {
    try=function(cb) cb(nil, "hmm") end,
    try2=function(name, cb) cb(nil, "the name is " .. name) end
})
