##
## download.R - download the dataset for the project
## ----------------------------------------------------------
## "Getting and Cleaning Data" Course Project:
## https://class.coursera.org/getdata-014
## ----------------------------------------------------------
## Solution (c) Thiago Sigrist 2015.
##

library(downloader)
download("http://archive.ics.uci.edu/ml/machine-learning-databases/00240/UCI%20HAR%20Dataset.zip",
         "UCI_HAR_Dataset.zip")
unzip("UCI_HAR_Dataset.zip", exdir="data")