
local messageTypes = {
  RequestVote = function()
    print("Hello from RequestVote")
    return 1
  end,
  RequestVoteReply = function ()
    return 1
  end,
  SendHeartbeat = function ()
    return 1
  end
}

return messageTypes
