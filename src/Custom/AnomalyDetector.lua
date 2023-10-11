local AnomalyDetectorDataStore = game:GetService("DataStoreService"):GetDataStore("AqwamChaWatcherAnomalyDetectorDataStore")

AnomalyDetector = {}

AnomalyDetector.__index = AnomalyDetector

local ChaWatcher = script.Parent.Parent.Parent

function AnomalyDetector:setPlayerHasMissingData(Player: player, hasMissingData: boolean)

	self.DataCollector:setPlayerHasMissingData(Player, hasMissingData)

end

function AnomalyDetector:getPlayerDataVectors(Player)

	return self.DataCollector:getPlayerDataVectors(Player)

end

function AnomalyDetector:bindToOutlierFound(functionToRun)
	
	self.OutlierFoundFunction = functionToRun
	
end

function AnomalyDetector:bindToHeartbeat(functionToRun)

	self.HeartbeatFunction = functionToRun

end

function AnomalyDetector:bindToMissingData(functionToRun)
	
	self.MissingDataFunction = functionToRun

end

function AnomalyDetector:createDataCollector()
	
	local DataCollector = require(ChaWatcher.SourceCodes.DataCollector).new(false)
	
	DataCollector:bindToHeartbeat(function(Player, fullDataVector)
		
		local predictedValue = self.SupportVectorMachine:predict({fullDataVector}, true)[1][1]

		local isOutlier = (predictedValue <= self.NormalThreshold)
		
		if self.HeartbeatFunction then self.HeartbeatFunction(Player, predictedValue, fullDataVector) end
		
		if isOutlier and self.OutlierFoundFunction then self.OutlierFoundFunction(Player, predictedValue, fullDataVector) end

	end)

	DataCollector:bindToMissingData(function(Player)

		if self.MissingDataFunction then self.MissingDataFunction(Player) end 

	end)
	
	return DataCollector
	
end

function AnomalyDetector:createSupportVectorMachine(ModelParameters, kernelFunction, kernelParameters)
	
	local SVM =  require(ChaWatcher.AqwamProprietarySourceCodes.SupportVectorMachine).new(nil, nil, nil, kernelFunction, kernelParameters)
	
	SVM:setModelParameters(ModelParameters)
	
	return SVM
	
end

local function fetchSettings(useOnlineModel: boolean, key: string)
	
	if useOnlineModel then

		return AnomalyDetectorDataStore:GetAsync(key)

	else

		return require(script.Parent.OfflineModelSettings)[key]

	end
	
end

function AnomalyDetector.new(normalThreshold: number, useOnlineModel: boolean, key: string)
	
	local NewAnomalyDetector = {}
	
	setmetatable(NewAnomalyDetector, AnomalyDetector)
	
	key = key or "default"
	
	if (typeof(key) ~= "string") then error("Key is not a string value!") end
	
	local Settings = fetchSettings(useOnlineModel, key)
	
	if not Settings then error("No Settings Found!") end
	
	normalThreshold = normalThreshold or Settings["normalThreshold"]

	if (typeof(normalThreshold) ~= "number") then error("Normal threshold is not a number value!") end

	NewAnomalyDetector.NormalThreshold = normalThreshold
		
	local ModelParameters = Settings["ModelParameters"]
	
	local kernelFunction = Settings["kernelFunction"]
		
	local kernelParameters = Settings["kernelParameters"]
	
	if not ModelParameters then error("No Model Parameters Found!") end
	
	if not kernelFunction then warn("No Kernel Function Found! Using Default Function!") end
	
	if not kernelParameters then warn("No Kernel Parameters Found! Using Default Values!") end
	
	NewAnomalyDetector.SupportVectorMachine = NewAnomalyDetector:createSupportVectorMachine(ModelParameters, kernelFunction, kernelParameters)
	
	NewAnomalyDetector.DataCollector = NewAnomalyDetector:createDataCollector()
	
	return NewAnomalyDetector
	
end

function AnomalyDetector:start()
	
	self.DataCollector:start()
	
end

function AnomalyDetector:stop()

	self.DataCollector:stop()

end

function AnomalyDetector:updateDataVectors(Player: Player, currentData, isNewData: boolean)

	self.AnomalyDetector:updateDataVectors(Player, currentData, isNewData)

end

function AnomalyDetector:destroy()
	
	self.DataCollector:destroy()
	
	self.SupportVectorMachine:destroy()

	table.clear(self)

	AnomalyDetector = nil
	
end

return AnomalyDetector
