package.path = "../rpc/?.lua;" .. package.path
local luarpc = require("luarpc")

package.path = "../raft/?.lua;" .. package.path
local luaraft = require("luaraft")

local IP = "127.0.0.1"
local port = "8000"
local idl = "../interface.lua"

local myobj = {
  ReceiveMessage = luaraft.ReceiveMessage,
  InitializeNode = luaraft.InitializeNode,
  StopNode = luaraft.StopNode,
  ApplyEntry = luaraft.ApplyEntry
}

luarpc.createServant(myobj, idl, port)
luarpc.waitIncoming()