![](https://i.imgur.com/Xt8Ujn8.png)

# Somata for Lua

Somata is a framework for building networked microservices, supporting both remote procedure call (RPC) and publish-subscribe models of communication. This is the Lua version of the library, see also [somata-node](https://github.com/somata/somata-node) and [somata-python](https://github.com/somata/somata-python).

*Note:* This implementation of the [Somata Protocol](https://github.com/somata/somata-protocol) is incomplete - it supports remote method calls but not event subscriptions.

## Installation

Install with the [LuaRocks](https://luarocks.org/) package manager:

```sh
$ luarocks install somata
```

## Getting started

![](https://i.imgur.com/mryWajd.png)

First make sure the Registry is [installed](https://github.com/somata/somata-registry#installation) and running:

```sh
$ somata-registry
[Registry] Bound to 127.0.0.1:8420
```

### Creating a Service

Create a Service using `somata.Service.create(name, methods)`. The `methods` argument is a table of named functions; every function is asynchronous and takes a callback as its last argument. 

This example (see [examples/hello-service.lua](https://github.com/somata/somata-lua/blob/master/examples/hello-service.lua)) creates a Service named "hello" with a single method `sayHello(name, cb)`:

```lua
local somata = require 'somata'

local service = somata.Service.create('hello', {
    sayHello = function(name, cb) cb(nil, "Hello, " .. name .. "!") end,
})
```

### Creating a Client

Create a Client using `somata.Client.create()`.

Call a remote method of a Service using `client.remote(service, method, args, cb)`. The callback function takes two argments, `err` and `response`.

This example (see [examples/hello-client.lua](https://github.com/somata/somata-lua/blob/master/examples/hello-client.lua)) connects to the "hello" service, and calls the `sayHello` method:

```lua
local somata = require 'somata'

local client = somata.Client.create()

client:remote("hello", "sayHello", {"world"}, function(err, response)
    print('Got response:', response)
end)

client.loop:start()
```
