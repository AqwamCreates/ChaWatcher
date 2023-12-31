local Players = game:GetService("Players")

local RunService = game:GetService("RunService")

local DataCollectorDataStore = game:GetService("DataStoreService"):GetDataStore("AqwamChaWatcherDataCollectorDataStore")

local DistributedComputingSetup = require(script.Parent.DistributedComputingSetup)

local clientName = DistributedComputingSetup:getClientName()

local RemoteEvents = DistributedComputingSetup:setup()

local ActivateClientDataCollectorRemoteEvent = RemoteEvents.ActivateClientDataCollectorRemoteEvent

local SendFullDataVectorRemoteEvent = RemoteEvents.SendFullDataVectorRemoteEvent

local OnMissingDataRemoteEvent = RemoteEvents.OnMissingDataRemoteEvent

DataCollector = {}

DataCollector.__index = DataCollector

function DataCollector:bindToMissingData(functionToRun)
	
	self.OnMissingDataFunction = functionToRun
	
end

function DataCollector:addFullDataVector(fullDataVector)
	
	table.insert(self.FullData, fullDataVector)
	
end

function DataCollector:getFullData()
	
	if (#self.FullData > 0) then
		
		return self.FullData
		
	else
		
		local fullData = DataCollectorDataStore:GetAsync(self.DataStoreKey)
		
		return fullData
		
	end 

end

function DataCollector:saveFullDataOnline()

	if not self.StoreFullData then warn("Did not save due to not storing full data.") return false end

	local success

	repeat

		success = pcall(function()

			DataCollectorDataStore:SetAsync(self.DataStoreKey, self.FullData)

		end)

		task.wait(0.1)

	until success

	print("Full data has been saved!")

	return true

end

function DataCollector:createConnectionsArray()
	
	local PlayerAddedConnection = Players.PlayerAdded:Connect(function(Player)
		
		ActivateClientDataCollectorRemoteEvent:FireClient(Player, true)
		
	end)
	
	local SendFullDataVectorRemoteEventConnection = SendFullDataVectorRemoteEvent.OnServerEvent:Connect(function(_, fullDataVector)

		self:addFullDataVector(fullDataVector)

	end)
	
	local OnMissingDataRemoteEventConnection = OnMissingDataRemoteEvent.OnServerEvent:Connect(function(WatchingPlayer, watchedPlayerStringUserId, currentDataVector, previousDataVector)
		
		if (typeof(WatchingPlayer) ~= "Player") or (typeof(watchedPlayerStringUserId) ~= "string") then return end
		
		local userId = tonumber(watchedPlayerStringUserId)
		
		if not userId then return end
		
		local WatchedPlayer = Players:GetPlayerByUserId(userId)
		
		if not WatchedPlayer then return end
		
		if self.OnMissingDataFunction then self.OnMissingDataFunction(WatchingPlayer, WatchedPlayer, currentDataVector, previousDataVector) end
		
	end)
	
	return {PlayerAddedConnection, SendFullDataVectorRemoteEventConnection, OnMissingDataRemoteEventConnection}
	
end

function DataCollector.new(dataStoreKey: string)

	local NewDataCollector = {}

	setmetatable(NewDataCollector, DataCollector)

	dataStoreKey = dataStoreKey or "default"

	if (typeof(dataStoreKey) ~= "string") then error("Key is not a string value!") end

	NewDataCollector.FullData = {}
	
	NewDataCollector.IsPlayerRecentlyJoined = {}

	NewDataCollector.DataStoreKey = dataStoreKey
	
	NewDataCollector.ConnectionsArray = {}
	
	return NewDataCollector

end

function DataCollector:start()
	
	self.ConnectionsArray = self:createConnectionsArray()
	
	ActivateClientDataCollectorRemoteEvent:FireAllClients(true)
	
end

function DataCollector:stop()
	
	ActivateClientDataCollectorRemoteEvent:FireAllClients(false)
	
	for _, Connection in ipairs(self.ConnectionsArray) do Connection:Disconnect() end
	
end

function DataCollector:clearFullData()
	
	self.FullData = {}
	
end

function DataCollector:destroy()
	
	self:stop()
	
	SendFullDataVectorRemoteEvent:Destroy()
	
	ActivateClientDataCollectorRemoteEvent:Destroy()

	table.clear(self)

	DataCollector = nil
	
end

return DataCollector
