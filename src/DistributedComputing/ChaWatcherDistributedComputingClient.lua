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

local Character = Player.Character

local playersPreviousData = {}

local playersCurrentData = {}

local playersToWatch = {}

local AnomalyDetectorHeartbeatConnection

local DataCollectorHearbeatConnection

local function updateFullDataVector(Player)

	local UserId = Player.UserId

	local stringUserId = tostring(UserId)

	local previousDataVector = playersPreviousData[stringUserId] 

	local currentDataVector = playersCurrentData[stringUserId] 

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

local function updateDataVectors(Player: Player, deltaTime: number, isNewData: boolean)

	local UserId = Player.UserId

	local stringUserId = tostring(UserId)

	local previousData = playersPreviousData[stringUserId]

	local Character = Player.Character

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

		previousData = playersCurrentData[stringUserId]

	end

	local currentData = {Position, Orientation, Velocity, accumulatedFlyingTime}

	playersPreviousData[stringUserId] = previousData

	playersCurrentData[stringUserId] = currentData

end

local function updateData(PlayerToUpdate, deltaTime)
	
	local isHumanoidDead = false
	
	local success = pcall(function()

		local Character = Player.Character

		local test = Character.PrimaryPart

		isHumanoidDead = (Character.Humanoid:GetState() == Enum.HumanoidStateType.Dead)

	end)
	
	local isMissingData = not success

	local isNewData = isHumanoidDead or isMissingData
	
	local previousData = playersPreviousData[tostring(PlayerToUpdate.UserId)]
	
	if isMissingData then 
		
		OnMissingDataRemoteEvent:FireServer(PlayerToUpdate, playersCurrentData[tostring(PlayerToUpdate.UserId)], previousData)
		return nil 
		
	end
	
	updateDataVectors(PlayerToUpdate, deltaTime, isNewData)
	
	if not previousData then return nil end

	local fullDataVector = updateFullDataVector(PlayerToUpdate)
	
	return fullDataVector
	
end

local function sendPredictedValuesToServer(WatchedPlayer, deltaTime)
	
	local fullDataVector = updateData(Player, deltaTime)

	if not fullDataVector then return end

	local predictedValue = SupportVectorMachine:predict(fullDataVector)

	SendPredictedValueRemoteEvent:FireServer(WatchedPlayer, predictedValue)
	
end

local function onAnomalyDetectorHeartbeat(deltaTime)
	
	if (#Players:GetPlayers() == 1) then
		
		sendPredictedValuesToServer(Player, deltaTime)
		
	else
		
		for _, WatchedPlayer in playersToWatch do sendPredictedValuesToServer(WatchedPlayer, deltaTime) end
		
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

local function onSetPlayerToWatchRemoteEventConnection(receivedPlayersToWatch)
	
	playersToWatch = receivedPlayersToWatch
	
end

ActivateClientAnomalyDetectorRemoteEvent.OnClientEvent:Connect(onActivateClientAnomalyDetectorRemoteEventConnection)

ActivateClientDataCollectorRemoteEvent.OnClientEvent:Connect(onActivateClientDataCollectorRemoteEventConnection)

SetPlayerToWatchRemoteEvent.OnClientEvent:Connect(onSetPlayerToWatchRemoteEventConnection)
