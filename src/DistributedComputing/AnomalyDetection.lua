local Players = game:GetService("Players")

local RunService = game:GetService("RunService")

local StarterPlayer = game:GetService("StarterPlayer")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModelCreatorDataStore = game:GetService("DataStoreService"):GetDataStore("AqwamChaWatcherModelCreatorDataStore")

local SendPredictedValueRemoteEvent: RemoteEvent

local SetPlayerToWatchRemoteEvent: RemoteEvent

local ActivateClientRemoteEvent: RemoteEvent

AnomalyDetector = {}

AnomalyDetector.__index = AnomalyDetector

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
	
	for otherStringUserId, watchedPlayersTable in self.PlayerWatching do
		
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

	self.PlayerWatching[stringUserId] = nil

	for watchedByPlayerStringUserId, _ in self.ReceivedPredictedValues[stringUserId] do

		local playerWatchingArray = self.PlayerWatching[watchedByPlayerStringUserId] 

		local index = table.find(playerWatchingArray, UserId)

		if index then table.remove(playerWatchingArray, index) end
		
		local PlayerToSet = Players:GetPlayerByUserId(tonumber(watchedByPlayerStringUserId))
		
		SetPlayerToWatchRemoteEvent:FireClient(PlayerToSet, self.PlayerWatching[watchedByPlayerStringUserId])

	end

	self.ReceivedPredictedValues[stringUserId] = nil

end

