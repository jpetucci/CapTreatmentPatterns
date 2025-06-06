################################################################################
# INSTRUCTIONS: Make sure you have downloaded your cohorts using 
# DownloadCohorts.R and that those cohorts are stored in the "inst" folder
# of the project. This script is written to use the sample study cohorts
# located in "inst/sampleStudy/Eunomia" so you will need to modify this in the code 
# below. 
# 
# See the Create analysis specifications section
# of the UsingThisTemplate.md for more details.
# 
# More information about Strategus HADES modules can be found at:
# https://ohdsi.github.io/Strategus/reference/index.html#omop-cdm-hades-modules.
# This help page also contains links to the corresponding HADES package that
# further details.
# ##############################################################################
library(dplyr)
library(Strategus)

# Time-at-risks (TARs) for the outcomes of interest in your study
timeAtRisks <- tibble(
  label = c("30d"),
  riskWindowStart  = c(1),
  startAnchor = c("cohort start"),
  riskWindowEnd  = c(30),
  endAnchor = c("cohort start")
)

# If you are not restricting your study to a specific time window, 
# please make these strings empty
studyStartDate <- '20100101' #start year
studyEndDate <- ''   #present
# Some of the settings require study dates with hyphens
studyStartDateWithHyphens <- gsub("(\\d{4})(\\d{2})(\\d{2})", "\\1-\\2-\\3", studyStartDate)
studyEndDateWithHyphens <- gsub("(\\d{4})(\\d{2})(\\d{2})", "\\1-\\2-\\3", studyEndDate)

# Consider these settings for estimation  ----------------------------------------
useCleanWindowForPriorOutcomeLookback <- FALSE # If FALSE, lookback window is all time prior, i.e., including only first events

# Shared Resources -------------------------------------------------------------
# Get the list of cohorts - NOTE: you should modify this for your
# study to retrieve the cohorts you downloaded as part of
# DownloadCohorts.R
cohortDefinitionSet <- CohortGenerator::getCohortDefinitionSet(
  settingsFileName = "inst/Cohorts.csv",
  jsonFolder = "inst/cohorts",
  sqlFolder = "inst/sql/sql_server"
)

 # Subset Operators
subsetOperators <- list ( 
prepandemic = CohortGenerator::createLimitSubset(
  name = 'prepandemic',
  calendarStartDate = '20100101',
  calendarEndDate = '20191231'
),
pandemic = CohortGenerator::createLimitSubset(
  name = 'pandemic',
  calendarStartDate = '20200101',
  calendarEndDate = '20221231'
),
postpandemic = CohortGenerator::createLimitSubset(
  name = 'postpandemic',
  #priorTime = 0,
  #followUpTime = 0,
  #limitTo = "all",
  calendarStartDate = '20230101',
  calendarEndDate = NULL
))

subsetDefs <- list(
  targetSubset = CohortGenerator::createCohortSubsetDefinition(
      name = "",
      definitionId = 1,
      subsetOperators = subsetOperators
  )
)

cohortDefinitionSet <- cohortDefinitionSet |>
  addCohortSubsetDefinition(subsetDefs, targetCohortIds %in% c(1, 2))

knitr::kable(cohortDefinitionSet[, names(cohortDefinitionSet)[which(!names(cohortDefinitionSet) %in% c("json", "sql"))]])

if (any(duplicated(cohortDefinitionSet$cohortId))) {
  stop("*** Error: duplicate cohort IDs found ***")
}

# Create some data frames to hold the cohorts we'll use in each analysis ---------------
# Outcomes: The outcome for this study is cohort_id >= 3 
oList <- cohortDefinitionSet %>%
  filter(.data$cohortId > 2 & .data$cohortId <= 22) %>%
  mutate(outcomeCohortId = cohortId, outcomeCohortName = cohortName) %>%
  select(outcomeCohortId, outcomeCohortName) %>%
  mutate(cleanWindow = 0)

# Df for TP
cohorts <- cohortDefinitionSet %>%
  select (cohortId, cohortName)

cohorts$type <- ifelse(cohorts$cohortId %in% oList$outcomeCohortId, 'event', 'target')

# CohortGeneratorModule --------------------------------------------------------
cgModuleSettingsCreator <- CohortGeneratorModule$new()
cohortDefinitionShared <- cgModuleSettingsCreator$createCohortSharedResourceSpecifications(cohortDefinitionSet)
cohortGeneratorModuleSpecifications <- cgModuleSettingsCreator$createModuleSpecifications(
  generateStats = TRUE
)

# CharacterizationModule Settings ---------------------------------------------
cModuleSettingsCreator <- CharacterizationModule$new()
characterizationModuleSpecifications <- cModuleSettingsCreator$createModuleSpecifications(
  targetIds = cohortDefinitionSet$cohortId, # NOTE: This is all T/C/I/O
  outcomeIds = oList$outcomeCohortId,
  outcomeWashoutDays = oList$cleanWindow , 
  minPriorObservation = 0,
  dechallengeStopInterval = 30,
  dechallengeEvaluationWindow = 30,
  riskWindowStart = timeAtRisks$riskWindowStart, 
  startAnchor = timeAtRisks$startAnchor, 
  riskWindowEnd = timeAtRisks$riskWindowEnd, 
  endAnchor = timeAtRisks$endAnchor,
  minCharacterizationMean = .01
)

# treatmentPatternsModule Settings ---------------------------------------------
tModuleSettingsCreator <- TreatmentPatternsModule$new()
treatmentPatternsModuleSpecifications <- tModuleSettingsCreator$createModuleSpecifications(
    cohorts,
    includeTreatments = "startDate",
    indexDateOffset = 0,
    minEraDuration = 1,
    splitEventCohorts = NULL,
    splitTime = NULL,
    eraCollapseSize = 7,
    combinationWindow = 1,
    minPostCombinationDuration = 1,
    filterTreatments = "All",
    maxPathLength = 7,
    ageWindow = 10,
    minCellCount = 5,
    censorType = "minCellCount"
)

# Create the analysis specifications ------------------------------------------
analysisSpecifications <- Strategus::createEmptyAnalysisSpecificiations() |>
  Strategus::addSharedResources(cohortDefinitionShared) |>
  Strategus::addModuleSpecifications(cohortGeneratorModuleSpecifications) |>
  Strategus::addModuleSpecifications(characterizationModuleSpecifications) |>
  Strategus::addModuleSpecifications(treatmentPatternsModuleSpecifications) 

ParallelLogger::saveSettingsToJson(
  analysisSpecifications, 
  file.path("inst", "CAPAnalysisSpecification.json")
)
