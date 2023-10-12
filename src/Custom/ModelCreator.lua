local DataStoreService = game:GetService("DataStoreService")

local DataCollectorDataStore = DataStoreService:GetDataStore("AqwamChaWatcherDataCollectorDataStore")

local ModelCreatorDataStore = DataStoreService:GetDataStore("AqwamChaWatcherModelCreatorDataStore")

ModelCreator = {}

ModelCreator.__index = ModelCreator

local function createSupportVectorMachine()
	
	local SupportVectorMachine = require(script.Parent.Parent.Parent.AqwamProprietarySourceCodes.SupportVectorMachine).new()
	
	SupportVectorMachine:setWaitDurations(0.3)
	
	return SupportVectorMachine
	
end

function ModelCreator.new(useOnlineData: boolean, dataCollectorDataStoreKey: string, modelCreatorDataStoreKey: string)

	local NewModelCreator = {}

	setmetatable(NewModelCreator, ModelCreator)

	dataCollectorDataStoreKey = dataCollectorDataStoreKey or "default"

	modelCreatorDataStoreKey = modelCreatorDataStoreKey or "default"

	if (typeof(dataCollectorDataStoreKey) ~= "string") then error("Data collector datastore key is not a string value!") end

	if (typeof(modelCreatorDataStoreKey) ~= "string") then error("Anomaly detector datastore key is not a string value!") end

	NewModelCreator.UseOnlineData = useOnlineData

	NewModelCreator.ModelCreatorDataStoreKey = modelCreatorDataStoreKey

	NewModelCreator.DataCollectorDataStoreKey = dataCollectorDataStoreKey

	NewModelCreator.Model = {}

	NewModelCreator.SupportVectorMachine = createSupportVectorMachine()

	return NewModelCreator

end

function ModelCreator:setParameters(maxNumberOfIterations, cValue, targetCost, kernelFunction, kernelParameters)
	
	self.Model = {}
	
	self.Model.kernelFunction = kernelFunction
	self.Model.kernelParameters = kernelParameters
	
	self.SupportVectorMachine:setParameters(maxNumberOfIterations, cValue, targetCost, kernelFunction, kernelParameters)
	
end

local function fetchData(useOnlineData: boolean, key: string)

	if useOnlineData then

		return DataCollectorDataStore:GetAsync(key)

	else

		return require(script.Parent.OfflineData)[key]

	end

end

function ModelCreator:saveModelOnline()
	
	if not self.ModelCreatorDataStoreKey then return false end

	local success

	repeat

		success = pcall(function()

			ModelCreatorDataStore:SetAsync(self.ModelCreatorDataStoreKey, self.Model)

		end)

		task.wait(0.1)

	until success

	print("Model has been saved!")

	return true
	
end

function ModelCreator:train(numberOfDataToUse: number)
	
	local data = fetchData(self.UseOnlineData, self.DataCollectorDataStoreKey)
	
	if not data then error("No data!") end
	
	if (numberOfDataToUse > #data) then error("Number of data to use exceeds the number of data!") end
	
	while (#data > numberOfDataToUse) do
		
		local randomIndex = Random.new():NextInteger(1, #data)
		
		table.remove(data, randomIndex)
		
	end
	
	task.wait(0.3)
	
	local labels = {}
	
	for i = 1, #data, 1 do
		
		table.insert(labels, {1})
		
	end
	
	task.wait(0.3)
	
	self.SupportVectorMachine:train(data, labels)
	
	self.Model.ModelParameters = self.SupportVectorMachine:getModelParameters()
	
	return self.Model
	
end

function ModelCreator:getModel()

	if self.Model then

		return self.Model

	else

		local Model = ModelCreatorDataStore:GetAsync(self.ModelCreatorDataStoreKey)

		return Model

	end 

end

function ModelCreator:loadModelOnline()

	local success = false

	repeat

		success = pcall(function()

			self.Model = ModelCreatorDataStore:GetAsync(self.ModelCreatorDataStoreKey)

		end)

		task.wait(0.1)

	until success

	if self.Model == nil then warn("No model found!") return end

	self.SupportVectorMachine:setModelParameters(self.Model.ModelParameters)

	self.SupportVectorMachine:setParameters(nil, nil, nil, self.Model.kernelFunction, self.Model.kernelParameters)

	print("Loaded model!")

end

return ModelCreator
