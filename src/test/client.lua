package.path = "../rpc/?.lua;" .. package.path
local luarpc = require("luarpc")

package.path = "../json.lua/?.lua;" .. package.path
local json = require("json")

local IP = "127.0.0.1"
local idl = "../interface.lua"

local port = arg[1]
local myport = tonumber(arg[1])
local peers = {}

for i = 2, #arg, 1 do
  peers[i-1] = arg[i]
end
peers = json.encode(peers)

local p1 = luarpc.createProxy(IP, port, idl)
p1.InitializeNode(myport, peers)
