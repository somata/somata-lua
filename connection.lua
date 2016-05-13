local zmq = require 'lzmq'
local cjson = require 'cjson'

local helpers = require 'somata.helpers'

local Connection = {}
Connection.__index = Connection

function Connection.create(ctx, loop, connect)
    local connection = {}
    setmetatable(connection, Connection)
    connection.outstanding = {}

    connection.socket = ctx:socket({zmq.DEALER, connect=connect, identity=randomString(10)})
    loop:add_socket(connection.socket, function() connection:gotResponse() end)

    return connection
end

function Connection:sendMethod(method, args, cb) 
    local message = {kind="method", method=method, args=args}
    self:sendMessage(message, cb)
end

function Connection:sendMessage(message, cb)
    local id = randomString(10)
    self.outstanding[id] = cb
    message.id = id
    local message_json = cjson.encode(message)
    self.socket:send(message_json)
end

function Connection:gotResponse()
    local message_json = self.socket:recv()
    if not message_json then return nil end

    local message = cjson.decode(message_json)
    local outstanding_cb = self.outstanding[message.id]
    if outstanding_cb ~= nil then
        outstanding_cb(nil, message.response)
    end
end

return Connection
