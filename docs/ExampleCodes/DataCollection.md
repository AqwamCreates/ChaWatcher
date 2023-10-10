```lua

local ChaWatcher = require(ServerScriptService:WaitForChild("ChaWatcher"))

local DataCollector = ChaWatcher.DataCollector.new(true, "1")

DataCollector:bindToHeartbeat(function(Player, fullDataVector)

end)

DataCollector:bindToMissingData(function(Player, fullDataVector)

end)

DataCollector:start() -- Starts collecting data
DataCollector:stop()  -- Stops collecting data

game:BindToClose(function()

	DataCollector:saveFullDataOnline() -- Saves data to online

end)


```
