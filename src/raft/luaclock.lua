local luaclock = {}

-- Returns a string with the current time in the format %02d:%02d:%02d
function luaclock.GetFormattedHour()
  local time = os.date("*t")
  return ("%02d:%02d:%02d"):format(time.hour, time.min, time.sec)
end

return luaclock