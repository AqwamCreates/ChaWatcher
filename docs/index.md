# Welcome To ChaWatcher's Documentation!

ChaWatcher is an anti-cheat that uses machine-learning to detect outlier behaviours. It uses One-Class Support Vector Machine from Aqwam's [DataPredict](https://aqwamcreates.github.io/DataPredict/) library.

This documentation contains all the example codes that demonstrates data collection, model training and anomaly detection. There will not be API reference here as I thought this library is preddy simple to use.

You only need to collect normal (non-hacker) data. You can include outlier (hacker) data, but it may reduce the ChaWatcher's model accuracy.

If there are any issues for this library, don’t be afraid to reach out to me at my [LinkedIn](https://www.linkedin.com/in/aqwam-harish-aiman/) or in this DevForum thread.

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

  * updateFullDataVector()

* Custom version is an empty template.

* That's really it...
