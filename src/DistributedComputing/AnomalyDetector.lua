local Players = game:GetService("Players")

local RunService = game:GetService("RunService")

local ModelCreatorDataStore = game:GetService("DataStoreService"):GetDataStore("AqwamChaWatcherModelCreatorDataStore")

local DistributedComputingSetup = require(script.Parent.DistributedComputingSetup)

local clientName = DistributedComputingSetup:getClientName()

local RemoteEvents = DistributedComputingSetup:setup()

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

	local WatchedPlayer = Players:GetPlayerByUserId(userId)
	
	return WatchedPlayer
	
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

function AnomalyDetector:onPlayerRemoving(Player: Player)

	local UserId = Player.UserId

	local stringUserId = tostring(UserId)

	for watchedByPlayerStringUserId, _ in self.ReceivedPredictedValues[stringUserId] do

		local playerWatchList = self.PlayerWatchListStringUserIds[watchedByPlayerStringUserId] 

		local index = table.find(playerWatchList, UserId)

		if index then table.remove(playerWatchList, index) end
		
		local PlayerToSet = convertStringUserIdToPlayer(watchedByPlayerStringUserId)
		
		if not PlayerToSet then continue end
		
		SetPlayerToWatchRemoteEvent:FireClient(PlayerToSet, self.PlayerWatchListStringUserIds[watchedByPlayerStringUserId])

	end

	self.ReceivedPredictedValues[stringUserId] = nil
	
	self.PlayerWatchListStringUserIds[stringUserId] = nil

end

function AnomalyDetector:onPlayerAdded(Player: Player)
	
	ActivateClientAnomalyDetectorRemoteEvent:FireClient(Player, true, self.Settings)
	
	local stringUserId = tostring(Player.UserId)

	local otherStringUserIdArray = self:getStringUserIdsWithEmptyWatchSlots(stringUserId)
	
	local stringUserIdToWatchArray = {}
	
	local numberOfWatchedBy = 0
	
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
	
	for otherStringUserId, watchedByPlayerStringUserIds in self.ReceivedPredictedValues do
		
		local numberOfPlayersWatchedByForOtherPlayer = 0
		
		for watchedByPlayerStringUserId, otherPredictedValue in watchedByPlayerStringUserIds do numberOfPlayersWatchedByForOtherPlayer += 1 end
		
		if (numberOfPlayersWatchedByForOtherPlayer >= self.MaxPlayersToWatchPerPlayer) then continue end
		
		table.insert(stringUserIdToWatchArray, otherStringUserId)
		
	end
	
	self.PlayerWatchListStringUserIds[stringUserId] = stringUserIdToWatchArray
	
	self.ReceivedPredictedValues[stringUserId] = {}
	
	SetPlayerToWatchRemoteEvent:FireClient(Player, stringUserIdToWatchArray)
	
end

