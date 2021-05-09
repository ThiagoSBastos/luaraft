package.path = "../rpc/?.lua;" .. package.path
local luarpc = require("luarpc")

local IP = "127.0.0.1"
local port = "8002"
local idl = "../interface.lua"

local p3 = luarpc.createProxy(IP, port, idl)
p3.InitializeNode()
