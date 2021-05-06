package.path = "../rpc/?.lua;" .. package.path
local luarpc = require("luarpc")

local luaraft = {}

local nodes = {}

local nodeProps = {
  -- Persistent state
  currentTerm = 0,
  votedFor = 0,
  log = {},
  -- Volatile state on all servers
  commitIndex = 0,
  lastApplied = 0,
  -- Volatile state on all leaders (reinitialized after election)
  nextIndex = {},
  matchIndex = {}
}

local nodeState = {
  Leader    = 1,
  Follower  = 2,
  Candidate = 3
}

local electionTimeout = {
  Min = 5,
  Max = 10
}

local heartbeatTimeout = 2

-------------------- LEADER ELECTION --------------------

-- Is initiated by candidates during elections
local function RequestVote(term, candidateId, lastLogIndex, lastLogTerm)
  return term, voteGranted
end

local function RequestVoteReply() end

-- Is initiated by leaders to replicate log entries to
-- provide a form of heartbeat
local function AppendEntries() end


local function isMajority()
  return votes > numberOfNodes/2
end

------------------------ RPC-API ------------------------
function luaraft.ReceiveMessage(messageStruct)
  print("Receiving message")
end

function luaraft.InitializeNode()
  -- Initialize node state

  -- Append node in the node array?

  --while nodeisAlive do
    -- processReceivedMessages
    -- processSentMessages

    -- Se for o leader, tem que mudar o comitt e mandar appendEntries

  --end

  luarpc.wait(2)

  print("Node Initialized from LuaRaft")
end

function luaraft.StopNode()
    print("Node stoped from LuaRaft")
end

function luaraft.ApplyEntry(someInt)

  while true do

  end


  print("Apply Entries from LuaRaft")

  return "something"
end

-- Prints the current state
function luaraft.Snapshot()
  --for k,v in pairs() do

  --end
end

return luaraft