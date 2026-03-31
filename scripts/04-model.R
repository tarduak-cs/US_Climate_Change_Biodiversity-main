#### Preamble ####
# Purpose: Make models of the data to generate inferential statistics
# Author: Julia Kim
# Date: 23 March 2024
# Contact: juliaym.kim@mail.utoronto.ca
# License: MIT
# Pre-requisites: Run 01-download_data.R, 02-data_cleaning.R
# Any other information needed? None

#### Workspace setup ####
library(tidyverse)
library(rstanarm)
library(here)
library(arrow)
library(lintr)
library(styler)

#### Read data ####
cleaned_species_data <-
  read_parquet(here("data/analysis_data/cleaned_speciesdata.parquet"))

#### Model data ####
# set reference level of taxon in to "Mammals"
cleaned_species_data$taxon <- factor(cleaned_species_data$taxon)
cleaned_species_data$taxon <- relevel(cleaned_species_data$taxon,
  ref = "Mammals"
)

# fit a logistic regression model, with listed as the response variable
species_listing_model <- stan_glm(
  listed ~ taxon + status +
    ngram_common + ngram_science +
    I(log(ngenus)),
  data = cleaned_species_data,
  family = binomial(link = "logit"),
  prior = normal(
    location = 0,
    scale = 2.5,
    autoscale = TRUE
  ),
  prior_intercept =
    normal(
      location = 0,
      scale = 2.5,
      autoscale = TRUE
    ),
  seed = 853
)

# run the logistic regression model without the six observations with high
# Cook's distances
# Run the outlier check: returns no outliers 
result <- check_outliers(species_listing_model, method = "cook")

# Convert result to data frame 
result <- as.data.frame(result)

# Find the indices of the five highest Cook distances
top_indices <- order(result$Distance_Cook, decreasing = TRUE)[1:6]

cleaned_species_data_Cook <- cleaned_species_data[-top_indices, ]

species_listing_model_Cook <- stan_glm(
  listed ~ taxon + status + ngram_common +
    ngram_science + I(log(ngenus)),
  data = cleaned_species_data_Cook,
  family = binomial(link = "logit"),
  prior = normal(
    location = 0,
    scale = 2.5,
    autoscale = TRUE
  ),
  prior_intercept = normal(
    location = 0,
    scale = 2.5,
    autoscale = TRUE
  ),
  seed = 853
)

#### Save models ####
saveRDS(
  species_listing_model_stanarm,
  file = "models/species_listing_model_stanarm.rds"
)

saveRDS(
  species_listing_model_cook,
  file = "models/species_listing_model_Cook.rds"
)

#### Summarise models ####
summary(species_listing_model_stanarm)
summary(species_listing_model_Cook)

#### Lint and style the code ####
lint(filename = here("scripts/04-model.R"))
style_file(path = here("scripts/04-model.R"))
