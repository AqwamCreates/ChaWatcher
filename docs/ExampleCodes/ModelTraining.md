# Model Training (Original Version)

```lua

local ServerScriptService = game:GetService("ServerScriptService")

local MatrixL = require(ServerScriptService.MatrixL)

local ChaWatcher = require(ServerScriptService:WaitForChild("ChaWatcher"))

local ModelCreator = ChaWatcher.Original.ModelCreator.new() -- Setting to default.

local kernelParameters = {
	
	sigma = 0.15,
	gamma = 100,
	r = -1,
	
}

ModelCreator:setParameters(200, 10^-3.5, nil, "Sigmoid", kernelParameters) -- Sets the model settings. You can view the options here: https://aqwamcreates.github.io/DataPredict/API/Models/SupportVectorMachine.html

local Model = ModelCreator:train(500) -- Sets the number of data to be trained to avoid reaching exhaustion time. The data are chosen randomly.

local ModelParameters = Model.ModelParameters

MatrixL:printMatrixWithComma(ModelParameters)

ModelCreator:saveModelOnline()

ModelCreator:loadModelOnline()
```
