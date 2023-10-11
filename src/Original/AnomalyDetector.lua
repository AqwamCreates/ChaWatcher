local ModelCreatorDataStore = game:GetService("DataStoreService"):GetDataStore("AqwamChaWatcherModelCreatorDataStore")

AnomalyDetector = {}

AnomalyDetector.__index = AnomalyDetector

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
	
	local DataCollector = require(script.Parent.DataCollector).new(false)
	
	DataCollector:bindToHeartbeat(function(Player, fullDataVector)
		
		local predictedValue = self.SupportVectorMachine:predict({fullDataVector}, true)[1][1]

		local isOutlier = (predictedValue < self.NormalThreshold)
		
		if self.HeartbeatFunction then self.HeartbeatFunction(Player, predictedValue, fullDataVector) end
		
		if isOutlier and self.OutlierFoundFunction then self.OutlierFoundFunction(Player, predictedValue, fullDataVector) end

	end)

	DataCollector:bindToMissingData(function(Player)

		if self.MissingDataFunction then self.MissingDataFunction(Player) end 

	end)
	
	return DataCollector
	
end

function AnomalyDetector:createSupportVectorMachine(ModelParameters, kernelFunction, kernelParameters)
	
	local SVM =  require(script.Parent.Parent.Parent.AqwamProprietarySourceCodes.SupportVectorMachine).new(nil, nil, nil, kernelFunction, kernelParameters)
	
	SVM:setModelParameters(ModelParameters)
	
	return SVM
	
end

local function fetchSettings(useOnlineModel: boolean, key: string)
	
	if useOnlineModel then

		return ModelCreatorDataStore:GetAsync(key)

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
	
	if not ModelParameters then error("No model parameters found!") end
	
	if not kernelFunction then warn("No kernel function found! Using default function!") end
	
	if not kernelParameters then warn("No Kkernel parameters Found! Using default values!") end
	
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

function AnomalyDetector:destroy()
	
	self.DataCollector:destroy()
	
	self.SupportVectorMachine:destroy()

	table.clear(self)

	AnomalyDetector = nil
	
end

return AnomalyDetector
