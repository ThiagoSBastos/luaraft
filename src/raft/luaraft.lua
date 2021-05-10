--
-- LuaRaft
-- Author: Thiago Sousa Bastos
--

package.path = "../rpc/?.lua;" .. package.path
local luarpc = require("luarpc")

package.path = "../json.lua/?.lua;" .. package.path
local json = require("json")

local Queue = require("queue")
local states = require("states")
local timeouts = require("timeouts")
local messageTypes = require("message_types")

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

-------------------------------------------------------------------------------
-- Message functions
-------------------------------------------------------------------------------
local function processReceivedMessages(node)
  print("LuaRaft: Processing Received Messages")

  while Queue.isNotEmpty(node.receivedMessages) do
    local message = Queue.pop(node.receivedMessages)

    if message.type ~= nil then
      messageTypes[message.type]()
    end
  end
end

local function processSentMessages()

end

local function sendMessage(message, proxy)
  print("LuaRaft: Sending Message")
  -- Build message
  --local message = {
  --  term = messageParams.term,
  --  fromNode = messageParams.fromNode,
  --  toNode = messageParams.toNode,
  --  type = messageParams.type,
  --  value = messageParams.val
  --}

  local success = proxy.ReceiveMessage(message)
  if success then
    print("Success sending")
    return true
  else
    print("Message not accepted from " .. message.fromNode .. " to " .. message.toNode)
    return false
  end
end

-------------------------------------------------------------------------------
-- Leader Election
-------------------------------------------------------------------------------
local function initElection(node)
  if node.state == states.Leader then
    print("Leader")
  else
    print("initElection else")
  end
end

local function isMajorityQuorum(node)
  return node.votesReceived >= (((#node.peerPorts) + 1) + 1)/2
end

-------------------------------------------------------------------------------
-- RPC-API
-------------------------------------------------------------------------------
function luaraft.ReceiveMessage(messageStruct)
  print("LuaRaft: Receiving message")

  if messageStruct.type then
    Queue.push(node.receivedMessages, messageStruct)
    return false
  end
  return true
end

-- Builds a node and starts its lifecycle
function luaraft.InitializeNode(port, peers)
  peers = json.decode(peers)

  -- Build node
  node = {
    state = states.Follower,
    receivedMessages = Queue.new(),
    sentMessages = Queue.new(),
    isAlive = true,
    port = port, -- Maybe unused
    peerPorts = peers, -- Maybe unused
    peerProxies = {},
    votedFor = nil,
    currentTerm = 0
  }

  for index, peer_port in ipairs(peers) do
    table.insert(node.peerProxies, index, luarpc.createProxy(IP, peer_port, idl))
  end

  print("LuaRaft: Node " .. port .. " initialized")

  -- Lifecycle
  while node.isAlive do
    -- TODO: Como definir o tempo de wait ?
    luarpc.wait(2)
    processReceivedMessages(node)
    processSentMessages()

    if node.state == states.Leader then
      print("Send heartbeat to peers")
    end

    --initElection(node)
  end
end

-- Kills a node from the cluster
function luaraft.StopNode()
  node.isAlive = false
  -- lembrar de matar as mensagens que tem que processar
  print("LuaRaft: Node stoped")
end

return luaraft
