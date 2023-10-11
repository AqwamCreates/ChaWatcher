# Anomaly Detection (Original Version)

```lua

local ServerScriptService = game:GetService("ServerScriptService")

local MatrixL = require(ServerScriptService.MatrixL)

local ChaWatcher = require(ServerScriptService.ChaWatcher)

local AnomalyDetector = ChaWatcher.Original.DataCollector.new(true, "1")

AnomalyDetector:bindToOutlierFound(function(Player) -- Runs a function if player's data is an outlier

	print(Player.Name .. " has an outlier data!")

	local currentDataVector, previousDataVector = AnomalyDetector:getPlayerDataVectors()

end)

AnomalyDetector:bindToHeartbeat(function(Player, fullDataVector) -- Runs a function on every heartbeat.

	print(Player.Name .. "\'s data has been collected!")

	local distance = fullDataVector[14]

end)

AnomalyDetector:bindToMissingData(function(Player) -- Runs a function if cannot create data vector.

	print(Player.Name .. " has missing data!")

	local currentDataVector, previousDataVector = AnomalyDetector:getPlayerDataVectors()

end)

AnomalyDetector:start() -- Starts collecting data.
AnomalyDetector:stop()  -- Stops collecting data.
AnomalyDetector:start() -- Starts collecting data. Again!

```
