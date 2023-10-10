# Data Collection

```lua

local ChaWatcher = require(ServerScriptService:WaitForChild("ChaWatcher"))

local DataCollector = ChaWatcher.DataCollector.new(true, "1")

DataCollector:bindToHeartbeat(function(Player, fullDataVector)

	print(Player.Name .. "\'s data has been collected!")

end)

DataCollector:bindToMissingData(function(Player) -- Runs a function if cannot create data vector.

	print(Player.Name .. "\'s data has missing data!")

	local currentDataVector, previousDataVector = DataCollector:getPlayerDataVectors()

end)

DataCollector:start() -- Starts collecting data
DataCollector:stop()  -- Stops collecting data

game:BindToClose(function()

	local fullData = DataCollector:getFullData()
	print(fullData)

	DataCollector:saveFullDataOnline() -- Saves data to online

end)

```
