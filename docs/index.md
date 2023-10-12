# Welcome To ChaWatcher's Documentation!

![ChaWatcherIcon](https://github.com/AqwamCreates/ChaWatcher/assets/67371914/876e056c-920a-416d-82b1-00ccb345eef0)

ChaWatcher is an anti-cheat / anomaly detector that uses machine-learning to detect outlier behaviours. It uses One-Class Support Vector Machine from my [DataPredict](https://aqwamcreates.github.io/DataPredict/) library.

This documentation contains all the example codes that demonstrates data collection, model training and anomaly detection. There will not be API reference here as I thought this library is pretty simple to use.

You only need to collect normal (non-hacker) data. You can include outlier (hacker) data, but it may reduce the ChaWatcher's model accuracy.

If there are any issues for this library, don’t be afraid to reach out to me at my [LinkedIn](https://www.linkedin.com/in/aqwam-harish-aiman/) or in this [DevForum](https://devforum.roblox.com/t/partial-open-source-chawatcher-a-machine-learning-anti-cheat-anomaly-detector-for-roblox-runs-using-datapredict/2643497?u=myoriginsworkshop) thread.

You can get the library from Roblox's Marketplace [here](https://create.roblox.com/marketplace/asset/15042133614/ChaWatcher)!

## Example codes (with explanations):

### Original Version

* [Data Collection](ExampleCodes/DataCollection.md)

* [Model Training](ExampleCodes/ModelTraining.md)

* [Anomaly Detection](ExampleCodes/AnomalyDetection.md)

## Difference between original and custom versions:

* Custom version has these functions for both DataCollector and AnomalyDetector that can be called outside of their module scripts:

  * setPlayerPreviousDataVector()

  * setPlayerCurrentDataVector()

  * setPlayerHasMissingData()
 
  * updateDataVectors()

  * updateFullDataVector()

* Custom version is an empty template. Put what you want there!

* That's really it...

## Tips:

* Use "radialBasisFunction" as your first choice of kernel function for training models. If the accuracy is weak, then use other kernel functions.

* Set the c value to very small if you want majority of your data points be a "normal" data.

* For the original version, the model training can handle up to 500 data when used with "radialBasisFunction" kernel functions.
