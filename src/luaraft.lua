local luaraft = {}

local nodeProps = {
  currentTerm = 0,
  votedFor = 0
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
-- [
-- Is initiated by candidates during elections
-- ]
local function RequestVote() end
local function RequestVoteReply() end

-- [
-- Is initiated by leaders to replicate log entries to
-- provide a form of heartbeat
-- ]
local function AppendEntries() end


local function isMajority()
  return votes > numberOfNodes/2
end

------------------------ RPC-API ------------------------
function luaraft.ReceiveMessage()
  print("Receiving message")
end

function luaraft.InitializeNode()
  print("Node Initialized from LuaRaft")
end

function luaraft.StopNode()
    print("Node stoped from LuaRaft")
end

function luaraft.ApplyEntry(term, leaderId)
    print("Apply Entries from LuaRaft")
end


return luaraft