package.path = "../rpc/?.lua;" .. package.path
local luarpc = require("luarpc")

package.path = "../json.lua/?.lua;" .. package.path
local json = require("json")

local Queue = require("queue")
local states = require("states")
local timeouts = require("timeouts")

local luaraft = {}

local IP = "127.0.0.1"
local idl = "../interface.lua"

local node = {}

-- TODO: REMOVE LATER
local function dumpTable(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dumpTable(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

----------------------------------------------------------
local function processReceivedMessages()
  --while #messageQueue > 0 do
  --  -- pop message from queue
  --  local message = 0

  --  if message ~= nil then
  --    message[message.type]()
  --  end

  --end
end

local function processSentMessages()

end

--[[
  message = {
    term = 1
    fromNode = 2
    toNode = 3
    type = "RequestVote"
    value = nil
  }
]]--

------------------------ RPC-API ------------------------
function luaraft.ReceiveMessage(messageStruct)
  print("Receiving message")

  if messageStruct.type ~= nil then
    Queue.push(node.receivedMessages, messageStruct)
    return "Message received"
  end

  return "Message not accepted"
end

-- Builds a node and starts its lifecycle
function luaraft.InitializeNode(port, peers)
  peers = json.decode(peers)

  -- Build node struct
  node.state = states.Follower
  node.receivedMessages = Queue.new()
  node.sentMessages = Queue.new()
  node.isAlive = true
  node.port = port -- Maybe unused
  node.peerPorts = peers -- Maybe unused
  node.peerProxies = {}

  for index, peer_port in ipairs(peers) do
    table.insert(node.peerProxies, index, luarpc.createProxy(IP, peer_port, idl))
  end

  while node.isAlive do
    processReceivedMessages()
    processSentMessages()
  end

  print("Node Initialized from LuaRaft")
end

-- Kills a node from the cluster
function luaraft.StopNode()
  node.isAlive = false
  -- lembrar de matar as mensagens que tem que processar
  print("Node stoped from LuaRaft")
end

return luaraft
