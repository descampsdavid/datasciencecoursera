packages <- c("data.table", "reshape2")
sapply(packages, require, character.only = TRUE, quietly = TRUE)

workingDir <- getwd()
inputDir <- file.path(workingDir, "UCI HAR Dataset")

#Download the dataset if not present
if (!file.info("UCI HAR Dataset")$isdir) {
  dataFile <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
  download.file(dataFile, "./UCI-HAR-dataset.zip", method="curl")
  unzip("./UCI-HAR-dataset.zip")
}

#read files
filePath <- file.path(inputDir, "train", "subject_train.txt")
dtSubjectTrain <- fread(filePath)
filePath <- file.path(inputDir, "test", "subject_test.txt")
dtSubjectTest <- fread(filePath)
filePath <- file.path(inputDir, "train", "Y_train.txt")
dtActivityTrain <- fread(filePath)
filePath <- file.path(inputDir, "test", "Y_test.txt")
dtActivityTest <- fread(filePath)
filePath <- file.path(inputDir, "train", "X_train.txt")
#workaround a bug with fread
dtTrain <- as.data.table(read.table(filePath))
filePath <- file.path(inputDir, "test", "X_test.txt")
#same bug
dtTest <- as.data.table(read.table(filePath))
filePath <- file.path(inputDir, "activity_labels.txt")
dtActivityNames <- fread(filePath)
filePath <- file.path(inputDir, "features.txt")
dtFeatures <- fread(filePath)

#merge subject tables, activities tables and main datatable (row bind)
dtSubject <- rbind(dtSubjectTrain, dtSubjectTest)
dtActivity <- rbind(dtActivityTrain, dtActivityTest)
dtMain <- rbind(dtTrain, dtTest) ###requirement 1

#setnames
setnames(dtSubject, "V1", "subject")
setnames(dtActivity, "V1", "activityCode")
setnames(dtActivityNames, names(dtActivityNames), c("activityCode", "activity"))
setnames(dtFeatures, names(dtFeatures), c("featureCode", "feature"))

#merge subject and activities columns (cbind) in main datatable
dtMain <- cbind(dtSubject, dtActivity, dtMain)

#merge activity labels in main datatable
dtMain <- merge(dtMain, dtActivityNames, by = "activityCode", all.x = TRUE)

#set keys
setkey(dtMain, subject, activityCode, activity) ###requirement 3

#Extracts only the measurements on the mean and 
# standard deviation for each measurement. 
#
# now the main datatable is enormous, we need to 
# get the features that have only "mean" and "std"
# in their name

dtFeatures <- dtFeatures[grepl("(mean|std)\\(", feature)]

#the featureCode values in dtFeatures should matched 
# with column names in dtMain 
dtFeatures$featureCode <- dtFeatures[, paste0("V", featureCode)]
head(dtFeatures)

dtFeatures$featureCode

#with the matched featureCode values, subset the big 
# main datatable with only the mean and standard deviations
select <- c(key(dtMain), dtFeatures$featureCode)
dtMain <- dtMain[, select, with = FALSE]

#now we have the main datatable with the required variables
#we still need to put descriptive activity names to columns
dtMain <- data.table(melt(dtMain, key(dtMain), variable.name = "featureCode"))
dtMain <- merge(dtMain, dtFeatures[, list(featureCode, feature)], by = "featureCode", 
            all.x = TRUE)

# Features with 1 category (is 'something' or not)
dtMain$Jerk <- factor(grepl("Jerk", dtMain$feature), labels = c(NA, "Jerk"))
dtMain$Magnitude <- factor(grepl("Mag", dtMain$feature), labels = c(NA, "Magnitude"))
# Features with 2 categories (two choices)
y <- matrix(seq(1, 2), nrow = 2)
#Time/Frequency Domains
x <- matrix(c(grepl("^t", dtMain$feature), grepl("^f", dtMain$feature)), ncol = nrow(y))
dtMain$Domain <- factor(x %*% y, labels = c("Time", "Frequency"))
#Accelerometer/Gyroscope Instruments
x <- matrix(c(grepl("Acc", dtMain$feature), grepl("Gyro", dtMain$feature)), ncol = nrow(y))
dtMain$Instrument <- factor(x %*% y, labels = c("Accelerometer", "Gyroscope"))
#Body/Gravity Acceleration
x <- matrix(c(grepl("BodyAcc", dtMain$feature), grepl("GravityAcc", dtMain$feature)), ncol = nrow(y))
dtMain$Acceleration <- factor(x %*% y, labels = c(NA, "Body", "Gravity"))
#Mean/Standard Deviation Measurement
x <- matrix(c(grepl("mean()", dtMain$feature), grepl("std()", dtMain$feature)), ncol = nrow(y))
dtMain$Measurement <- factor(x %*% y, labels = c("Mean", "Std"))
## Axis, the feature with 3 categories (X,Y and Z)
y <- matrix(seq(1, 3), nrow = 3)
x <- matrix(c(grepl("-X", dtMain$feature), grepl("-Y", dtMain$feature), grepl("-Z", dtMain$feature)), ncol = nrow(y))
dtMain$Axis <- factor(x %*% y, labels = c(NA, "X", "Y", "Z"))

setkey(dtMain, subject, activity, Jerk, Magnitude, Domain, Acceleration, Instrument, 
      Measurement, Axis)
dtTidy <- dtMain[, list(count = .N, average = mean(value)), by = key(dtMain)] ##requirement 5

#f <- file.path(workingDir, "HAR_UsingSmartphonesDataset_set.txt")
#write.table(dtMain, f, quote = FALSE, sep = "\t", row.names = FALSE)
f <- file.path(workingDir, "HAR_UsingSmartphonesDataset_tidyset.txt")
write.table(dtTidy, f, quote = FALSE, sep = "\t", row.names = FALSE)