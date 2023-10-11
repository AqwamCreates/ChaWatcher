local RunService = game:GetService("RunService")

local Players = game:GetService("Players")

local DataCollectorDataStore = game:GetService("DataStoreService"):GetDataStore("AqwamChaWatcherDataCollectorDataStore")

DataCollector = {}

DataCollector.__index = DataCollector

function DataCollector:setPlayerPreviousDataVector(Player: Player, previousDataVector)
	
	local UserId = Player.UserId

	local stringUserId = tostring(UserId)
	
	self.PlayersPreviousData[stringUserId] = previousDataVector
	
end

function DataCollector:setPlayerCurrentDataVector(Player: Player, currentDataVector)

	local UserId = Player.UserId

	local stringUserId = tostring(UserId)

	self.PlayersCurrentData[stringUserId] = currentDataVector

end

function DataCollector:setPlayerHasMissingData(Player: player, hasMissingData: boolean)
	
	local UserId = Player.UserId

	local stringUserId = tostring(UserId)
	
	self.PlayerHasMissingData[stringUserId] = hasMissingData
	
end

function DataCollector:updateFullDataVector(Player)

	local UserId = Player.UserId

	local stringUserId = tostring(UserId)

	local previousDataVector = self.PlayersPreviousData[stringUserId] 

	local currentDataVector = self.PlayersCurrentData[stringUserId] 
	
	local fullDataVector = {}

	return fullDataVector

end

function DataCollector:updateDataVectors(Player: Player, currentData, isNewData: boolean)

	local UserId = Player.UserId

	local stringUserId = tostring(UserId)

	local previousData = self.PlayersPreviousData[stringUserId]

	if (isNewData == true) then

		previousData = nil

	else

		previousData = self.PlayersCurrentData[stringUserId]

	end

	self.PlayersPreviousData[stringUserId] = previousData

	self.PlayersCurrentData[stringUserId] = currentData

end

function DataCollector:onPlayerRemoving(Player: Player)

	local UserId = Player.UserId

	local stringUserId = tostring(UserId)
	
	self.PlayersCurrentData[stringUserId] = nil

	self.PlayersPreviousData[stringUserId] = nil
	
	self.IsPlayerRecentlyJoined[stringUserId] = nil
	
	self.PlayerHasMissingData[stringUserId] = nil

end

function DataCollector:onHeartbeatForPlayer(Player, deltaTime)
	
	local stringUserId = tostring(Player.UserId)
	
	if self.PlayerHasMissingData[stringUserId] then 

		if self.OnMissingDataFunction then self.OnMissingDataFunction(Player) end
		return

	end

	if not self.PlayersPreviousData[stringUserId] then return end

	local dataVector = self:updateFullDataVector(Player)

	if self.StoreFullData then table.insert(self.FullData, dataVector) end

	if self.OnHeartbeatFunction then self.OnHeartbeatFunction(Player, dataVector) end
	
end

function DataCollector:onHeartbeat(deltaTime)
	
	for _, Player in Players:GetPlayers() do

		if (Player == nil) then continue end
		
		if self.IsPlayerRecentlyJoined[tostring(Player.UserId)] then continue end

		task.spawn(function()

			self:onHeartbeatForPlayer(Player, deltaTime)

		end)

	end

end

function DataCollector:createConnectionsArray()

	local PlayerAddedConnection = Players.PlayerAdded:Connect(function(Player)
		
		local stringUserId = tostring(Player.UserId)
		
		self.IsPlayerRecentlyJoined[stringUserId] = true

		Player.CharacterAdded:Connect(function()
			
			self.IsPlayerRecentlyJoined[stringUserId] = false

		end)

	end)

	local PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(Player)

		self:onPlayerRemoving(Player)

	end)

	local RunServiceConnection = RunService.Heartbeat:Connect(function(deltaTime)

		self:onHeartbeat(deltaTime)

	end)

	return {PlayerAddedConnection, PlayerRemovingConnection, RunServiceConnection}

end

function DataCollector:getPlayerDataVectors(Player: Player)
	
	if not Player:IsA("Player") then error("Not a player object!") end

	local UserId = Player.UserId

	local stringUserId = tostring(UserId)

	local previousDataVector = self.PlayersPreviousData[stringUserId] 

	local currentDataVector = self.PlayersCurrentData[stringUserId] 

	return currentDataVector, previousDataVector

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

function DataCollector:bindToHeartbeat(functionToRun)

	self.OnHeartbeatFunction = functionToRun

end

function DataCollector:bindToMissingData(functionToRun)

	self.OnMissingDataFunction = functionToRun

end

function DataCollector.new(storeFullData: boolean, dataStoreKey: string)

	local NewDataCollector = {}

	setmetatable(NewDataCollector, DataCollector)

	dataStoreKey = dataStoreKey or "default"

	if (typeof(dataStoreKey) ~= "string") then error("Key is not a string value!") end

	NewDataCollector.ConnectionsArray = {}

	NewDataCollector.PlayersCurrentData = {}

	NewDataCollector.PlayersPreviousData = {}

	NewDataCollector.FullData = {}
	
	NewDataCollector.IsPlayerRecentlyJoined = {}
	
	NewDataCollector.PlayerHasMissingData = {}

	NewDataCollector.StoreFullData = storeFullData

	NewDataCollector.DataStoreKey = dataStoreKey

	return NewDataCollector

end

function DataCollector:start()

	self.ConnectionsArray = self:createConnectionsArray()

end

function DataCollector:stop() 

	for _, Connection in ipairs(self.ConnectionsArray) do Connection:Disconnect() end

end

function DataCollector:clearFullData()
	
	self.FullData = {}
	
end

function DataCollector:destroy()

	for _, Connection in ipairs(self.ConnectionsArray) do Connection:Disconnect() end

	table.clear(self)

	DataCollector = nil

end

return DataCollector
