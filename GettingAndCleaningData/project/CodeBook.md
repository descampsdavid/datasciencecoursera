## Code Book

Author: David Descamps

Study design
============

The data was downloaded from the following url :

https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip 

A description of the data is available there :

http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones

And the dataset also includes a README.txt file.

The unit used in the dataset is standard gravity unit 'g'.

As requested for the project, the only measurements used are the mean and standard deviation for each measurement.

Codebook
========

Variable list and descriptions
------------------------------

Variable name  | Description
---------------|------------
subject        | Subject ID
activity       | Activity name
Domain         | Feature: `Time` or `Frequency` domain signal
Instrument     | Feature: `Accelerometer` or `Gyroscope` measuring instrument
Acceleration   | Feature: `Body` or `Gravity` acceleration signal
Variable       | Feature: `Mean` or `Std` (Standard deviation)
Jerk           | Feature: `Jerk` signal
Magnitude      | Feature: `Magnitude` of the signals calculated using the Euclidean norm
Axis           | Feature: 3-axial signals in the `X`, `Y` and `Z` directions
count          | Count of data points used to compute `average`
average        | The average of each variable for each activity and each subject

Dataset structure
-----------------

```R
str(dtTidy)
```

```
Classes 'data.table' and 'data.frame':	11880 obs. of  11 variables:
 $ subject     : int  1 1 1 1 1 1 1 1 1 1 ...
 $ activity    : chr  "LAYING" "LAYING" "LAYING" "LAYING" ...
 $ Jerk        : Factor w/ 2 levels NA,"Jerk": 1 1 1 1 1 1 1 1 1 1 ...
 $ Magnitude   : Factor w/ 2 levels NA,"Magnitude": 1 1 1 1 1 1 1 1 1 1 ...
 $ Domain      : Factor w/ 2 levels "Time","Frequency": 1 1 1 1 1 1 1 1 1 1 ...
 $ Acceleration: Factor w/ 3 levels NA,"Body","Gravity": 1 1 1 1 1 1 2 2 2 2 ...
 $ Instrument  : Factor w/ 2 levels "Accelerometer",..: 2 2 2 2 2 2 1 1 1 1 ...
 $ Measurement : Factor w/ 2 levels "Mean","Std": 1 1 1 2 2 2 1 1 1 2 ...
 $ Axis        : Factor w/ 4 levels NA,"X","Y","Z": 2 3 4 2 3 4 2 3 4 2 ...
 $ count       : int  50 50 50 50 50 50 50 50 50 50 ...
 $ average     : num  -0.0166 -0.0645 0.1487 -0.8735 -0.9511 ...
 - attr(*, "sorted")= chr  "subject" "activity" "Jerk" "Magnitude" ...
 - attr(*, ".internal.selfref")=<externalptr> 
```

Instructions
============

Just execute the R script called `run_analysis.R`. This script does the following :

0. Download the dataset if it is not in the working directory
1. Get the needed files in datatables and merge them:
	- fread() `Y_train.txt` and `Y_test.txt`, then rbind() them to merge all activities ids,
	- fread() `subject_train.txt` and `subject_test.txt`, then rbind() them for all subjects ids,
	- For the sets with the files `X_train.txt` and `X_test.txt`, as.data.table(read.table()) was used instead of fread() due to a bug.
	- fread() `activity_labels.txt` for the labels of the activities
	- fread() also `features.txt` that will be used later
	
2. Column-bind with cbind() activity ids and subject ids in the datatable of the sets
3. Merge the labels of the activities in the datatable of the sets, with the activity id column.
4. Filter the datatable of the sets to keep mean and standard deviations measurements
	- grep was used to select the appropriate measurements
	- melt and merge were used to manipulate and minimise the datatable
5. Categorize the features in different columns and label them as well as their type
	- For each feature, create a temporary matrix by selecting the right rows with grep
	- add the matrix as a new column and factor the different values (1, 2 or 3 depending the feature)
6. Create the second tidy set requested and adding in it the average of each variable for each activity and each subject
	- setkey to "tag" the columns that will be needed
	- select the tagged columns by keys, and add the average with list()
7. Save the tidy set with write.table()
	