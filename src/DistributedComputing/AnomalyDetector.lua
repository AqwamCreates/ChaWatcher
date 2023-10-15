local Players = game:GetService("Players")

local RunService = game:GetService("RunService")

local ModelCreatorDataStore = game:GetService("DataStoreService"):GetDataStore("AqwamChaWatcherModelCreatorDataStore")

local DistributedComputingSetup = require(script.Parent.DistributedComputingSetup)

local clientName = DistributedComputingSetup:getClientName()

local RemoteEvents, ChaWatcherDistributedComputingClient = DistributedComputingSetup:setup()

local ActivateClientAnomalyDetectorRemoteEvent = RemoteEvents.ActivateClientAnomalyDetectorRemoteEvent

local SendPredictedValueRemoteEvent = RemoteEvents.SendPredictedValueRemoteEvent

local SetPlayerToWatchRemoteEvent = RemoteEvents.SetPlayerToWatchRemoteEvent

local OnMissingDataRemoteEvent = RemoteEvents.OnMissingDataRemoteEvent

AnomalyDetector = {}

AnomalyDetector.__index = AnomalyDetector

local function iskeyExistsInTable(tableToSearch, keyToFind)
	
	for key, _ in pairs(tableToSearch) do
		
		if (key == keyToFind) then return true end
		
	end
	
	return false
end

local function convertStringUserIdToPlayer(stringUserId)
	
	local userId = tonumber(stringUserId)

	if not userId then return nil end

	local Player = Players:GetPlayerByUserId(userId)
	
	return Player
	
end
	
function AnomalyDetector:bindToMissingData(functionToRun)

	self.OnMissingDataFunction = functionToRun

end

function AnomalyDetector:bindToClientAccessedRemoteEvent(functionToRun)

	self.OnClientAccessedFunction = functionToRun

end

function AnomalyDetector:bindToOutlierFound(functionToRun)

	self.OutlierFoundFunction = functionToRun

end

function AnomalyDetector:bindToAbnormalPredictedValues(functionToRun)
	
	self.AbnormalPredictedValuesFunction = functionToRun
	
end

function AnomalyDetector:bindToPredictedValueReceived(functionToRun)
	
	self.PredictedValueReceivedFunction = functionToRun
	
end

function AnomalyDetector:getStringUserIdsWithEmptyWatchSlots(stringUserIdExeption)
	
	local stringUserIdArray = {}
	
	for otherStringUserId, watchedPlayersTable in self.PlayerWatchListStringUserIds do
		
		if (otherStringUserId == stringUserIdExeption) then continue end

		local numberOfPlayersWatching = 0
		
		for _, _ in watchedPlayersTable do numberOfPlayersWatching += 1 end
		
		if (numberOfPlayersWatching >= self.MaxPlayersToWatchPerPlayer) then continue end
		
		table.insert(stringUserIdArray, otherStringUserId)

	end
	
	return stringUserIdArray
	
end

