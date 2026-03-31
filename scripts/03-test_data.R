#### Preamble ####
# Purpose: Test the data sets
# Author: Julia Kim
# Date: 23 March 2024
# Contact: juliaym.kim@mail.utoronto.ca
# License: MIT
# Pre-requisites: Run 01-download_data.R, 02-data_cleaning.R
# Any other information needed? None

#### Workspace setup ####
library(tidyverse)
library(here)
library(arrow)
library(lintr)
library(styler)

#### Read data ####
cleaned_species_data <-
  read_parquet(here("data/analysis_data/cleaned_speciesdata.parquet"))

#### Testing species data ####
# Check that there are exactly 9 unique taxa to which a species can belong
length(unique(cleaned_species_data$taxon)) == 9

# Check those taxons are exclusively one of these 9: "Fishes", "Birds",
# "Mammals", "Amphibians", "Invertebrates", "Plants", "Reptiles", "Fungi",
# "Protists"
unique(cleaned_species_data$taxon) == c(
  "Fishes", "Birds", "Mammals", "Amphibians",
  "Invertebrates", "Plants", "Reptiles", "Fungi",
  "Protists"
)

# Check that listed is binary variables taking on 0 or 1
all(cleaned_species_data$listed %in% c(0, 1)) == TRUE

# Check that status is a value of 1, 2, 3, 4, 5, "UNK", "Prob. Extinct",
# "Extinct" or NA
all(cleaned_species_data$status %in% c(
  1, 2, 3, 4, 5, "UNK", "Prob. Extinct",
  "Extinct", NA
)) == TRUE

# Check ngenus only takes NA or positive values
all(is.na(cleaned_species_data$ngenus) | cleaned_species_data$ngenus > 0) ==
  TRUE

# Verify that each column is of the appropriate class
cleaned_species_data$name |> class() == "character"
cleaned_species_data$taxon |> class() == "character"
cleaned_species_data$listed |> class() == "numeric"
cleaned_species_data$status |> class() == "character"
cleaned_species_data$ngram_common |> class() == "numeric"
cleaned_species_data$ngram_science |> class() == "numeric"
cleaned_species_data$ngenus |> class() == "numeric"

# Check if there are no duplicates in the dataset
all(duplicated(cleaned_species_data)) == FALSE 

#### Lint and style the code ####
lint(filename = here("scripts/03-test_data.R"))
style_file(path = here("scripts/03-test_data.R"))
