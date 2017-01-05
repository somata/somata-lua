local zmq = require 'lzmq'
local cjson = require 'cjson'

local helpers = require 'somata.helpers'

local Connection = {}
Connection.__index = Connection

function Connection.create(ctx, loop, connect, service)
    local connection = {}
    setmetatable(connection, Connection)
    connection.outstanding = {}
    connection.service = service

    connection.socket = ctx:socket({zmq.DEALER, connect=connect, identity=randomString(10)})
    loop:add_socket(connection.socket, function() connection:gotResponse() end)

    return connection
end

function Connection:sendMethod(method, args, cb) 
    local message = {kind="method", method=method, args=args, service=self.service}
    self:sendMessage(message, cb)
end

function Connection:sendMessage(message, cb)
    if message.id == nil then
        message.id = randomString(10)
    end
    self.outstanding[message.id] = cb
    local message_json = cjson.encode(message)
    self.socket:send(message_json)
end

function Connection:gotResponse()
    local message_json = self.socket:recv()
    if not message_json then return nil end

    local message = cjson.decode(message_json)
    local outstanding_cb = self.outstanding[message.id]

    if outstanding_cb ~= nil then
        if message.error ~= nil then
            outstanding_cb(message.error)
        else
            if message.response ~= nil then
                outstanding_cb(nil, message.response)
            elseif message.pong ~= nil then
                outstanding_cb(nil, message.pong)
            end
        end
    end
end

return Connection
