# Data Collection (Original Version)

```lua

local ServerScriptService = game:GetService("ServerScriptService")

local MatrixL = require(ServerScriptService.MatrixL)

local ChaWatcher = require(ServerScriptService.ChaWatcher)

local DataCollector = ChaWatcher.Original.DataCollector.new(true, "1")

DataCollector:bindToMissingData(function(Player, currentDataVector, previousDataVector) -- Runs a function if cannot create a data vector.

	print(Player.Name .. " has missing data!")

end)

DataCollector:start() -- Starts collecting data.
DataCollector:stop()  -- Stops collecting data.
DataCollector:start() -- Starts collecting data. Again!

game:BindToClose(function()

	local fullData = DataCollector:getFullData()
	MatrixL:printMatrixWithComma(fullData)

	DataCollector:saveFullDataOnline() -- Saves data to online

end)

```
