library(readr)
library(dplyr)
library(forcats)
library(tidyverse)



#Read in data ----
clean <- function(df) df %>% rename(sub = `P'`, TaskNum = `Task #`, TSTmin = `Task Start Time`, TSTsec = X6,
                                    TSTfps = X7, TETmin = `Task End Time`,
                                    TETsec = X10, TETfps = X11, 
                                    GSTmin = `Glance Start Time`, GSTsec = X15,
                                    GSTfps = X16, GETmin = `Glance End Time`, 
                                    GETsec = X19, GETfps = X20) %>%
  select(1:4, TSTmin, TSTsec, TSTfps, TETmin, TETsec, TETfps, 
              GSTmin, GSTsec, GSTfps, GETmin, GETsec, GETfps) %>%
  filter(!is.na(Condition)) %>%
  mutate(Car = as.factor(Car),
         Condition = as.factor(Condition),
         TSTmin = parse_integer(TSTmin),
         TSTsec = parse_integer(TSTsec),
         TSTfps = parse_integer(TSTfps),
         TETmin = parse_integer(TETmin),
         TETsec = parse_integer(TETsec),
         TETfps = parse_integer(TETfps), 
         GSTmin = parse_integer(GSTmin), 
         GSTsec = parse_integer(GSTsec), 
         GSTfps = parse_integer(GSTfps), 
         GETmin = parse_integer(GETmin),
         GETsec = parse_integer(GETsec),
         GETfps = parse_integer(GETfps), 
         codetype = 0) %>%
  mutate(TSTmin_ms = TSTmin * 60000,
         TSTsec_ms = TSTsec * 1000,
         TSTfps_ms = TSTfps * 33.33,
         TETmin_ms = TETmin * 60000,
         TETsec_ms = TETsec * 1000,
         TETfps_ms = TETfps * 33.33,
         GSTmin_ms = GSTmin * 60000,
         GSTsec_ms = GSTsec * 1000,
         GSTfps_ms = GSTfps * 33.33,
         GETmin_ms = GETmin * 60000,
         GETsec_ms = GETsec * 1000,
         GETfps_ms = GETfps * 33.33) %>%
  mutate(TaskStartTime = TSTmin_ms + TSTsec_ms + TSTfps_ms,
         TaskEndTime = TETmin_ms + TETsec_ms + TETfps_ms,
         GlanceStartTime = GSTmin_ms + GSTsec_ms + GSTfps_ms,
         GlanceEndTime = GETmin_ms + GETsec_ms + GETfps_ms) %>%
  mutate(TotalTaskTime = TaskEndTime - TaskStartTime,
         GlanceTime = GlanceEndTime - GlanceStartTime)

chevy <- read_csv('CS_Chevy Equinox.csv') %>%
  clean()

chrysler <- read_csv('CS_Chrysler 200.csv') %>% 
  clean()

ford <- read_csv('CS_Ford Mustang.csv') %>%
  clean()

honda <- read_csv('CS_Honda Accord.csv') %>% 
  clean()

hyundai <- read_csv('CS_Hyundai Elantra.csv') %>%
  clean()

jeep <- read_csv('CS_Jeep Cherokee.csv') %>%
  clean()

recoded <- read_csv('Recoded.csv') %>%
  clean() %>%
  mutate(codetype = 1)


#Combine ----
# Combine original coding with recoded dataframe, split out the "Cars" variable into separate columns for make, model, and trim,
# and then take "Audio_" out of the Condition column 
# These steps make the videocoded data mergeable with hit rate data from the DRT

