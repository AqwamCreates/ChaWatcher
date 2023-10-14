local Players = game:GetService("Players")

local RunService = game:GetService("RunService")

local StarterPlayer = game:GetService("StarterPlayer")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChaWatcherDistributedComputing = ReplicatedStorage:WaitForChild("ChaWatcherDistributedComputing")

local ActivateClientAnomalyDetectorRemoteEvent =  ChaWatcherDistributedComputing.ActivateClientAnomalyDetectorRemoteEvent

local ActivateClientDataCollectorRemoteEvent = ChaWatcherDistributedComputing.ActivateClientDataCollectorRemoteEvent

local SendPredictedValueRemoteEvent = ChaWatcherDistributedComputing.SendPredictedValueRemoteEvent

local SendFullDataVectorRemoteEvent = ChaWatcherDistributedComputing.SendFullDataVectorRemoteEvent

local SetPlayerToWatchRemoteEvent = ChaWatcherDistributedComputing.SetPlayerToWatchRemoteEvent

local OnMissingDataRemoteEvent = ChaWatcherDistributedComputing.OnMissingDataRemoteEvent

local SupportVectorMachine = require(script.AqwamProprietarySourceCodes.SupportVectorMachine).new()

local Player = Players.LocalPlayer

local stringUserId = tostring(Player.UserId)

local Character = Player.Character

local playersToWatchStringUserIds = {}

local playersPreviousData = {}

local playersCurrentData = {}

local AnomalyDetectorHeartbeatConnection

local DataCollectorHearbeatConnection

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

local function updateFullDataVector(watchedPlayerStringUserId)

	local previousDataVector = playersPreviousData[watchedPlayerStringUserId] 

	local currentDataVector = playersCurrentData[watchedPlayerStringUserId] 

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

	if not workspace:Raycast(CharacterPosition, DirectionVector, raycastParameters) then 

		return true

	else

		return false

	end

end

local function updateDataVectors(watchedPlayerStringUserId, deltaTime: number, isNewData: boolean)

	local previousData = playersPreviousData[watchedPlayerStringUserId]
	
	local WatchedPlayer = convertStringUserIdToPlayer(stringUserId)

	local Character = WatchedPlayer.Character

	if (Character == nil) then return nil end

	local CharacterPrimaryPart = Character.PrimaryPart

	local Position = CharacterPrimaryPart.Position

	local Orientation = CharacterPrimaryPart.Orientation -- in degrees so it is easier to convert to radians later

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

	if (isNewData) then

		previousData = nil

	else

		previousData = playersCurrentData[watchedPlayerStringUserId]

	end

	local currentData = {Position, Orientation, Velocity, accumulatedFlyingTime}

	playersPreviousData[watchedPlayerStringUserId] = previousData

	playersCurrentData[watchedPlayerStringUserId] = currentData

end

local function updateData(watchedPlayerStringUserId, deltaTime)
	
	local isHumanoidDead = false
	
	local success = pcall(function()

		local WatchedPlayer = convertStringUserIdToPlayer(stringUserId)
		
		local Character = WatchedPlayer.Character

		local test = Character.PrimaryPart

		isHumanoidDead = (Character.Humanoid:GetState() == Enum.HumanoidStateType.Dead)

	end)
	
	local isMissingData = not success

	local isNewData = isHumanoidDead or isMissingData
	
	local previousData = playersPreviousData[watchedPlayerStringUserId]
	
	if isMissingData then 
		
		OnMissingDataRemoteEvent:FireServer(watchedPlayerStringUserId, playersCurrentData[watchedPlayerStringUserId], previousData)
		return nil 
		
	end
	
	updateDataVectors(watchedPlayerStringUserId, deltaTime, isNewData)
	
	if not previousData then return nil end

	local fullDataVector = updateFullDataVector(watchedPlayerStringUserId)
	
	return fullDataVector
	
end

local function sendPredictedValuesToServer(watchedPlayerStringUserId, deltaTime)
	
	local fullDataVector = updateData(watchedPlayerStringUserId, deltaTime)

	if not fullDataVector then return end
	
	local predictedValue = SupportVectorMachine:predict({fullDataVector}, true)[1][1]
	
	SendPredictedValueRemoteEvent:FireServer(watchedPlayerStringUserId, predictedValue)
	
end

local function onAnomalyDetectorHeartbeat(deltaTime)
	
	if (#Players:GetPlayers() == 1) then
		
		sendPredictedValuesToServer(stringUserId, deltaTime)
		
	else
		
		for _, watchedPlayerStringUserId in playersToWatchStringUserIds do sendPredictedValuesToServer(watchedPlayerStringUserId, deltaTime) end
		
	end
	
end

local function onDataCollectorHearbeat(deltaTime)
	
	local fullDataVector = updateData(Player, deltaTime)
	
	if not fullDataVector then return end
		
	SendFullDataVectorRemoteEvent:FireServer(fullDataVector)
	
end

local function onActivateClientAnomalyDetectorRemoteEventConnection(isActivated, ReceivedSettings)
	
	if not isActivated then
		
		if AnomalyDetectorHeartbeatConnection then AnomalyDetectorHeartbeatConnection:Disconnect() end
		
	else
		
		SupportVectorMachine:setParameters(nil, nil, nil, ReceivedSettings.kernelFunction, ReceivedSettings.kernelParameters)
		
		SupportVectorMachine:setModelParameters(ReceivedSettings.ModelParameters)
		
		AnomalyDetectorHeartbeatConnection = RunService.Heartbeat:Connect(onAnomalyDetectorHeartbeat)
		
	end
	
end

local function onActivateClientDataCollectorRemoteEventConnection(isActivated)
	
	if not isActivated then

		if DataCollectorHearbeatConnection then DataCollectorHearbeatConnection:Disconnect() end

	else

		DataCollectorHearbeatConnection = RunService.Heartbeat:Connect(onDataCollectorHearbeat)

	end
	
end

local function onSetPlayerToWatchRemoteEventConnection(receivedPlayersToWatchStringUserIds)
	
	playersToWatchStringUserIds = receivedPlayersToWatchStringUserIds
	
	for watchedPlayerStringUserId, _ in playersCurrentData do
		
		local keyExists = iskeyExistsInTable(playersToWatchStringUserIds, watchedPlayerStringUserId)
		
		if keyExists then continue end
		
		playersPreviousData[watchedPlayerStringUserId] = nil
		playersCurrentData[watchedPlayerStringUserId] = nil
		
	end
	
end

ActivateClientAnomalyDetectorRemoteEvent.OnClientEvent:Connect(onActivateClientAnomalyDetectorRemoteEventConnection)

ActivateClientDataCollectorRemoteEvent.OnClientEvent:Connect(onActivateClientDataCollectorRemoteEventConnection)

SetPlayerToWatchRemoteEvent.OnClientEvent:Connect(onSetPlayerToWatchRemoteEventConnection)
