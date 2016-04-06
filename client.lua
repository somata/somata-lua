zmq = require 'lzmq'
zloop = require 'lzmq.loop'
zthreads = require 'lzmq.threads'
uuid = require 'uuid'

Connection = require './connection'

-- Client
--------------------------------------------------------------------------------

Client = {}
Client.__index = Client

function Client.create()
    local client = {}
    setmetatable(client, Client)

    client.ctx = zmq.context()
    client.loop = zloop.new(1, ctx)
    client.service_connections = {}
    client.registry_connection = Connection.create(client.ctx, client.loop, "tcp://localhost:8420")

    return client
end

function Client:getConnection(service_name, cb)
    if self.service_connections[service_name] then
        cb(nil, self.service_connections[service_name])
    else
        self.registry_connection:sendMethod("getService", {service_name}, function(err, service)
            local service_connection = Connection.create(self.ctx, self.loop, "tcp://localhost:" .. service.port)
            self.service_connections[service_name] = service_connection
            cb(nil, service_connection)
        end)
    end
end

function Client:remote(service_name, method, args, cb)
    self:getConnection(service_name, function (err, service_connection)
        service_connection:sendMethod(method, args, cb)
    end)
end

return Client
