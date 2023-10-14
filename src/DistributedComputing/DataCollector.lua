local Players = game:GetService("Players")

local RunService = game:GetService("RunService")

local StarterPlayer = game:GetService("StarterPlayer")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataCollectorDataStore = game:GetService("DataStoreService"):GetDataStore("AqwamChaWatcherDataCollectorDataStore")

local SendPlayerFullDataRemoteEvent: RemoteEvent

local ActivateClientDataCollectorRemoteEvent: RemoteEvent

DataCollector = {}

DataCollector.__index = DataCollector

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

function DataCollector:startUp()

	local ChaWatcherDistributedComputing = ReplicatedStorage:FindFirstChild("ChaWatcherDistributedComputing") or Instance.new("Folder")
	
	ActivateClientDataCollectorRemoteEvent = ChaWatcherDistributedComputing:FindFirstChild("ActivateClientDataCollectorRemoteEvent") or Instance.new("RemoteEvent")

	SendPlayerFullDataRemoteEvent = ChaWatcherDistributedComputing:FindFirstChild("SendPlayerFullDataRemoteEvent") or Instance.new("RemoteEvent")
	
	ActivateClientDataCollectorRemoteEvent.Name = ActivateClientDataCollectorRemoteEvent

	ChaWatcherDistributedComputing.Name = "ChaWatcherDistributedComputing"

	SendPlayerFullDataRemoteEvent.Name = "SendPlayerFullDataRemoteEvent"
	
	ActivateClientDataCollectorRemoteEvent.Parent = ChaWatcherDistributedComputing

	SendPlayerFullDataRemoteEvent.Parent = ChaWatcherDistributedComputing
	
	ChaWatcherDistributedComputing.Parent = ReplicatedStorage

	local ChaWatcherClientAnomalyDetector = script.ChaWatcherClientAnomalyDetector

	script.Parent.Parent.Parent.AqwamProprietarySourceCodes:Clone().Parent = ChaWatcherClientAnomalyDetector

	ChaWatcherClientAnomalyDetector.Parent = StarterPlayer
	
	SendPlayerFullDataRemoteEvent.OnServerEvent:Connect(function(Player, fullDataVector)
		
		self:addFullDataVector(fullDataVector)
		
	end)

end

function DataCollector.new(dataStoreKey: string)

	local NewDataCollector = {}

	setmetatable(NewDataCollector, DataCollector)

	dataStoreKey = dataStoreKey or "default"

	if (typeof(dataStoreKey) ~= "string") then error("Key is not a string value!") end

	NewDataCollector.FullData = {}
	
	NewDataCollector.IsPlayerRecentlyJoined = {}

	NewDataCollector.DataStoreKey = dataStoreKey
	
	NewDataCollector:startUp()

	return NewDataCollector

end

function DataCollector:start()
	
	ActivateClientDataCollectorRemoteEvent:FireAllClients(true)
	
end

function DataCollector:stop()
	
	ActivateClientDataCollectorRemoteEvent:FireAllClients(false)
	
end

function DataCollector:clearFullData()
	
	self.FullData = {}
	
end

function DataCollector:destroy()
	
	self:stop()
	
	SendPlayerFullDataRemoteEvent:Destroy()
	
	ActivateClientDataCollectorRemoteEvent:Destroy()

	table.clear(self)

	DataCollector = nil
	
end

return DataCollector
