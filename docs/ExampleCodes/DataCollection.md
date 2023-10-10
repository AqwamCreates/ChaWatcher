# Data Collection

```lua

local ChaWatcher = require(ServerScriptService:WaitForChild("ChaWatcher"))

local DataCollector = ChaWatcher.DataCollector.new(true, "1")

DataCollector:bindToHeartbeat(function(Player, fullDataVector)

	print(Player.Name .. "\'s data has been collected!")

end)

DataCollector:bindToMissingData(function(Player)

	print(Player.Name .. "\'s data has missing data!")

end)

DataCollector:start() -- Starts collecting data
DataCollector:stop()  -- Stops collecting data

game:BindToClose(function()

	DataCollector:saveFullDataOnline() -- Saves data to online

end)

```
