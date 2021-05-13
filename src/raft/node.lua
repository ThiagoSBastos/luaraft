local queue = require("queue")
local states = require("states")
local timeouts = require("timeouts")

package.path = "../rpc/?.lua;" .. package.path
local luarpc = require("luarpc")

local IP = "127.0.0.1"
local idl = "../interface.lua"

local node = {
  state = states.Follower,
  receivedMessages = queue.new(),
  isAlive = true,
  port = {},
  peerPorts = {},
  peerProxies = {},
  votedFor = nil,
  voteCount = 0,
  currentTerm = 0,
  heartbeatTimeout = 0,
  electionTimeout = 0,

  pushMessage = function(self, message)
    queue.push(self.receivedMessages, message)
  end,
  popMessage = function(self)
    return queue.pop(self.receivedMessages)
  end,

  getPort = function(self) return self.port end,
  getVoteCount = function(self) return self.voteCount end,
  getState = function(self) return self.state end,
  getCurrentTerm = function(self) return self.currentTerm end,
  getHeartbeatTimeout = function(self) return self.heartbeatTimeout end,
  getElectionTimeout = function(self) return self.electionTimeout end,

  setState = function(self, newState)
    self.state = newState
  end,
  setNewHeartbeatTimeout = function(self)
    self.heartbeatTimeout = timeouts.GetTimeout("Heartbeat")
  end,
  setNewElectionTimeout = function(self)
    self.electionTimeout = timeouts.GetTimeout("Election")
  end,
  setPort = function(self, port)
    self.port = port
  end,
  setVotedFor = function(self, candidate)
    self.votedFor = candidate
  end,
  setPeerPorts = function(self, peerPorts)
    self.peerPorts = peerPorts
  end,
  addPeerProxies = function(self, peers)
    for id, peer_port in ipairs(peers) do
      table.insert(self.peerProxies, id, luarpc.createProxy(IP, peer_port, idl))
    end
  end,

  hasMessages = function(self)
    return queue.hasItems(self.receivedMessages)
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