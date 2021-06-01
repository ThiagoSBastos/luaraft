local states = require("states")
local timeouts = require("timeouts")

package.path = "../rpc/?.lua;" .. package.path
local luarpc = require("luarpc")

local IP = "127.0.0.1"
local idl = "../interface.lua"

local node = {
  state = states.Follower,
  receivedMessages = {},
  isAlive = true,
  port = {},
  peerPorts = {},
  peerProxies = {},
  votedFor = nil,
  voteCount = 0,
  currentTerm = 0,
  electionTimeout = 0,
  start_timeout = 0,

  pushMessage = function(self, message)
    table.insert(self.receivedMessages, message)
  end,
  popMessage = function(self)
    return table.remove(self.receivedMessages, 1)
  end,

  getPort = function(self) return self.port end,
  getVoteCount = function(self) return self.voteCount end,
  getState = function(self) return self.state end,
  getCurrentTerm = function(self) return self.currentTerm end,
  getElectionTimeout = function(self) return self.electionTimeout end,
  getLeaderWaitTime = function(self) return self.leaderWaitTime end,

  setState = function(self, newState)
    self.state = newState
  end,
  setPort = function(self, port)
    self.port = port
  end,
  setVotedFor = function(self, candidate)
    self.votedFor = candidate
  end,
  setCurrentTerm = function (self, term)
    self.currentTerm = term
  end,
  setPeerPorts = function(self, peerPorts)
    self.peerPorts = peerPorts
  end,
  addPeerProxies = function(self, peers)
    for _, peer_port in pairs(peers) do
      self.peerProxies[peer_port] = luarpc.createProxy(IP, peer_port, idl)
    end
  end,

  hasMessages = function(self)
    return #self.receivedMessages > 0
  end,
  hasTimedOut = function(self)
    return os.difftime(os.time(), self.start_timeout) > self.electionTimeout
  end,

  resetElectionTimeout = function(self)
    self.electionTimeout = timeouts.GetTimeout("Election")
  end,
  resetElectionTimer = function(self)
    self.start_timeout = os.time()
  end,
  resetVotedFor = function(self)
    self.votedFor = nil
  end,
  resetVoteCount = function(self)
    self.voteCount = 0
  end,
  incrementCurrentTerm = function(self)
    self.currentTerm = self.currentTerm + 1
  end,
  incrementVoteCount = function(self)
    self.voteCount = self.voteCount + 1
  end
}

return node