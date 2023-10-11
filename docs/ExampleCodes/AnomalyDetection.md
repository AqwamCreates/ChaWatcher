# Anomaly Detection (Original Version)

```lua

local ServerScriptService = game:GetService("ServerScriptService")

local MatrixL = require(ServerScriptService.MatrixL)

local ChaWatcher = require(ServerScriptService.ChaWatcher)

local DataCollector = ChaWatcher.Original.DataCollector.new(true, "1")

DataCollector:bindToHeartbeat(function(Player, fullDataVector) -- Runs a function on every heartbeat.

	print(Player.Name .. "\'s data has been collected!")

	local distance = fullDataVector[14]

end)

DataCollector:bindToMissingData(function(Player) -- Runs a function if cannot create data vector.

	print(Player.Name .. " has missing data!")

	local currentDataVector, previousDataVector = DataCollector:getPlayerDataVectors()

end)

DataCollector:start() -- Starts collecting data.
DataCollector:stop()  -- Stops collecting data.
DataCollector:start() -- Starts collecting data. Again!

game:BindToClose(function()

	local fullData = DataCollector:getFullData()
	MatrixL:printMatrix(fullData)

	DataCollector:saveFullDataOnline() -- Saves data to online

end)

```