function AnomalyDetector:onPlayerAdded(Player: Player)
	
	ActivateClientRemoteEvent:FireClient(Player, true, self.Settings)
	
	local stringUserId = tostring(Player.UserId)

	local otherStringUserIdArray = self:getStringUserIdsWithEmptyWatchSlots(stringUserId)
	
	local stringUserIdToWatchArray = {}
	
	local numberOfWatchedBy = 0
	
	while (numberOfWatchedBy < self.MaxPlayersToWatchPerPlayer) and (#otherStringUserIdArray >= 0) do
		
		local randomIndex = Random.new():NextInteger(1, #otherStringUserIdArray)
		
		local randomStringUserId = otherStringUserIdArray[randomIndex]
		
		local PlayerToSet = Players:GetPlayerByUserId(tonumber(randomStringUserId))
		
		if not PlayerToSet then continue end
		
		table.insert(self.PlayerWatching[randomStringUserId], stringUserId)
		
		SetPlayerToWatchRemoteEvent:FireClient(PlayerToSet, self.PlayerWatching[randomStringUserId])
		
		table.remove(randomStringUserId, randomIndex)
		
		numberOfWatchedBy += 1
		
	end 
	
	for otherStringUserId, watchedByPlayerStringUserIds in self.ReceivedPredictedValues do
		
		local numberOfPlayersWatchedByForOtherPlayer = 0
		
		for watchedByPlayerStringUserId, otherPredictedValue in watchedByPlayerStringUserIds do numberOfPlayersWatchedByForOtherPlayer += 1 end
		
		if (numberOfPlayersWatchedByForOtherPlayer >= self.MaxPlayersToWatchPerPlayer) then continue end
		
		table.insert(stringUserIdToWatchArray, otherStringUserId)
		
	end
	
	self.PlayerWatching[stringUserId] = stringUserIdToWatchArray
	
	SetPlayerToWatchRemoteEvent:FireClient(Player, stringUserIdToWatchArray)
	
end

function AnomalyDetector:onPredictedValueReceived(WatchingPlayer: Player, WatchedPlayer: Player, predictedValue)
	
	if ((typeof(WatchedPlayer) ~= "Player") or (typeof(predictedValue) ~= "number")) and self.OnClientAccessedFunction then self.OnClientAccessedFunction(WatchingPlayer) return end

	local targetPlayerStringUserId = tostring(WatchedPlayer.UserId)

	self.ReceivedPredictedValues[targetPlayerStringUserId][tostring(WatchingPlayer.UserId)] = predictedValue

	local averageDifference = 0
	
	local watchedByPlayerArray = {}

	for watchedByPlayerStringUserId, otherPredictedValue in self.ReceivedPredictedValues[targetPlayerStringUserId] do

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
		
		for watchedByPlayerStringUserId, otherPredictedValue in self.ReceivedPredictedValues[targetPlayerStringUserId] do
			
			local PlayerToSet = Players:GetPlayerByUserId(tonumber(watchedByPlayerStringUserId))
				
			if not PlayerToSet then continue end
				
			table.insert(playersArray, PlayerToSet)
			table.insert(predictedValuesArray, otherPredictedValue)
			
		end
		
		self.AbnormalPredictedValuesFunction(WatchedPlayer, playersArray, predictedValuesArray)
		
		return 
			
	end

	if (predictedValue < self.NormalThreshold) and self.OutlierFoundFunction then self.OutlierFoundFunction(WatchedPlayer, predictedValue) end
	
end

function AnomalyDetector:createConnectionsArray()

	local PlayerAddedConnection = Players.PlayerAdded:Connect(function(Player)

		self:onPlayerAdded(Player)

	end)

	local PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(Player)

		self:onPlayerRemoving(Player)

	end)

	local SendPredictedValueRemoteEventConnection = SendPredictedValueRemoteEvent.OnServerEvent:Connect(function(WatchingPlayer, WatcherPlayer, predictedValue)

		self:onPredictedValueReceived(WatchingPlayer, WatcherPlayer, predictedValue)

	end)

	local SetPlayerToWatchRemoteEventConnection = SetPlayerToWatchRemoteEvent.OnServerEvent:Connect(function(Player)

		if self.OnClientAccessedFunction then self.OnClientAccessedFunction(Player) end

	end)

	local ActivateClientRemoteEvent = SendPredictedValueRemoteEvent.OnServerEvent:Connect(function(Player)

		if self.OnClientAccessedFunction then self.OnClientAccessedFunction(Player) end

	end)

	return {PlayerAddedConnection, PlayerRemovingConnection, SendPredictedValueRemoteEventConnection, SetPlayerToWatchRemoteEventConnection, ActivateClientRemoteEvent}

end

local function startUp()

	local ChaWatcherDistributedComputing = ReplicatedStorage:FindFirstChild("ChaWatcherDistributedComputing") or Instance.new("Folder")

	SendPredictedValueRemoteEvent = ChaWatcherDistributedComputing:FindFirstChild("SendPredictedValueRemoteEvent") or Instance.new("RemoteEvent")

	SetPlayerToWatchRemoteEvent = ChaWatcherDistributedComputing:FindFirstChild("SetPlayerToWatchRemoteEvent") or Instance.new("RemoteEvent")

	ActivateClientRemoteEvent =  ChaWatcherDistributedComputing:FindFirstChild("ActivateClientRemoteEvent") or Instance.new("RemoteEvent")
	
	ChaWatcherDistributedComputing.Name = "ChaWatcherDistributedComputing"

	SendPredictedValueRemoteEvent.Name = "SendPredictedValueRemoteEvent"

	SetPlayerToWatchRemoteEvent.Name = "SetPlayerToWatchRemoteEvent"

	ActivateClientRemoteEvent.Name = "ActivateClientRemoteEvent"

	SendPredictedValueRemoteEvent.Parent = ChaWatcherDistributedComputing

	SetPlayerToWatchRemoteEvent.Parent	 = ChaWatcherDistributedComputing

	ActivateClientRemoteEvent.Parent = ChaWatcherDistributedComputing

	local ChaWatcherClientAnomalyDetector = script.ChaWatcherClientAnomalyDetector

	script.Parent.Parent.Parent.AqwamProprietarySourceCodes:Clone().Parent = ChaWatcherClientAnomalyDetector

	ChaWatcherClientAnomalyDetector.Parent = StarterPlayer

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

	normalThreshold = normalThreshold or Settings["normalThreshold"]

	if (typeof(normalThreshold) ~= "number") then error("Normal threshold is not a number value!") end
	
	maxPredictedValuesDifferenceAverage = maxPredictedValuesDifferenceAverage or Settings["maxPredictedValuesDifferenceAverage"]

	if (typeof(maxPredictedValuesDifferenceAverage) ~= "number") then error("Maximum predicted values difference average is not a number value!") end
	
	maxPlayersToWatchPerPlayer = maxPlayersToWatchPerPlayer or 2
	
	if (typeof(maxPlayersToWatchPerPlayer) ~= "number") then error("Maximum players to watch is not a number value!") end
	
	NewAnomalyDetector.Settings = Settings
	
	NewAnomalyDetector.NormalThreshold = normalThreshold

	NewAnomalyDetector.MaxPredictedValuesDifferenceAverage = maxPredictedValuesDifferenceAverage
	
	NewAnomalyDetector.MaxPlayersToWatchPerPlayer = maxPlayersToWatchPerPlayer
	
	NewAnomalyDetector.PlayerWatching = {}

	NewAnomalyDetector.ConnectionsArray = {}
	
	NewAnomalyDetector.ReceivedPredictedValues = {}

	startUp()

	return NewAnomalyDetector

end

function AnomalyDetector:start()

	self.ConnectionsArray = self:createConnectionsArray()

	ActivateClientRemoteEvent:FireAllClients(true, self.Settings)

end

function AnomalyDetector:stop()

	ActivateClientRemoteEvent:FireAllClients(false)

	for _, Connection in ipairs(self.ConnectionsArray) do Connection:Disconnect() end

end

function AnomalyDetector:destroy()

	self:stop()

	table.clear(self)

	AnomalyDetector = nil

end

return AnomalyDetector
