package.path = "../rpc/?.lua;" .. package.path
local luarpc = require("luarpc")

package.path = "../raft/?.lua;" .. package.path
local luaraft = require("luaraft")

local port = "8000"
local idl = "../interface.lua"

local myobj = {
  ReceiveMessage = luaraft.ReceiveMessage,
  InitializeNode = luaraft.InitializeNode,
  StopNode = luaraft.StopNode,
}

luarpc.createServant(myobj, idl, port)
luarpc.waitIncoming()