local zmq = require 'lzmq'
local zloop = require 'lzmq.loop'
local zthreads = require 'lzmq.threads'
local cjson = require 'cjson'

local helpers = require './helpers'
local Connection = require './connection'
local Binding = require './binding'

local Service = {}
Service.__index = Service

local heartbeat_interval = 5000

function Service.create(name, methods)
    local service = {}
    setmetatable(service, Service)

    service.id = name .. '~' .. helpers.randomString(5)
    service.name = name
    service.port = math.random(5000, 35000)
    service.methods = methods

    service.ctx = zmq.context()
    service.loop = zloop.new(1, service.ctx)
    service.registry_connection = Connection.create(service.ctx, service.loop, "tcp://localhost:8420")
    service.binding = Binding.create(service.ctx, service.loop, service.port, function(client_id, message_id, method, args) service:handleMethod(client_id, message_id, method, args) end)

    service.loop:add_once(heartbeat_interval, function() service:sendPing() end)

    return service
end

function Service:register(cb)
    local registration = {
        id=self.id,
        name=self.name,
        port=self.port,
        heartbeat=heartbeat_interval
    }
    self.registry_connection:sendMethod('registerService', {registration}, cb)
    self.loop:start()
end

function Service:sendPing()
    self.registry_connection:sendMessage({kind='ping'}, function()
        self.loop:add_once(heartbeat_interval, function() self:sendPing() end)
    end)
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
