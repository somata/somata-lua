local zmq = require 'lzmq'
local zloop = require 'lzmq.loop'
local Connection = require 'somata.connection'

local Client = {}
Client.__index = Client

function Client.create(loop)
    local client = {}
    setmetatable(client, Client)

    client.ctx = zmq.context()
    if loop == nil then
        client.loop = zloop.new(1, client.ctx)
    else
        client.loop = loop
    end
    client.service_connections = {}
    client.registry_connection = Connection.create(client.ctx, client.loop, "tcp://localhost:8420")

    return client
end

function Client:getConnection(service_name, cb)
    if self.service_connections[service_name] then
        cb(nil, self.service_connections[service_name])
    else
        self.registry_connection:sendMethod("getService", {service_name}, function(err, service)
            if service ~= nil then
                local service_connection = Connection.create(self.ctx, self.loop, "tcp://localhost:" .. service.port)
                self.service_connections[service_name] = service_connection
                cb(nil, service_connection)
            else
                cb("No such service")
            end
        end)
    end
end

function Client:remote(service_name, method, args, cb)
    self:getConnection(service_name, function (err, service_connection)
        if service_connection ~= nil then
            service_connection:sendMethod(method, args, cb)
        else
            print("[remote] Can't get service connection:", err)
            cb("Can't get service connection")
        end
    end)
end

return Client
