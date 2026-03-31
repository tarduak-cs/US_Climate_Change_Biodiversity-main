#### Preamble ####
# Purpose: Replicate Figure 1(b), Table 3, Figure 2 in Moore et al.'s paper
# titled"Noah’s Ark on Rising Seas: Climate Change, Biodiversity Loss and 
# Public Adaptation Costs in the United States" found at
# https://www.journals.uchicago.edu/doi/epdf/10.1086/716662.
# Author: Julia Kim
# Date: 23 March 2024
# Contact:juliaym.kim@mail.utoronto.ca
# License: MIT
# Any other additional info? Moore et al. include a copy of their code here
# https://dataverse.harvard.edu/file.xhtml?fileId=4931778&version=1.0. The
# following code references and builds on their work.

#### Workspace Setup ####
library(tidyverse)
library(ggplot2)
library(here)
library(modelsummary)
library(lintr)
library(styler)

#### FIGURE 1(b) ####
species_data <- read.csv(here::here("data/raw_data/speciesdata.csv"))

cleaned_species_data <- species_data |>
  filter(status %in% c(1, 2, 3, 4, 5, "UNK")) |>
  # relabel status numbers
  mutate(status = case_when(
    status == 1 ~ "Critically Imperiled",
    status == 2 ~ "Imperiled",
    status == 3 ~ "Vulnerable",
    status == 4 ~ "Apparently Secure",
    status == 5 ~ "Secure",
    status == "UNK" ~ "Unknown",
    TRUE ~ as.character(status)
  )) |>
  # convert status to a factor with the desired levels
  mutate(status = factor(status, levels = c(
    "Critically Imperiled", "Imperiled", "Vulnerable",
    "Apparently Secure", "Secure", "Unknown"
  ))) |>
  # convert taxon to a factor with levels arranged in the same order as in
  # Figure 1(a)
  add_count(taxon) |> # add column to count number of occurrences of each taxon
  group_by(taxon, status) |> # group by unique taxon-status groups
  # count number of occurrences of each taxon-status group, and total number of
  # rows in each group
  dplyr::summarise(count = n(), total = n[1]) |>
  mutate(proportion = count / total)

# assign colour to each status, as used by NatureServe
# https://www.natureserve.org/conservation-status-assessment
status_colours <- c(
  "Critically Imperiled" = "#DB0908", # Red
  "Imperiled" = "#F17619", # Orange
  "Vulnerable" = "#FDD131", # Yellow
  "Apparently Secure" = "#27BBEF", # Light blue
  "Secure" = "#194B89", # Blue
  "Unknown" = "grey" # Grey
)

# plot data
cleaned_species_data |>
  ggplot(aes(x = taxon, y = proportion, fill = status)) +
  geom_bar(stat = "identity", position = "fill") +
  scale_fill_manual(values = status_colours) + # apply custom colors
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) + # rotate x-labels
  labs(x = "Taxon", y = "Proportion", fill = "Status") +
  # add counts for each taxon above the stacked chart
  geom_text(aes(x = taxon, y = 1.05, label = total), size = 3)

#### TABLE 3 ####
# set reference level of taxon in to "Mammals"
cleaned_species_data$taxon <- factor(cleaned_species_data$taxon)
cleaned_species_data$taxon <- relevel(cleaned_species_data$taxon,
  ref = "Mammals"
)

# fit a logistic regression model, with listed as the response variable
fit1 <- glm(
  listed ~ taxon + status + ngram_common +
    ngram_science + I(log(ngenus)),
  data = species_data[-which(species_data$ngram_common_flag == 1), ],
  family = binomial(link = "logit"),
  x = TRUE 
)

# display regression results
modelsummary::modelsummary(fit1)

#### FIGURE 2 ####
# convert values to probabilities of listing
taxconsmeans <- species_data |>
  # remove rows where status is NA
  filter(!is.na(status)) |>
  # filter rows where ngram_common_flag is 0
  filter(ngram_common_flag == 0) |>
  # group by taxon and status
  group_by(taxon, status) |>
  # calculate median values and uncertainties for each variable
  summarize(
    ngram_common = median(ngram_common, na.rm = TRUE),
    ngram_science = median(ngram_science, na.rm = TRUE),
    ngenus = log(median(ngenus, na.rm = TRUE))
  )

# use coefficients from fit to find conditional probabilities of listing for
# taxon-status groups
taxon <- levels(factor(species_data$taxon))
status <- levels(factor(species_data$status))

# use coefficients from fit to find conditional probabilities of listing for
# taxon-status groups
for (i in 1:length(taxon)) {
  for (j in 1:length(status)) {
    # calculate intercept for the logistic regression model
    intercept <- fit1$coefficients[1] +
      # add taxon coefficient if i is not 1
      ifelse(i == 1, 0, fit1$coefficients[grep(
        taxon[i],
        names(fit1$coefficients)
      )]) +
      # add status coeff. if j is not 1 or use 'Extinct' coeff. if j is 6
      ifelse(j == 1, 0,
        ifelse(j == 6, fit1$coefficients[grep(
          "Extinct",
          names(fit1$coefficients)
        )],
        fit1$coefficients[grep(status[j], names(fit1$coefficients))]
        )
      )
    # subset taxconsmeans dataframe based on current 'taxon[i]' and 'status[j]'
    taxmeanstemp <- taxconsmeans[which(taxconsmeans$taxon == taxon[i]), ]
    taxmeanstemp <- taxmeanstemp[ifelse(j == 6, grep(
      "Extinct",
      taxmeanstemp$status
    ),
    grep(status[j], taxmeanstemp$status)
    ), ]
    # calculate fitted values for the logistic regression model
    fit <- intercept + as.numeric(taxmeanstemp[3:5]) %*%
      fit1$coefficients[17:19]
    # transform fitted values into probabilities using the logistic function
    fitprob <- exp(fit) / (1 + exp(fit))
    # assign 'fitprob' to 'taxconfit' if it's the first iteration
    if (i == 1 && j == 1) {
      taxconfit <- fitprob
    }
    # append 'fitprob' to 'taxconfit' for subsequent iterations
    if (i > 1 || j > 1) {
      taxconfit <- append(taxconfit, fitprob)
    }
  }
}

# create a data frame with taxon, status, and fitted probabilities
taxconfit <- data.frame(
  taxon = rep(taxon, each = length(status)),
  status = rep(status, length(taxon)),
  fitprob = taxconfit
)

# specify shapes for each taxon category
shape_values <- c(1, 2, 3, 4, 5, 6, 7, 8, 9) # specify shapes for each taxon
# category

# plot data of predicted probability of listing against assessed conservation
# status, with points shaped according to taxon
taxconfit |>
  ggplot(aes(
    x = status, y = fitprob, group = taxon, col = taxon,
    pch = taxon
  )) +
  geom_point(size = 3, stroke = 0.75) +
  labs(
    x = "Assessed Conservation Status",
    y = "Predicted Probability of Listing"
  ) +
  theme_minimal() +
  scale_shape_manual(values = shape_values) # manually specify shape values

#### Lint and style the code ####
lint(filename = here("scripts/99-replications.R"))
style_file(path = here("scripts/99-replications.R"))
