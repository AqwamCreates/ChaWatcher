# Anomaly Detection (Original Version)

```lua

local ServerScriptService = game:GetService("ServerScriptService")

local MatrixL = require(ServerScriptService.MatrixL)

local ChaWatcher = require(ServerScriptService.ChaWatcher)

local AnomalyDetector = ChaWatcher.Original.DataCollector.new(0.5, false) -- First argument is the normal threshold. If the predicted value from the model is higher than this, the player is considered "normal".

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
