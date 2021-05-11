local math = require("math")
math.randomseed(os.time()) -- random initialize
math.random(); math.random(); math.random() -- warming up

local timeouts = {}

local electionTimeoutMin  = 7
local electionTimeoutMax  = 10
local heartbeatTimeoutMin = 3
local heartbeatTimeoutMax = 5

local timeoutsList = {
  Election = function ()
    return math.random()*(electionTimeoutMax - electionTimeoutMin) + electionTimeoutMin
  end,
  Heartbeat = function()
    return math.random()*(heartbeatTimeoutMax - heartbeatTimeoutMin) + heartbeatTimeoutMin
  end
}

function timeouts.getTimeout(type)
  return timeoutsList[type]()
end

return timeouts