combvgtdata <- rbind(chevy, chrysler, ford, honda, hyundai, jeep) %>%
  rename(make = Car) %>%
  mutate(make = parse_factor(make, levels = c("ChevyEquinox", "HondaAccord", "FordMustang", 
                                              "HyundaiElantra", "JeepCherokee", "Chrysler200")),
         Condition = parse_factor(Condition, levels = c("Audio_V", "Audio_SW", "Audio_TS", "Audio_M"))) %>%
  mutate(make = fct_recode(make, Chevrolet = "ChevyEquinox", Honda = "HondaAccord", 
                           Ford = "FordMustang", Hyundai = "HyundaiElantra", Jeep = "JeepCherokee",
                           Chrysler = "Chrysler200"),
         model = fct_recode(make, Equinox = "Chevrolet", Accord = "Honda", Ford = "Ford",
                            Elantra = "Hyundai", Cherokee = "Jeep", "200" = "Chrysler"),
         trim = fct_recode(make, EcoBoost.Convertible = "Ford",
                           EXL = "Honda",
                           LT = "Chevrolet",
                           Limited = "Jeep",
                           GT = "Hyundai",
                           Limited = "Chrysler"),
         Condition = fct_recode(Condition, SW = "Audio_SW",
                                V = "Audio_V",
                                TS = "Audio_TS",
                                M = "Audio_M")) %>% 
  # this creates a counter similiar to Task #, in order to give make each glance uniquely identifiable 
  group_by(sub, make, Condition, TaskNum) %>%
  mutate(GlanceNum = 1:n()) %>%
  select(sub, make, model, trim, Condition, TaskNum, GlanceNum, TaskStartTime, TaskEndTime, 
                                                       GlanceStartTime, GlanceEndTime,
                                                       TotalTaskTime, GlanceTime, codetype)

recodedgtdata <- recoded %>%
  rename(make = Car) %>%
  mutate(make = parse_factor(make, levels = c("ChevyEquinox", "HondaAccord", "FordMustang", 
                                              "HyundaiElantra", "JeepCherokee", "Chrysler200")),
         Condition = parse_factor(Condition, levels = c("Audio_V", "Audio_SW", "Audio_TS", "Audio_M"))) %>%
  mutate(make = fct_recode(make, Chevrolet = "ChevyEquinox", Honda = "HondaAccord", 
                           Ford = "FordMustang", Hyundai = "HyundaiElantra", Jeep = "JeepCherokee",
                           Chrysler = "Chrysler200"),
         model = fct_recode(make, Equinox = "Chevrolet", Accord = "Honda", Ford = "Ford",
                            Elantra = "Hyundai", Cherokee = "Jeep", "200" = "Chrysler"),
         trim = fct_recode(make, EcoBoost.Convertible = "Ford",
                           EXL = "Honda",
                           LT = "Chevrolet",
                           Limited = "Jeep",
                           GT = "Hyundai",
                           Limited = "Chrysler"),
         Condition = fct_recode(Condition, SW = "Audio_SW",
                                V = "Audio_V",
                                TS = "Audio_TS",
                                M = "Audio_M")) %>%
  # this creates a counter similiar to Task #, in order to give make each glance uniquely identifiable 
  group_by(sub, make, Condition, TaskNum) %>%
  mutate(GlanceNum = 1:n()) %>%
  select(sub, make, model, trim, Condition, TaskNum, GlanceNum, TaskStartTime, TaskEndTime, 
         GlanceStartTime, GlanceEndTime,
         TotalTaskTime, GlanceTime, codetype)

# Write File ----------

write_csv(combvgtdata, "combvgtdata.csv")
write_csv(recodedgtdata, "recodedgtdata.csv")



# Error Detection -----------
error_detect <- function(df) df %>%
  group_by(sub, make, Condition, TaskNum) %>%
  # this takes advantage of dplyr's recycling behavior to paste TaskStartTime
  mutate(TaskStartTime = mean(TaskStartTime, na.rm = T),
         TaskEndTime = mean(TaskEndTime, na.rm = T),
         TotalTaskTime = mean(TotalTaskTime, na.rm = T)) %>%
  ungroup() %>%
  mutate(Error_Start = if_else(GlanceStartTime >= TotalTaskTime | GlanceStartTime == 0, 0, 1),
         Error_End =  if_else(TaskEndTime >= GlanceEndTime | GlanceEndTime == 0, 0, 1),
         Error_Long = if_else(TotalTaskTime < 100000, 0, 1),
         GlanceEnd_lag = lag(GlanceEndTime, 1)) %>%
  mutate(Error_Overlap = if_else(TaskNum == 1 & GlanceNum == 1 | GlanceStartTime == 0 & GlanceEndTime == 0, 0, 
                                 if_else(GlanceEnd_lag < GlanceStartTime, 0, 1))) %>%
  filter(Error_Start == 1 | Error_End == 1 | Error_Long == 1 | Error_Overlap == 1 | is.na(Error_Start) | is.na(Error_End))

errors_original <- combvgtdata %>%
  error_detect()

errors_recoded <- recodedgtdata %>%
  error_detect()





