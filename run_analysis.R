##
## run_analysis.R - generates tidy dataset for the project
## ----------------------------------------------------------
## "Getting and Cleaning Data" Course Project:
## https://class.coursera.org/getdata-014
## ----------------------------------------------------------
## Solution (c) Thiago Sigrist 2015.
##

library(dplyr)


run_analysis <- function(base_path = "data") {
  ##
  ## run_analysis() - generates tidy dataset for the project.
  ##
  ## Arguments:
  ## ----------
  ## base_path - path of where the "UCI HAR Dataset" directory is located.
  ##             Defaults to "data" which is the directory where download.R
  ##             will place it.
  ##

  # files are inside a "UCI HAR Dataset" directory, append that to base_path
  base_path <- file.path(base_path, "UCI HAR Dataset")

  # read tables with activity labels and feature labels
  activity_labels <- read.table(file.path(base_path, "activity_labels.txt"),
                                col.names = c("id", "activity"))
  
  feature_labels <- read.table(file.path(base_path, "features.txt"),
                               col.names = c("id", "feature"))

  process_dataset <- function(dataset_name) {
    ##
    ## process_dataset() - constructs a full tidy data.frame from one of
    ##                     the "test" or "train" sets from the raw UCI HAR
    ##                     Dataset.
    ##
    ## Arguments:
    ## ----------
    ## dataset_name - name of the desired dataset, either "test" or "train".
    ## base_path    - path to the "UCI HAR Dataset" directory.
    ##
    ## Return value:
    ## -------------
    ## A R data.frame containing the tidy dataset as a wide table.
    ##

    # dataset directory has the same name as the dataset, append that to path
    dataset_path <- file.path(base_path, dataset_name)

    # subject variable file always has the name "subject_<dataset_name>.txt"
    subject_path <- paste0("subject_", dataset_name, ".txt")
    subject_path <- file.path(dataset_path, subject_path)
    subject <- read.table(subject_path, col.names = "subject")

    # activity code variable file always has the name "y_<dataset_name>.txt"
    activity_code_path <- paste0("y_", dataset_name, ".txt")
    activity_code_path <- file.path(dataset_path, activity_code_path)
    activity_code <- read.table(activity_code_path,
                                col.names = "activity_code")

    # associate activity label to activity
    activity <- inner_join(activity_code, activity_labels,
                           by = c("activity_code" = "id"))
    activity <- activity$activity

    # measure variables file always has the name "X_<dataset_name>.txt"
    measures_path <- paste0("X_", dataset_name, ".txt")
    measures_path <- file.path(dataset_path, measures_path)
    
    # measure variable names are in the feature_labels table, so use that
    # as column names
    measures <- read.table(measures_path, col.names = feature_labels$feature)
    
    # put together subject ID, activity labels and measures in a single table
    df <- cbind(subject, activity, measures)
    
    # dplyr will replace characters such as "[()-,]" from our column names with
    # dots "\\."
    # this means we'll have lots of consecutive dots in our column names, so
    # let's clean that up with some regular expression action!
    #
    # regexp in English:
    # remove from column names all sequences of one or more dots that precede
    # either: another dot, or the end of the string
    colnames(df) <- gsub("(\\.+)(\\.|$)", "\\2", colnames(df))

    # some column/variable names are incorrectly labeled with "BodyBody"!
    # oops, we have to fix that too:
    colnames(df) <- gsub("BodyBody", "Body", colnames(df))
    
    # let's consider the magnitude of a signal a component of it, so a
    # signal has 4 components: its 3 axes X, Y, Z and its magnitude
    # to do that, we'll rename the columns that have the word "Mag" in them
    # to have a final ".mag" like the axes measurements have ".X", ".Y" etc
    colnames(df) <- gsub("(.*)(Mag)(.*)", "\\1\\3.mag", colnames(df))
    
    df
  }

  # obtain names for the named datasets - these are the directories
  # inside "UCI HAR Dataset"
  named_datasets <- list.dirs(base_path, full.names = FALSE, recursive = FALSE)

  # process all datasets within "UCI HAR Dataset" and bind all the data
  # together in a single data.frame
  tidy_df <- rbind_all(lapply(named_datasets, process_dataset))
  
  # choose only columns with mean or standard deviation (std)
  # identify those by either the word "mean" or "std", and search by whole
  # word only, i.e., don't return results if "mean" or "std" are part of
  # a bigger word
  measure_names <- colnames(tidy_df)
  measure_names <- grep("\\<(mean|std)\\>", measure_names, value = TRUE)
  # of course don't forget to include the subject and activity identifiers
  measure_names <- c("subject", "activity", measure_names)
  tidy_df <- tidy_df[, measure_names]
  
  # arrange the tidy dataset by subject and activity
  tidy_df <- arrange(tidy_df, subject, activity)
  
  # write tidy dataset to working directory
  write.table(tidy_df, "tidy_dataset_full.txt", row.names = FALSE)
  
  # now make an aggregate data.frame (using means)
  agg_df <- tidy_df %>%
    group_by(subject, activity) %>%
    summarise_each(funs(mean))
  
  # write aggregate dataset to working directory
  write.table(agg_df, "tidy_dataset_summarized.txt", row.names = FALSE)

  ###### TESTS - uncomment to run ######

  ## TEST 1: every subject should have performed all 6 activities
#   test1 <- function(df) {
#     test <- all(sapply(unique(df$subject), function(x) {
#       nrow(unique(df[df$subject == x, "activity"])) == 6
#     }))
#     if (test == FALSE) {
#       stop("TEST 1 failed: not all subjects perform all 6 activities")
#     }
#   }
#   test1(tidy_df)
#   test1(agg_df)

  ## TEST 2: read back text files and compare to data.frames
#   test2 <- function(df, filename) {
#     file_df <- read.table(filename, header = TRUE)
#     test <- all.equal(df, file_df)
#     if (test == FALSE) {
#       stop("TEST 2 failed: text file not equal to data.frame")
#     }
#   }
#   test2(tidy_df, "tidy_dataset_full.txt")
#   test2(agg_df, "tidy_dataset_summarized.txt")

  ## TEST 3: if we have data.table installed, check if fread can read back
  ##         our generated text files
#   test3 <- function(df, filename) {
#     if ("data.table" %in% installed.packages()) {
#       require(data.table)
#       file_df <- fread(filename)
#       test <- all.equal(df, file_df)
#       if (test == FALSE) {
#         stop("TEST 3 failed: text file not equal to data.frame")
#       }
#     }
#   }
#   test3(tidy_df, "tidy_dataset_full.txt")
#   test3(agg_df, "tidy_dataset_summarized.txt")
}

run_analysis()