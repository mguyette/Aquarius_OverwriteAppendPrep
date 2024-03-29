#========================================================#
# This script prepares a json object to be input into    #
# the Swagger UI for the AQUARIUS Acquisition API        #
# URL: http://aquasvr/AQUARIUS/Acquisition/v2/           #
#      swagger-ui/#!/timeseries/PostTimeSeriesAppend     #
# This script requires a telemetry file (.dat), the time #
# series Unique ID, and the start and end time of the    #
# period you would like to overwrite with new data       #
#========================================================#

## Required packages
library(readr)         # for read_csv()
library(jsonlite)      # for toJSON()


##==> CHANGE THE FILE PATH HERE ####
## Import data set from .dat telemetry file
dat <- read_csv("./dat_files/SJR_US_Hell_N_Blazes_CM_WQ_Hourly.dat", skip = 1)

## Clean up the data frame
dat <- dat[-c(1:2),]
dat$TIMESTAMP <- as.POSIXct(dat$TIMESTAMP,tz = "EST")
dat[,2:length(dat)] <- sapply(dat[,2:length(dat)],
                              as.numeric)

##==> CHANGE THE PARAMETER AND LABEL HERE ####
## Use the Parameter and Label as shown in Aquarius
parameter <- "Sp Cond"
label <- "YSI"

## Load crosswalk table of telemetry file columns and 
## parameter/label combinations
xwalk <- read.csv("TelemetryParameters.csv")

## Get column name
column <- as.character(xwalk$Telemetry_Column[xwalk$Parameter == parameter & xwalk$Label == label])

## Subset the dat file to include only the datetime and the 
## parameter of interest
dat <- dat[,c("TIMESTAMP",column)]

##==> CHANGE THE UNIQUE ID HERE ####
## Go to the hamburger button for the time series and select
## View/Edit Details. Cut and paste the Unique ID from the 
## bottom of the Time Series Attributes section of the 
uid <- "9259636e1fb9425f9934b355a785d7e4"

##==> CHANGE THE START TIME FOR PERIOD REQUIRING ####
#### OVERWRITE HERE                             ####
## Start datetime of period requiring overwrite
## Use format shown in the second argument
starttime <- as.POSIXct("2019-05-29 08:00:00","%Y-%m-%d %H:%M:%S", tz = "EST")

##==> CHANGE THE END TIME FOR PERIOD REQUIRING ####
#### OVERWRITE HERE                           ####
## End datetime of period requiring overwrite
## Use format shown in the second argument
endtime <- as.POSIXct("2019-05-30 07:00:00","%Y-%m-%d %H:%M:%S", tz = "EST")

## Cut down data set
cut <- dat[dat$TIMESTAMP >= starttime & dat$TIMESTAMP <= endtime,]

## Change column names
names(cut) <- c("Time","Value")

## Format Time to ISO 8601 timestamp and convert to GMT (from EST)
cut$Time <- format(cut$Time,"%Y-%m-%dT%H:%M:%SZ", tz = "GMT")
starttime_iso <- format(starttime,"%Y-%m-%dT%H:%M:%SZ", tz = "GMT")
endtime_iso <- format(endtime + 60,"%Y-%m-%dT%H:%M:%SZ", tz = "GMT")

## Create a data frame that is built around the json structure
## requirements as defined by Aquatic Informatics
## Part 1: Unique ID
df_json <- data.frame(UniqueID = uid)

## Part 2: Points
df_json$Points <- list(cut)

## Part 3: Time Range
df_json$TimeRange <- data.frame(Start = starttime_iso,
                              End = endtime_iso)

## Create a JSON object holding the new data
json_for_export <- jsonlite::toJSON(df_json,pretty = T)

##==> CHANGE JSON FILE LOCATION AND FILE NAME HERE ####
## You MUST include .json at the end of the file name
## Save file to disk
write(json_for_export, file = "./JSON_files/HBI_SpCond.json")

