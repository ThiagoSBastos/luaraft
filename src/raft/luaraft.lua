--
-- LuaRaft
-- Author: Thiago Sousa Bastos
--

package.path = "../rpc/?.lua;" .. package.path
local luarpc = require("luarpc")

package.path = "../json.lua/?.lua;" .. package.path
local json = require("json")

local states = require("states")
local luaclock = require("luaclock")
local node_obj = require("node")

local luaraft = {}

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

-- Table containing callbacks to handle any message type
local messageTypes = {
  RequestVote = function(message)

    -- Case 1: message w/ stale term
    if message.term < node:getCurrentTerm() then
      -- reject vote
      print("LuaRaft: Node " .. node:getPort()
         .. " is rejecting vote from node " .. message.fromNode
         .. " " .. luaclock.GetFormattedHour())

      local rejectVote_message = {
        term = node:getCurrentTerm(),
        fromNode = node.port,
        toNode = message.fromNode,
        type = "RequestVoteReply",
        value = json.encode(false)
      }

      local node_to_reply = tostring(rejectVote_message.toNode)
      local node_proxy = node.peerProxies[node_to_reply]
      SendMessage(rejectVote_message, node_proxy)

      return
    end

    -- Case 2: RPC request contains term T > currentTerm:
    if message.term > node:getCurrentTerm() then
      -- set currentTerm = T, convert to follower

      node:resetElectionTimer()
      node:setCurrentTerm(message.term)
      node:setState(states.Follower)
      node:resetVoteCount()
      node:setVotedFor(message.fromNode)

      -- grant vote to candidate
      print("LuaRaft: Node " .. node:getPort()
         .. " is granting vote to node " .. message.fromNode
         .. " " .. luaclock.GetFormattedHour())

      local requestVoteReply_msg = {
        term = node:getCurrentTerm(),
        fromNode = node.port,
        toNode = message.fromNode,
        type = "RequestVoteReply",
        value = json.encode(true)
      }

      local node_to_reply = tostring(requestVoteReply_msg.toNode)
      local node_proxy = node.peerProxies[node_to_reply]
      SendMessage(requestVoteReply_msg, node_proxy)

      return
    end

    -- Case 3: If votedFor is null or candidateId grant vote
    if node.votedFor == nil or node.votedFor == message.fromNode then

      node:resetElectionTimer()
      node:setVotedFor(message.fromNode)

      print("LuaRaft: Node " .. node:getPort()
         .. " is granting vote to node " .. message.fromNode
         .. " " .. luaclock.GetFormattedHour())
      local requestVoteReply_msg = {
        term = node:getCurrentTerm(),
        fromNode = node.port,
        toNode = message.fromNode,
        type = "RequestVoteReply",
        value = json.encode(true)
      }

      local node_to_reply = tostring(requestVoteReply_msg.toNode)
      local node_proxy = node.peerProxies[node_to_reply]
      SendMessage(requestVoteReply_msg, node_proxy)
    end
  end,
  RequestVoteReply = function(message)

    -- Case 1: message w/ stale term
    if message.term < node:getCurrentTerm() then
      return -- ignore
    end

    -- Case 2: RPC response contains term T > currentTerm:
    if message.term > node:getCurrentTerm() then
      -- set currentTerm = T, convert to follower
      print("LuaRaft: RequestVoteReply is converting node " ..
      node:getPort() .. " to follower" .. " " ..
      luaclock.GetFormattedHour())

      node:setState(states.Follower)
      node:setCurrentTerm(message.term)
      node:resetVoteCount()
      node:resetVotedFor()

      return
    end

    -- Case 3: Everything ok
    local response_val = json.decode(message.value)
    if response_val == true then -- vote granted
      print("LuaRaft: Node " .. node:getPort()
         .. " received vote from node " .. message.fromNode
         .. " " .. luaclock.GetFormattedHour())

      node:incrementVoteCount()
      if HasQuorum() then
        BecomeLeader()
      end
    else -- vote rejected
      print("LuaRaft: RequestVoteReply is converting node " ..
             node:getPort() .. " to follower" .. " " ..
             luaclock.GetFormattedHour())

      node:setState(states.Follower)
      node:setCurrentTerm(message.term)
      node:resetVoteCount()
      node:resetVotedFor()
    end
  end,
  AppendEntries = function(message)

    -- Case 1: message w/ stale term
    if message.term < node:getCurrentTerm() then
      -- reject append entries
      print("LuaRaft: Node " .. node:getPort()
         .. " is rejecting append entries from node " .. message.fromNode
         .. " " .. luaclock.GetFormattedHour())

      local rejectAppend_message = {
        term = node:getCurrentTerm(),
        fromNode = node.port,
        toNode = message.fromNode,
        type = "AppendEntriesReply",
        value = json.encode(false)
      }

      local node_to_reply = tostring(rejectAppend_message.toNode)
      local node_proxy = node.peerProxies[node_to_reply]
      SendMessage(rejectAppend_message, node_proxy)

      return
    end

    -- Case 2: Everything ok
    node:resetElectionTimer()
    node:resetVotedFor()
    node:resetVoteCount()
    node:setState(states.Follower)
    node:setTerm(message.term)

    local sendAppendEntriesReply_msg = {
      term = node:getCurrentTerm(),
      fromNode = node.port,
      toNode = message.fromNode,
      type = "AppendEntriesReply",
      value = json.encode("")
    }

    local node_to_reply = tostring(sendAppendEntriesReply_msg.toNode)
    local node_proxy = node.peerProxies[node_to_reply]
    SendMessage(sendAppendEntriesReply_msg, node_proxy)
  end,
  AppendEntriesReply = function(message)

    -- Case 1: message w/ stale term
    if message.term < node:getCurrentTerm() then
      return -- ignore
    end

    -- Case 2: RPC response contains term T > currentTerm:
    if message.term > node:getCurrentTerm() then
      -- set currentTerm = T, convert to follower
      print("LuaRaft: AppendEntriesReply is converting node " ..
      node:getPort() .. " to follower" .. " " ..
      luaclock.GetFormattedHour())

      node:setState(states.Follower)
      node:setCurrentTerm(message.term)
      node:resetVoteCount()
      node:resetVotedFor()

      return
    end

    -- Case 3: Append entries rejected
    local response_val = json.decode(message.value)
    if response_val == false then -- reset node
      print("LuaRaft: AppendEntriesReply is converting node " ..
            node:getPort() .. " to follower" .. " " ..
            luaclock.GetFormattedHour())

      node:setState(states.Follower)
      node:setCurrentTerm(message.term)
      node:resetVoteCount()
      node:resetVotedFor()

      return
    end

    print("LuaRaft: AppendEntriesReply ok")
  end
}

