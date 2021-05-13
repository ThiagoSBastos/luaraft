local math = require("math")
math.randomseed(os.time()) -- random initialize
math.random(); math.random(); math.random() -- warming up

local timeouts = {}

local electionTimeoutMin  = 8.0
local electionTimeoutMax  = 11.0
local heartbeatTimeoutMin = 3.0
local heartbeatTimeoutMax = 6.0

local timeoutsList = {
  Election = function ()
    return math.random()*(electionTimeoutMax - electionTimeoutMin) + electionTimeoutMin
  end,
  Heartbeat = function()
    return math.random()*(heartbeatTimeoutMax - heartbeatTimeoutMin) + heartbeatTimeoutMin
  end
}

function timeouts.GetTimeout(type)
  return timeoutsList[type]()
end

return timeouts