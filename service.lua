local zmq = require 'lzmq'
local zloop = require 'lzmq.loop'
local zthreads = require 'lzmq.threads'
local uuid = require 'uuid'
local cjson = require 'cjson'

local Connection = require './connection'
local Binding = require './binding'

local Service = {}
Service.__index = Service

function Service.create(name, methods)
    local service = {}
    setmetatable(service, Service)

    service.id = name .. '~1'
    service.name = name
    service.port = 8888
    service.methods = methods

    service.ctx = zmq.context()
    service.loop = zloop.new(1, service.ctx)
    service.registry_connection = Connection.create(service.ctx, service.loop, "tcp://localhost:8420")
    service.binding = Binding.create(service.ctx, service.loop, service.port, function(client_id, message_id, method, args) service:handleMethod(client_id, message_id, method, args) end)

    return service
end

function Service:register()
    local registration = {
        id=self.id,
        name=self.name,
        port=self.port,
        heartbeat=15000
    }
    self.registry_connection:sendMethod('registerService', {registration}, function() end)
    self.loop:start()
end

function Service:handleMethod(client_id, message_id, method, args)
    function cb(err, data)
        local response = {
            id=message_id,
            kind='response',
            response=data
        }
        local response_json = cjson.encode(response)
        self.binding.socket:sendx(client_id, response_json)
    end
    table.insert(args, cb)
    self.methods[method](unpack(args))
end

return Service