function ProcessReceivedMessages()
  while node:hasMessages() do
    local message = node:popMessage()

    print("LuaRaft: Processing Received Message of type " .. message.type
          .. " " .. luaclock.GetFormattedHour())

    if message.type ~= nil then
      -- calling request/reply callbacks
      messageTypes[message.type](message)
    end
  end
end

function SendMessage(message, proxy)
  print("LuaRaft: Node " .. message.fromNode .. " is sending a message of type "
        .. message.type .. " to " .. message.toNode .. " " ..
        luaclock.GetFormattedHour())

  local _, err = proxy.ReceiveMessage(message)

  if err then
    print("LuaRaft: Node " .. message.fromNode ..
          " could not send message to node " .. message.toNode)
  end
end

-------------------------------------------------------------------------------
-- Leader Election
-------------------------------------------------------------------------------

function InitElection()
  print("LuaRaft: Init Election")

  node:resetVoteCount()
  node:resetVotedFor()

  node:setState(states.Candidate) -- convert to candidate
  node:incrementCurrentTerm() -- increment currentTerm
  node:incrementVoteCount() -- vote for self
  node:setVotedFor(node.port)
  node:resetElectionTimer() -- reset election timer

  -- Send RequestVote RPCs to all other servers
  local requestVote_msg = {
    term = node:getCurrentTerm(),
    fromNode = node.port,
    type = "RequestVote",
    value = json.encode("")
  }

  for _, port in pairs(node.peerPorts) do
    requestVote_msg.toNode = port
    SendMessage(requestVote_msg, node.peerProxies[port])
  end
