local RunService = game:GetService("RunService")

local Players = game:GetService("Players")

local DataCollectorDataStore = game:GetService("DataStoreService"):GetDataStore("AqwamChaWatcherDataCollectorDataStore")

DataCollector = {}

DataCollector.__index = DataCollector

function DataCollector:updateFullDataVector(Player)

	local UserId = Player.UserId

	local stringUserId = tostring(UserId)

	local previousDataVector = self.PlayersPreviousData[stringUserId] 

	local currentDataVector = self.PlayersCurrentData[stringUserId] 

	local changeInPosition = currentDataVector[1] - previousDataVector[1]

	local changeInOrientation = currentDataVector[2] - previousDataVector[2]

	local currentVelocity = currentDataVector[3] 

	local previousVelocity = previousDataVector[3]

	local changeInVelocity = currentVelocity - previousVelocity

	local timeSpentFlying = currentDataVector[4]

	local distance = changeInPosition.Magnitude

	local fullDataVector = {

		changeInPosition.X, changeInPosition.Y, changeInPosition.Z,

		math.rad(changeInOrientation.X), math.rad(changeInOrientation.Y), math.rad(changeInOrientation.Z),

		changeInVelocity.X, changeInVelocity.Y, changeInVelocity.Z,

		currentVelocity.X, currentVelocity.Y, currentVelocity.Z,

		timeSpentFlying, distance

	}

	return fullDataVector

end

local function checkIfIsFlying(Character: Model)

	local CharacterPosition = Character:GetPivot().Position

	local DirectionVector = Vector3.new(0, -3.1, 0)

	local raycastParameters = RaycastParams.new()

	raycastParameters.FilterDescendantsInstances = Character:GetChildren()

	raycastParameters.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(CharacterPosition, DirectionVector, raycastParameters)

	if not result then 

		return true

	else

		return false

	end

end

function DataCollector:updateDataVectors(Player: Player, deltaTime: number, isNewData: boolean)

	local UserId = Player.UserId

	local stringUserId = tostring(UserId)

	local previousData = self.PlayersPreviousData[stringUserId]

	local Character = Player.Character

	if (Character == nil) then return nil end

	local CharacterPrimaryPart = Character.PrimaryPart
	
	local CHaracterCFrame = Character:GetPivot() -- Since hackers can fake a HumanoidRootPart and control its properties, we'll be relying on both combination of primary part and model position for best results.

	local Position = CHaracterCFrame.Position

	local Orientation = Vector3.new(math.deg(CHaracterCFrame.LookVector.X), math.deg(CHaracterCFrame.LookVector.Y), math.deg(CHaracterCFrame.LookVector.Z)) -- in degrees so it is easier to convert to radians later

	local Velocity = CharacterPrimaryPart.Velocity

	local isFlying = checkIfIsFlying(Character)

	local accumulatedFlyingTime

	if previousData then

		accumulatedFlyingTime = previousData[4]

	else

		accumulatedFlyingTime = 0

	end

	if isFlying then

		accumulatedFlyingTime += deltaTime

	else

		accumulatedFlyingTime = 0

	end

	if (isNewData == true) then

		previousData = nil

	else

		previousData = self.PlayersCurrentData[stringUserId]

	end

	local currentData = {Position, Orientation, Velocity, accumulatedFlyingTime}

	self.PlayersPreviousData[stringUserId] = previousData

	self.PlayersCurrentData[stringUserId] = currentData

end

function DataCollector:onPlayerRemoving(Player: Player)

	local UserId = Player.UserId

	local stringUserId = tostring(UserId)
	
	self.PlayersCurrentData[stringUserId] = nil

	self.PlayersPreviousData[stringUserId] = nil
	
	self.IsPlayerRecentlyJoined[stringUserId] = nil

end

function DataCollector:onHeartbeatForPlayer(Player, deltaTime)
	
	local isHumanoidDead = false

	local success = pcall(function()

		local Character = Player.Character

		local test = Character.PrimaryPart

		isHumanoidDead = (Character.Humanoid:GetState() == Enum.HumanoidStateType.Dead)

	end)

	local isMissingData = not success

	local isNewData = isHumanoidDead or isMissingData
	
	if isMissingData then 

		if self.OnMissingDataFunction then self.OnMissingDataFunction(Player) end
		return

	end

	self:updateDataVectors(Player, deltaTime, isNewData)

	if not self.PlayersPreviousData[tostring(Player.UserId)] then return end

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
		
		self:updateDataVectors(Player, 0, true)

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
