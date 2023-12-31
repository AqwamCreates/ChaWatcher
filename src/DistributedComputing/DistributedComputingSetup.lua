local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts

local clientName = "ChaWatcherDistributedComputingClient"

local module = {}

function module:getClientName()
	
	return clientName
	
end

function module:setup()
	
	local ChaWatcherDistributedComputing = ReplicatedStorage:FindFirstChild("ChaWatcherDistributedComputing") or Instance.new("Folder")
	
	local ActivateClientAnomalyDetectorRemoteEvent =  ChaWatcherDistributedComputing:FindFirstChild("ActivateClientAnomalyDetectorRemoteEvent") or Instance.new("RemoteEvent")
	
	local ActivateClientDataCollectorRemoteEvent = ChaWatcherDistributedComputing:FindFirstChild("ActivateClientDataCollectorRemoteEvent") or Instance.new("RemoteEvent")

	local SendPredictedValueRemoteEvent = ChaWatcherDistributedComputing:FindFirstChild("SendPredictedValueRemoteEvent") or Instance.new("RemoteEvent")
	
	local SendFullDataVectorRemoteEvent = ChaWatcherDistributedComputing:FindFirstChild("SendFullDataVectorRemoteEvent") or Instance.new("RemoteEvent")

	local SetPlayerToWatchRemoteEvent = ChaWatcherDistributedComputing:FindFirstChild("SetPlayerToWatchRemoteEvent") or Instance.new("RemoteEvent")
	
	local OnMissingDataRemoteEvent = ChaWatcherDistributedComputing:FindFirstChild("OnMissingDataRemoteEvent") or Instance.new("RemoteEvent")
	
	---------------------------------------------------------------
	
	ChaWatcherDistributedComputing.Name = "ChaWatcherDistributedComputing"
	
	ActivateClientAnomalyDetectorRemoteEvent.Name = "ActivateClientAnomalyDetectorRemoteEvent"
	
	ActivateClientDataCollectorRemoteEvent.Name = "ActivateClientDataCollectorRemoteEvent"

	SendPredictedValueRemoteEvent.Name = "SendPredictedValueRemoteEvent"
	
	SendFullDataVectorRemoteEvent.Name = "SendFullDataVectorRemoteEvent"

	SetPlayerToWatchRemoteEvent.Name = "SetPlayerToWatchRemoteEvent"
	
	OnMissingDataRemoteEvent.Name = "OnMissingDataRemoteEvent"
	
	---------------------------------------------------------------
	
	ChaWatcherDistributedComputing.Parent = ReplicatedStorage

	ActivateClientAnomalyDetectorRemoteEvent.Parent = ChaWatcherDistributedComputing
	
	ActivateClientDataCollectorRemoteEvent.Parent = ChaWatcherDistributedComputing

	SendPredictedValueRemoteEvent.Parent = ChaWatcherDistributedComputing
	
	SendFullDataVectorRemoteEvent.Parent = ChaWatcherDistributedComputing

	SetPlayerToWatchRemoteEvent.Parent = ChaWatcherDistributedComputing
	
	OnMissingDataRemoteEvent.Parent = ChaWatcherDistributedComputing
	
	---------------------------------------------------------------
	
	local ChaWatcherDistributedComputingClient = StarterPlayerScripts:FindFirstChild(clientName)
	
	if not ChaWatcherDistributedComputingClient then
		
		ChaWatcherDistributedComputingClient = script.Parent.ChaWatcherDistributedComputingClient:Clone()
		
		ChaWatcherDistributedComputingClient.Name = clientName or ChaWatcherDistributedComputingClient.Name
		
		script.Parent.Parent.Parent.AqwamProprietarySourceCodes:Clone().Parent = ChaWatcherDistributedComputingClient
		
		ChaWatcherDistributedComputingClient.Parent = StarterPlayerScripts
		
		ChaWatcherDistributedComputingClient.Enabled = true
		
	end
	
	---------------------------------------------------------------
	
	local RemoteEvents = {
		
		ActivateClientAnomalyDetectorRemoteEvent = ActivateClientAnomalyDetectorRemoteEvent,
		ActivateClientDataCollectorRemoteEvent = ActivateClientDataCollectorRemoteEvent,
		SendPredictedValueRemoteEvent = SendPredictedValueRemoteEvent,
		SendFullDataVectorRemoteEvent = SendFullDataVectorRemoteEvent,
		SetPlayerToWatchRemoteEvent = SetPlayerToWatchRemoteEvent,
		OnMissingDataRemoteEvent = OnMissingDataRemoteEvent,
		
	}
	
	---------------------------------------------------------------
	
	return RemoteEvents, ChaWatcherDistributedComputingClient
	
end

return module
