package = "somata"
version = "0.0.1"

source = {
    url = "git://github.com/somata/somata-lua",
    tag = "v0.0.1"
}

description = {
    summary = "Somata for Lua",
    homepage = "https://github.com/somata/somata-lua"
}

dependencies = {
    "lua ~> 5.1",
    "lzmq >= 0.4.3-1"
    "luaposix >= 33.4.0-1"
}

build = {
    type = "builtin",
    modules = {
        ["somata"] = "init.lua"
    }
}