end

function BecomeLeader()
  node:setState(states.Leader)

  print("LuaRaft: Node " .. node:getPort() .. " became the Leader for term " ..
         node:getCurrentTerm() .. " with " .. node:getVoteCount() .. " votes " ..
         luaclock.GetFormattedHour())

  -- Upon election: send initial empty AppendEntries RPCs (heartbeat) to each
  -- server
  local heartbeat_msg = {
    term = node.currentTerm,
    fromNode = node.port,
    type = "AppendEntries",
    value = json.encode("")
  }

  for _, value in pairs(node.peerPorts) do
    heartbeat_msg.toNode = value
    SendMessage(heartbeat_msg, node.peerProxies[value])
  end
end

function HasQuorum()
  local max_votes = (#node.peerPorts + 1)
  return node:getVoteCount() >= ((max_votes) // 2) + 1
end

-------------------------------------------------------------------------------
-- RPC-API
-------------------------------------------------------------------------------

function luaraft.ReceiveMessage(message)
  if message.type then
    print("LuaRaft: Receiving message of type " .. message.type .. " " .. luaclock.GetFormattedHour())
    node:pushMessage(message)

    print("LuaRaft: Current message queue size " .. #node.receivedMessages)

    return "Message received"
  end
  return "Couldn't receive message"
end

-- Builds a node and starts its lifecycle
function luaraft.InitializeNode(port, peers)
  peers = json.decode(peers)

  -- Build node
  node = node_obj
  node:setPort(port)
  node:setPeerPorts(peers)
  node:addPeerProxies(peers)

  print("LuaRaft: Node " .. node:getPort() .. " initialized")

  node:resetElectionTimeout()

  print("LuaRaft: electionTimeout: " .. node:getElectionTimeout())

  node:resetElectionTimer()

  -- Lifecycle
  while node.isAlive do
    ProcessReceivedMessages()

    if node.state == states.Leader then
      print("LuaRaft: Node " .. node.port .. " is Leader " ..
            luaclock.GetFormattedHour())

      -- Upon election: send AppendEntries RPCs (heartbeat) to each server;
      -- repeat during idle periods to prevent election timeouts
      local heartbeat_msg = {
        term = node:getCurrentTerm(),
        fromNode = node:getPort(),
        type = "AppendEntries",
        value = json.encode("")
      }

      for _, peer_port in pairs(node.peerPorts) do
        heartbeat_msg.toNode = peer_port
        SendMessage(heartbeat_msg, node.peerProxies[peer_port])
      end
    else
      if node.state == states.Follower then
        print("LuaRaft: Node " .. node:getPort() .. " is Follower " ..
              luaclock.GetFormattedHour())

        -- If election timeout elapses without receiving AppendEntries RPC from
        -- current leader or granting vote to candidate: convert to candidate
        if node:hasTimedOut() then
          InitElection()
        end
      else -- is Candidate
        print("LuaRaft: Node " .. node:getPort() .. " is Candidate " ..
              luaclock.GetFormattedHour())

        -- If election timeout elapses: start new election
        if node:hasTimedOut() then
          print("LuaRaft: Election timeout")
          -- Reset node
          node:setState(states.Follower)
          node:resetVoteCount()
          node:resetVotedFor()
          -- node:resetElectionTimeout()
        end
      end
    end
  end
end

-- Kills a node from the cluster
function luaraft.StopNode()
  node.isAlive = false
  print("LuaRaft: Node " .. node.port .. " stoped")
end

return luaraft