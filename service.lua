local zmq = require 'lzmq'
local zloop = require 'lzmq.loop'
local cjson = require 'cjson'
local signal = require 'posix.signal'
local helpers = require 'somata.helpers'
local Connection = require 'somata.connection'
local Binding = require 'somata.binding'

local Service = {}
Service.__index = Service

function Service.create(name, methods, options)
    local service = {}
    setmetatable(service, Service)

    service.id = name .. '~' .. helpers.randomString(5)
    service.name = name
    service.port = math.random(5000, 35000)
    service.methods = methods
    service.subscriptions = {}
    service.heartbeat = 5000

    if options ~= nil then
        if options.heartbeat ~= nil then
            service.heartbeat = options.heartbeat
        end
    end

    service.ctx = zmq.context()
    service.loop = zloop.new(1, service.ctx)
    service.registry_connection = Connection.create(service.ctx, service.loop, "tcp://localhost:8420", 'registry')
    service.binding = Binding.create(service.ctx, service.loop, service.port, function(client_id, message) service:handleMessage(client_id, message) end)

    if service.heartbeat > 0 then
        service:sendPing()
    end

    service.loop:start()

    return service
end

function Service:register()
    local registration = {
        id=self.id,
        name=self.name,
        port=self.port,
        heartbeat=self.heartbeat
    }
    self.registry_connection:sendMethod('registerService', {registration}, function()
        print(string.format("Registered %s on :%d", self.id, self.port))
    end)

    -- Deregister handler
    deregister = function() self:deregister() end
    signal.signal(signal.SIGINT, deregister)
    signal.signal(signal.SIGTERM, deregister)
end

function Service:deregister()
    print(string.format("Deregistering %s...", self.id))
    self.registry_connection:sendMethod('deregisterService', {self.name, self.id})
end

function Service:sendPing()
    local ping = 'ping'
    if self.ping_id == nil then
        self.ping_id = helpers.randomString(8)
        ping = 'hello'
    end
    self.registry_connection:sendMessage({kind='ping', ping=ping, id=self.ping_id}, function(err, pong)
        if pong == 'welcome' then
            self:register()
        end
        self.loop:add_once(self.heartbeat, function() self:sendPing() end)
    end)
end

function Service:handleMessage(client_id, message)
    if message.kind == 'method' then
        self:handleMethod(client_id, message.id, message.method, message.args)
    elseif message.kind == 'subscribe' then
        self:handleSubscribe(client_id, message.id, message.type)
    end
end

function Service:handleMethod(client_id, message_id, method, args)
    function cb(err, data)
        local response
        if err ~= nil then
            response = {
                id=message_id,
                kind='error',
                error=err
            }
        else
            response = {
                id=message_id,
                kind='response',
                response=data
            }
        end
        local response_json = cjson.encode(response)
        self.binding.socket:sendx(client_id, response_json)
    end
    print('[handleMethod]', client_id, method, args)
    table.insert(args, cb)
    self.methods[method](unpack(args))
end

function Service:handleSubscribe(client_id, message_id, event_type)
    if self.subscriptions[event_type] == nil then
        self.subscriptions[event_type] = {}
    end
    print('[handleSubscribe]', client_id, event_type)
    table.insert(self.subscriptions[event_type], {client_id, message_id})
end

function Service:publish(event_type, data)
    for i, subscription in pairs(self.subscriptions[event_type]) do
        local client_id = subscription[1]
        local message_id = subscription[2]
        local event = {
            id=message_id,
            kind='event',
            event=data
        }
        local event_json = cjson.encode(event)
        self.binding.socket:sendx(client_id, event_json)
    end
end

return Service