function AnomalyDetector:assignWatchListRandomly(stringUserId)
	
	local numberOfWatchedBy = 0
	
	local otherStringUserIdArray = self:getStringUserIdsWithEmptyWatchSlots(stringUserId)

	while (numberOfWatchedBy < self.MaxPlayersToWatchPerPlayer) and (#otherStringUserIdArray > 0) and (#Players:GetPlayers() > 1) do

		local randomIndex = Random.new():NextInteger(1, #otherStringUserIdArray)

		local randomStringUserId = otherStringUserIdArray[randomIndex]

		local PlayerToSet = Players:GetPlayerByUserId(tonumber(randomStringUserId))

		if not PlayerToSet then continue end

		table.insert(self.PlayerWatchListStringUserIds[randomStringUserId], stringUserId)

		SetPlayerToWatchRemoteEvent:FireClient(PlayerToSet, self.PlayerWatchListStringUserIds[randomStringUserId])

		table.remove(otherStringUserIdArray, randomIndex)

		numberOfWatchedBy += 1

	end 
	
end

function AnomalyDetector:reassignWatchListForAllPlayersRandomly()
	
	self.isWatchListCurrentlyReassigned = true

	local PlayersArray = Players:GetPlayers()

	for _, OtherPlayer in PlayersArray do -- Delete everything first before 

		local stringUserId = tostring(OtherPlayer.UserId)

		self.ReceivedPredictedValues[stringUserId] = {}

		self.PlayerWatchListStringUserIds[stringUserId] = {}

	end

	for _, OtherPlayer in PlayersArray do self:assignWatchListRandomly(tostring(OtherPlayer.UserId)) end

	self.isWatchListCurrentlyReassigned = false
	
end

function AnomalyDetector:onPlayerRemoving(Player)
	
	self:reassignWatchListForAllPlayersRandomly()
	
	self.TimeSinceLastUpdate[tostring(Player.UserId)] = nil

end

function AnomalyDetector:onPlayerAdded(Player: Player)
	
	ActivateClientAnomalyDetectorRemoteEvent:FireClient(Player, true, self.Settings)
	
	local stringUserId = tostring(Player.UserId)
	
	self:reassignWatchListForAllPlayersRandomly()
	
	SetPlayerToWatchRemoteEvent:FireClient(Player, self.PlayerWatchListStringUserIds[stringUserId])
	
	self.TimeSinceLastUpdate[stringUserId] = os.time()
	
end

function AnomalyDetector:onPredictedValueReceived(WatchingPlayer: Player, watchedPlayerStringUserId: number, predictedValue: number, fullDataVector)
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	local watchingPlayerStringUserId = tostring(WatchingPlayer.UserId)
	
	self.TimeSinceLastUpdate[watchingPlayerStringUserId] = os.time()
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	if self.isWatchListCurrentlyReassigned then return end
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	local isNotCorrectFormat = (typeof(watchedPlayerStringUserId) ~= "string") or (typeof(predictedValue) ~= "number")

	if (isNotCorrectFormat) then 

		if self.OnClientAccessedFunction then self.OnClientAccessedFunction(WatchingPlayer) end
		return

	end
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	local WatchedPlayer = convertStringUserIdToPlayer(watchedPlayerStringUserId)
	
	if self.PredictedValueReceivedFunction then self.PredictedValueReceivedFunction(WatchingPlayer, WatchedPlayer, predictedValue, fullDataVector) end
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	local serverHasMoreThanOnePlayer = (#Players:GetPlayers() > 1)
	
	if (watchingPlayerStringUserId == watchedPlayerStringUserId) and (serverHasMoreThanOnePlayer) then 
		
		if self.OnClientAccessedFunction then self.OnClientAccessedFunction(WatchingPlayer) end
		return
			
	end
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	local isWatchingPlayerNotSupposedToWatchThisPlayer = not iskeyExistsInTable(self.PlayerWatchListStringUserIds[watchingPlayerStringUserId], watchedPlayerStringUserId)
	
	if (isWatchingPlayerNotSupposedToWatchThisPlayer) and (serverHasMoreThanOnePlayer) then 

		if self.OnClientAccessedFunction then self.OnClientAccessedFunction(WatchingPlayer) end
		return

	end
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	local watchedPlayerReceivedPredictedValues = self.ReceivedPredictedValues[watchedPlayerStringUserId]
	
	if not watchedPlayerReceivedPredictedValues then return end
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	watchedPlayerReceivedPredictedValues[watchingPlayerStringUserId] = predictedValue
	
	local averageDifference = 0
	
	local watchedByPlayerArray = {}
	
	local predictedValuesArray = {}

	for watchedByPlayerStringUserId, otherPredictedValue in watchedPlayerReceivedPredictedValues do
		
		if (watchedByPlayerStringUserId == watchingPlayerStringUserId) then continue end
		
		local WatchedByPlayer = convertStringUserIdToPlayer(watchedByPlayerStringUserId)

		if not WatchedByPlayer then continue end
		
		if (WatchedByPlayer:GetNetworkPing() > 0.3) then continue end

		if (typeof(otherPredictedValue) ~= "number") then continue end

		averageDifference += math.abs(predictedValue - otherPredictedValue)
		
		table.insert(watchedByPlayerArray, WatchedByPlayer)
		
		table.insert(predictedValuesArray, watchedPlayerReceivedPredictedValues[watchedByPlayerStringUserId])

	end
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	local numberOfWatchingPlayers = #watchedByPlayerArray
	
	if (numberOfWatchingPlayers > 1) then averageDifference /= (numberOfWatchingPlayers - 1) end
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	if (averageDifference > self.MaxAveragePredictedValuesDifference) then
		
		self.AbnormalPredictedValuesFunction(WatchedPlayer, watchedByPlayerArray, predictedValuesArray)
		
	else
		
		if (predictedValue < self.NormalThreshold) and self.OutlierFoundFunction then self.OutlierFoundFunction(WatchingPlayer, WatchedPlayer, predictedValue, fullDataVector) end
			
	end
	
end

function AnomalyDetector:checkForLastUpdate(Player: Player, currentTime: number)
	
	if not Player then return end
	
	local playerStringUserId = tostring(Player.UserId)
	
	local lastUpdatedTime = self.TimeSinceLastUpdate[playerStringUserId] or os.time()

	local timeDifference = currentTime - lastUpdatedTime
	
	if timeDifference <= 10 then return end
	
	local clientScript = Player.PlayerScripts:FindFirstChild(clientName)
	
	if clientScript and self.OnClientAccessedFunction then self.OnClientAccessedFunction(Player) end
		
	ChaWatcherDistributedComputingClient:Clone().Parent = Player.PlayerGui 
	
	self.TimeSinceLastUpdate[playerStringUserId] = os.time()
	
	task.delay(1, function()
		
		SetPlayerToWatchRemoteEvent:FireClient(Player, self.PlayerWatchListStringUserIds[playerStringUserId])
		
	end)
	
end

function AnomalyDetector:createConnectionsArray()

	local PlayerAddedConnection = Players.PlayerAdded:Connect(function(Player)

		self:onPlayerAdded(Player)

	end)

	local PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(Player)

		self:onPlayerRemoving(Player)

	end)

	local SendPredictedValueRemoteEventConnection = SendPredictedValueRemoteEvent.OnServerEvent:Connect(function(WatchingPlayer, watchedPlayerStringUserId, predictedValue, fullDataVector)
		
		if not WatchingPlayer then return end

		self:onPredictedValueReceived(WatchingPlayer, watchedPlayerStringUserId, predictedValue, fullDataVector)

	end)

	local SetPlayerToWatchRemoteEventConnection = SetPlayerToWatchRemoteEvent.OnServerEvent:Connect(function(Player)

		if self.OnClientAccessedFunction then self.OnClientAccessedFunction(Player) end

	end)

	local ActivateClientAnomalyDetectorRemoteEventConnection = ActivateClientAnomalyDetectorRemoteEvent.OnServerEvent:Connect(function(Player)

		if self.OnClientAccessedFunction then self.OnClientAccessedFunction(Player) end

	end)
	
	local OnMissingDataRemoteEventConnection = OnMissingDataRemoteEvent.OnServerEvent:Connect(function(WatchingPlayer, watchedPlayerStringUserId, currentDataVector, previousDataVector)

		if (typeof(WatchingPlayer) ~= "Player") or (typeof(watchedPlayerStringUserId) ~= "string") then return end

		local WatchedPlayer = convertStringUserIdToPlayer(watchedPlayerStringUserId)

		if not WatchedPlayer then return end

		if self.OnMissingDataFunction then self.OnMissingDataFunction(WatchingPlayer, WatchedPlayer, currentDataVector, previousDataVector) end

	end)
	
	local HeartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
		
		local currentTime = os.time()
		
		for _, Player in Players:GetPlayers() do	
			
			pcall(function() self:checkForLastUpdate(Player, currentTime) end)
			
		end
		
	end)
	
	local ConnectionsArray = {
		
		PlayerAddedConnection, PlayerRemovingConnection, 
		SendPredictedValueRemoteEventConnection, SetPlayerToWatchRemoteEventConnection, 
		ActivateClientAnomalyDetectorRemoteEventConnection, OnMissingDataRemoteEventConnection,
		HeartbeatConnection
		
	}

	return ConnectionsArray

end

local function fetchSettings(useOnlineModel: boolean, key: string)

	if useOnlineModel then

		return ModelCreatorDataStore:GetAsync(key)

	else

		return require(script.Parent.OfflineModelSettings)[key]

	end

end

function AnomalyDetector.new(maxPlayersToWatchPerPlayer: number, normalThreshold: number, maxAveragePredictedValuesDifference: number, useOnlineModel: boolean, key: string)

	local NewAnomalyDetector = {}

	setmetatable(NewAnomalyDetector, AnomalyDetector)

	key = key or "default"

	if (typeof(key) ~= "string") then error("Key is not a string value!") end

	local Settings = fetchSettings(useOnlineModel, key)

	if not Settings then error("No Settings Found!") end
	
	maxPlayersToWatchPerPlayer = maxPlayersToWatchPerPlayer or Settings["maxPlayersToWatchPerPlayer"] or 2

	if (typeof(maxPlayersToWatchPerPlayer) ~= "number") then error("Maximum players to watch is not a number value!") end

	normalThreshold = normalThreshold or Settings["normalThreshold"]

	if (typeof(normalThreshold) ~= "number") then error("Normal threshold is not a number value!") end
	
	maxAveragePredictedValuesDifference = maxAveragePredictedValuesDifference or Settings["maxPredictedValuesDifferenceAverage"] or 5

	if (typeof(maxAveragePredictedValuesDifference) ~= "number") then error("Maximum predicted values difference average is not a number value!") end
	
	NewAnomalyDetector.Settings = Settings
	
	NewAnomalyDetector.NormalThreshold = normalThreshold

	NewAnomalyDetector.MaxAveragePredictedValuesDifference = maxAveragePredictedValuesDifference
	
	NewAnomalyDetector.MaxPlayersToWatchPerPlayer = maxPlayersToWatchPerPlayer
	
	NewAnomalyDetector.PlayerWatchListStringUserIds = {}

	NewAnomalyDetector.ConnectionsArray = {}
	
	NewAnomalyDetector.ReceivedPredictedValues = {}
	
	NewAnomalyDetector.TimeSinceLastUpdate = {}
	
	NewAnomalyDetector.isWatchListCurrentlyReassigned = false

	return NewAnomalyDetector

end

function AnomalyDetector:start()

	self.ConnectionsArray = self:createConnectionsArray()

	ActivateClientAnomalyDetectorRemoteEvent:FireAllClients(true, self.Settings)

end

function AnomalyDetector:stop()

	ActivateClientAnomalyDetectorRemoteEvent:FireAllClients(false)

	for _, Connection in ipairs(self.ConnectionsArray) do Connection:Disconnect() end

end

function AnomalyDetector:destroy()
	
	self:stop()
	
	SendPredictedValueRemoteEvent:Destroy()

	SetPlayerToWatchRemoteEvent:Destroy()

	ActivateClientAnomalyDetectorRemoteEvent:Destroy()

	table.clear(self)

	AnomalyDetector = nil

end

return AnomalyDetector
