local math = require("math")
math.randomseed(os.time()) -- random initialize
math.random(); math.random(); math.random() -- warming up

local timeouts = {}

local electionTimeoutMin  = 5.0
local electionTimeoutMax  = 10.0

local timeoutsList = {
  Election = function()
    return math.random()*(electionTimeoutMax - electionTimeoutMin) + electionTimeoutMin
  end
}

function timeouts.GetTimeout(type)
  return timeoutsList[type]()
end

return timeouts