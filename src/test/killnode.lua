package.path = "../rpc/?.lua;" .. package.path
local luarpc = require("luarpc")

package.path = "../json.lua/?.lua;" .. package.path

local IP = "127.0.0.1"
local idl = "../interface.lua"

local port = arg[1]

local p1 = luarpc.createProxy(IP, port, idl)
p1.StopNode()