local zmq = require 'lzmq'
local uuid = require 'uuid'
local cjson = require 'cjson'

local Binding = {}
Binding.__index = Binding

function Binding.create(ctx, loop, port, onMessage)
    local binding = {}
    setmetatable(binding, Binding)

    binding.onMessage = onMessage
    binding.socket = ctx:socket({zmq.ROUTER, bind="tcp://*:" .. port})
    loop:add_socket(binding.socket, function() binding:gotMessage() end)

    return binding
end

function Binding:gotMessage()
    local client_id = self.socket:recv()
    local message_json = self.socket:recv()
    if not message_json then return nil end

    local message = cjson.decode(message_json)
    self.onMessage(client_id, message.id, message.method, message.args)
end

return Binding