function AnomalyDetector:onPredictedValueReceived(WatchingPlayer: Player, watchedPlayerStringUserId: number, predictedValue: number)
	
	local numberOfPlayersInServer = #Players:GetPlayers()
	
	local watchingPlayerStringUserId = tostring(WatchingPlayer.UserId)
	
	local WatchedPlayer = convertStringUserIdToPlayer(watchedPlayerStringUserId)
	
	if (watchingPlayerStringUserId == watchedPlayerStringUserId) and (numberOfPlayersInServer > 1) and self.OnClientAccessedFunction then self.OnClientAccessedFunction(WatchingPlayer, WatchedPlayer, predictedValue) return end
	
	local isWatchingPlayerNotSupposedToWatchThisPlayer = not iskeyExistsInTable(self.PlayerWatchListStringUserIds[watchingPlayerStringUserId], watchedPlayerStringUserId)
	
	if (isWatchingPlayerNotSupposedToWatchThisPlayer) and self.OnClientAccessedFunction then self.OnClientAccessedFunction(WatchingPlayer) return end
	
	local isNotCorrectFormat = (typeof(watchedPlayerStringUserId) ~= "string") or (typeof(predictedValue) ~= "number")
		
	if (isNotCorrectFormat) and self.OnClientAccessedFunction then self.OnClientAccessedFunction(WatchingPlayer) return end
	
	local watchedPlayerReceivedPredictedValues = self.ReceivedPredictedValues[watchedPlayerStringUserId]
	
	if not watchedPlayerReceivedPredictedValues then return end

	watchedPlayerReceivedPredictedValues[watchingPlayerStringUserId] = predictedValue
	
	local averageDifference = 0
	
	local watchedByPlayerArray = {}

	for watchedByPlayerStringUserId, otherPredictedValue in watchedPlayerReceivedPredictedValues do
		
		if (watchedByPlayerStringUserId == watchingPlayerStringUserId) and (numberOfPlayersInServer > 1) then continue end
		
		local PlayerToSet = convertStringUserIdToPlayer(watchedByPlayerStringUserId)

		if not PlayerToSet then continue end
		
		if (PlayerToSet:GetNetworkPing() > 1) then continue end

		if (typeof(otherPredictedValue) ~= "number") then continue end

		averageDifference += math.abs(predictedValue - otherPredictedValue)
		
		table.insert(watchedByPlayerArray, watchedByPlayerStringUserId)

	end
	
	local numberOfWatchingPlayers = #watchedByPlayerArray
	
	if (numberOfWatchingPlayers > 1) then
		
		averageDifference /= (numberOfWatchingPlayers - 1)
		
	end

	if (averageDifference > self.MaxPredictedValuesDifferenceAverage) then
		
		local playersArray = {}
		
		local predictedValuesArray = {}
		
		for watchedByPlayerStringUserId, otherPredictedValue in watchedPlayerReceivedPredictedValues do
			
			local PlayerToSet = convertStringUserIdToPlayer(watchedByPlayerStringUserId)
				
			if not PlayerToSet then continue end
				
			table.insert(playersArray, PlayerToSet)
			table.insert(predictedValuesArray, otherPredictedValue)
			
		end
		
		self.AbnormalPredictedValuesFunction(WatchedPlayer, playersArray, predictedValuesArray)
		
	else
		
		if (predictedValue < self.NormalThreshold) and self.OutlierFoundFunction then self.OutlierFoundFunction(WatchedPlayer, predictedValue) end
			
	end
	
end

function AnomalyDetector:createConnectionsArray()

	local PlayerAddedConnection = Players.PlayerAdded:Connect(function(Player)

		self:onPlayerAdded(Player)

	end)

	local PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(Player)

		self:onPlayerRemoving(Player)

	end)

	local SendPredictedValueRemoteEventConnection = SendPredictedValueRemoteEvent.OnServerEvent:Connect(function(WatchingPlayer, watchedPlayerStringUserId, predictedValue)
		
		if not WatchingPlayer then return end

		self:onPredictedValueReceived(WatchingPlayer, watchedPlayerStringUserId, predictedValue)

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

	return {PlayerAddedConnection, PlayerRemovingConnection, SendPredictedValueRemoteEventConnection, SetPlayerToWatchRemoteEventConnection, ActivateClientAnomalyDetectorRemoteEventConnection, OnMissingDataRemoteEventConnection}

end

local function fetchSettings(useOnlineModel: boolean, key: string)

	if useOnlineModel then

		return ModelCreatorDataStore:GetAsync(key)

	else

		return require(script.Parent.OfflineModelSettings)[key]

	end

end

function AnomalyDetector.new(maxPlayersToWatchPerPlayer: number, normalThreshold: number, maxPredictedValuesDifferenceAverage: number, useOnlineModel: boolean, key: string)

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
	
	maxPredictedValuesDifferenceAverage = maxPredictedValuesDifferenceAverage or Settings["maxPredictedValuesDifferenceAverage"] or 5

	if (typeof(maxPredictedValuesDifferenceAverage) ~= "number") then error("Maximum predicted values difference average is not a number value!") end
	
	NewAnomalyDetector.Settings = Settings
	
	NewAnomalyDetector.NormalThreshold = normalThreshold

	NewAnomalyDetector.MaxPredictedValuesDifferenceAverage = maxPredictedValuesDifferenceAverage
	
	NewAnomalyDetector.MaxPlayersToWatchPerPlayer = maxPlayersToWatchPerPlayer
	
	NewAnomalyDetector.PlayerWatchListStringUserIds = {}

	NewAnomalyDetector.ConnectionsArray = {}
	
	NewAnomalyDetector.ReceivedPredictedValues = {}

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
