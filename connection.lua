-- Connection
--------------------------------------------------------------------------------

Connection = {}
Connection.__index = Connection

function Connection.create(ctx, loop, connect)
    local connection = {}
    setmetatable(connection, Connection)
    connection.outstanding = {}
    connection.socket = ctx:socket({zmq.DEALER, connect=connect, identity=uuid.new()})

    loop:add_socket(connection.socket, function() connection:gotResponse() end)
    return connection
end

function Connection:sendMethod(method, args, cb) 
    local id = uuid.new()
    self.outstanding[id] = cb
    message = {id=id, kind="method", method=method, args=args}
    message_json = cjson.encode(message)
    self.socket:send(message_json)
end

function Connection:gotResponse()
    local message_json = self.socket:recv()
    if not message_json then return nil end

    message = cjson.decode(message_json)
    self.outstanding[message.id](nil, message.response)
end

return Connection
