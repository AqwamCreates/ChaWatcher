# Anomaly Detection (Distributed Computing Version)

```lua

local ServerScriptService = game:GetService("ServerScriptService")

local MatrixL = require(ServerScriptService.MatrixL)

local ChaWatcher = require(ServerScriptService.ChaWatcher)

local AnomalyDetector = ChaWatcher.DistributedComputing.AnomalyDetector.new() -- Setting to default.

-- maxPlayersToWatchPerPlayers: The maximum number of players that each player needs to watch.
-- normalThreshold: If the predicted value is less than the normal threshold, then the player is considered not nornal.
-- maxAveragePredictedValuesDifferemce: If the average predicted value difference is larger than this, suspect somebody has altered our data!

AnomalyDetector:bindToOutlierFound(function(Player, predictedValue) -- Runs a function if player's data is an outlier.

	print(Player.Name .. " has an outlier data!")

end)

AnomalyDetector:bindToAbnormalPredictedValues(function(WatchedPlayer, watchedByPlayerArray, predictedValuesArray) -- Runs a function when average predicted values difference is greater than maxAveragePredictedValuesDifferemce.

	print(Player.Name .. "\'s data has been collected!")

	local Player = watchedByPlayerArray[1]
	local predictedValue = predictedValuesArray[1]

end)

AnomalyDetector:bindToMissingData(function(WatchingPlayer, WatchedPlayer, currentDataVector, previousDataVector) -- Runs a function if cannot create a data vector.

	print(WatchedPlayer.Name .. " has missing data!")

end)

AnomalyDetector:bindToPredictedValueReceived(function(WatchingPlayer, WatchedPlayer, predictedValue, fullDataVector) -- Runs a function on predicted value received

	print(WatchedPlayer.Name .. " has missing data!")

	local distance = fullDataVector[14]
	
end)

AnomalyDetector:bindToClientAccessedRemoteEvent(function(Player) -- Runs a function if cannot create a data vector.

	print(Player.Name .. " tried to change access remote events!")

end)

AnomalyDetector:start() -- Starts detecting outlier data.
AnomalyDetector:stop()  -- Stops detecting outlier data.
AnomalyDetector:start() -- Starts detecting outlier data. Again!

```
