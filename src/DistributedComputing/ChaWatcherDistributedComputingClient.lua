local RunService = game:GetService("RunService")

local StarterPlayer = game:GetService("StarterPlayer")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChaWatcherDistributedComputing = ReplicatedStorage:WaitForChild("ChaWatcherDistributedComputing")

local ActivateClientAnomalyDetectorRemoteEvent =  ChaWatcherDistributedComputing.ActivateClientAnomalyDetectorRemoteEvent

local ActivateClientDataCollectorRemoteEvent = ChaWatcherDistributedComputing.ActivateClientDataCollectorRemoteEvent

local SendPredictedValueRemoteEvent = ChaWatcherDistributedComputing.SendPredictedValueRemoteEvent

local SendFullDataVectorRemoteEvent = ChaWatcherDistributedComputing.SendFullDataVectorRemoteEvent

local SetPlayerToWatchRemoteEvent = ChaWatcherDistributedComputing.SetPlayerToWatchRemoteEvent

local SupportVectorMachine = require(script.AqwamProprietarySourceCodes.SupportVectorMachine).new()

local PlayersPreviousData = {}

local PlayersCurrentData = {}

local PlayerToTrack = {}

local function updateFullDataVector(Player)

	local UserId = Player.UserId

	local stringUserId = tostring(UserId)

	local previousDataVector = PlayersPreviousData[stringUserId] 

	local currentDataVector = PlayersCurrentData[stringUserId] 

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

local function updateDataVectors(Player: Player, deltaTime: number, isNewData: boolean)

	local UserId = Player.UserId

	local stringUserId = tostring(UserId)

	local previousData = PlayersPreviousData[stringUserId]

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

	if (isNewData == true) then

		previousData = nil

	else

		previousData = PlayersCurrentData[stringUserId]

	end

	local currentData = {Position, Orientation, Velocity, accumulatedFlyingTime}

	PlayersPreviousData[stringUserId] = previousData

	PlayersCurrentData[stringUserId] = currentData

end

local function onActivateClientAnomalyDetectorRemoteEventConnection(isActivated, ReceivedModel)
	
	SupportVectorMachine:setParameters(nil, nil, nil, ReceivedModel.kernelFunction, ReceivedModel.kernelParameters)
	
end

ActivateClientAnomalyDetectorRemoteEvent.OnClientEvent:Connect(onActivateClientAnomalyDetectorRemoteEventConnection)
