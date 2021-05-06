package.path = "../rpc/?.lua;" .. package.path
local luarpc = require("luarpc")

local IP = "127.0.0.1"
local port = "8000"
local idl = "../interface.lua"

local p1 = luarpc.createProxy(IP, port, idl)
p1.InitializeNode()
