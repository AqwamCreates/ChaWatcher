# Anomaly Detection (Original Version)

```lua

local ServerScriptService = game:GetService("ServerScriptService")

local MatrixL = require(ServerScriptService.MatrixL)

local ChaWatcher = require(ServerScriptService.ChaWatcher)

local AnomalyDetector = ChaWatcher.Original.AnomalyDetector.new() -- Setting to defaults.

-- First argument above is the normal threshold. If the predicted value is less than the normal threshold, then the player is considered not nornal.

AnomalyDetector:bindToOutlierFound(function(Player, predictedValue, fullDataVector) -- Runs a function if player's data is an outlier.

	print(Player.Name .. " has an outlier data!")

end)

AnomalyDetector:bindToHeartbeat(function(Player, predictedValue, fullDataVector) -- Runs a function on every heartbeat.

	print(Player.Name .. "\'s data has been collected!")

	local distance = fullDataVector[14]

end)

AnomalyDetector:bindToMissingData(function(Player) -- Runs a function if cannot create a data vector.

	print(Player.Name .. " has missing data!")

	local currentDataVector, previousDataVector = AnomalyDetector:getPlayerDataVectors()

end)

AnomalyDetector:start() -- Starts detecting outlier data.
AnomalyDetector:stop()  -- Stops detecting outlier data.
AnomalyDetector:start() -- Starts detecting outlier data. Again!

```
