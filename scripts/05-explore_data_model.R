#### Preamble ####
# Purpose: Explore and understand the dataset and model by creating data
# visualisations
# Author: Julia Kim
# Data: 10 April 2024
# Contact: juliaym.kim@mail.utoronto.ca
# License: MIT
# Pre-requisites: Run 01-download_data.R, 02-data_cleaning.R
# Any other information needed? None

#### Workspace setup ####
library(tidyverse)
library(here)
library(arrow)
library(patchwork)
library(lintr)
library(styler)

#### Read data and model ####
cleaned_species_data <-
  read_parquet(here("data/analysis_data/cleaned_speciesdata.parquet"))

species_listing_model <- readRDS(here("models/species_listing_model.rds"))

#### Make plots ####
## Plot the distribution of the logarithm of genus size by taxon ##
ggplot(cleaned_species_data, aes(x = ngenus)) +
  geom_histogram(nbins = 10, fill = "gray", color = "black") +
  facet_wrap(~taxon, ncol = 3, scales = "free") +
  theme_minimal() +
  labs(x = "Genus size (logged)", y = "Frequency") +
  scale_x_log10()

## Plot distribution of common and scientific n-grams by taxon
# group by taxon and calculate mean ngram_common and ngram_science ##
taxon_means <- cleaned_species_data |>
  group_by(taxon) |>
  summarise(
    mean_ngram_common = mean(ngram_common, na.rm = TRUE),
    mean_ngram_science = mean(ngram_science, na.rm = TRUE)
  )

# reshape the data for plotting
taxon_means_long <- pivot_longer(taxon_means,
  cols = c(
    mean_ngram_science,
    mean_ngram_common
  ),
  names_to = "variable",
  values_to = "mean_value"
)

# plot the means with legend in upper right corner
ggplot(taxon_means_long, aes(x = taxon, y = mean_value, fill = variable)) +
  geom_bar(stat = "identity", position = position_dodge()) +
  labs(
    x = "Taxon",
    y = expression(paste(italic("n"), "-gram frequency")),
    fill = NULL
  ) +
  scale_fill_manual(
    values = c("#DB0908", "#194B89"),
    labels = c("common name", "scientific name")
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = c(0.85, 0.84), # adjust legend position
    legend.text.align = 0, # align legend labels to the left
    legend.margin = margin(1.5, 1.5, 1.5, 1.5),
    # adjust transparency
    legend.background = element_rect(fill = alpha("white", 0.7)),
    legend.text = element_text(size = 7.5),
    # reduce size of legend squares to 0.5 cm
    legend.key.size = unit(0.5, "cm")
  )

## Make summary statistics table of number of listed species by taxon ##
# group by taxon and calculate the number of listed species
summary_list_table <- cleaned_species_data |>
  group_by(taxon) |>
  summarise(num_listed_species = sum(listed == 1, na.rm = TRUE))

# print the summary table as a kable
summary_list_table |>
  kable(
    col.names = c("Taxon", "Listed"), format = "latex",
    booktabs = TRUE, linesep = ""
  ) |>
  column_spec(1, bold = TRUE)

## Make predictions of the probability of species appearing on the ESA list,
# as implied by regression model against ngrams and logged genus size ###
# Omit all NAs from the dataset
cleaned_data <- na.omit(cleaned_species_data)

# Convert taxon and status to factors
cleaned_data$taxon <- factor(cleaned_data$taxon)
cleaned_data$status <- factor(cleaned_data$status)

# Create a data frame
plotting_data <- data.frame(
  ngram_science = seq(min(cleaned_data$ngram_science),
    max(cleaned_data$ngram_science),
    length.out = 100
  ),
  ngram_common = seq(min(cleaned_data$ngram_common),
    max(cleaned_data$ngram_common),
    length.out = 100
  ),
  taxon = levels(cleaned_data$taxon)[6], # reference level: mammal
  status = levels(cleaned_data$status)[1], # reference level: G1
  ngenus = seq(min(cleaned_data$ngenus),
    max(cleaned_data$ngenus),
    length.out = 100
  ),
  listed = (0:1)
)

# Predict probabilities using the model
plotting_data$preds <- predict(species_listing_model,
  newdata = plotting_data,
  type = "response"
)

# Plot probabilities against covariates
ngram_science_plot <- ggplot(cleaned_species_data, aes(
  x = ngram_science,
  y = listed
)) +
  geom_jitter(width = 0, height = 0.005, alpha = 0.2, colour = "#194B89") +
  geom_line(
    data = plotting_data, aes(x = ngram_science, y = preds),
    linewidth = 1, colour = "#194B89"
  ) +
  labs(
    x = expression(paste("Science ", italic("n"), "-gram")),
    y = "Predicted Probability of Listing"
  ) +
  theme(plot.margin = margin(5, 10, 5, 10, "pt")) +
  theme_minimal()

ngram_common_plot <- ggplot(cleaned_species_data, aes(
  x = ngram_common,
  y = listed
)) +
  geom_jitter(width = 0, height = 0.005, alpha = 0.2, colour = "#DB0908") +
  geom_line(
    data = plotting_data, aes(x = ngram_common, y = preds),
    linewidth = 1, colour = "#DB0908"
  ) +
  labs(
    x = expression(paste("Common ", italic("n"), "-gram")),
    y = NULL
  ) +
  theme(axis.text.y = element_text(size = 0)) +
  theme(plot.margin = margin(5, 10, 5, 10, "pt")) +
  theme_minimal()

log_ngenus_plot <- ggplot(cleaned_species_data, aes(
  x = log(ngenus),
  y = listed
)) +
  geom_jitter(width = 0, height = 0.005, alpha = 0.2, colour = "#2a7a3f") +
  geom_line(
    data = plotting_data, aes(x = log(ngenus), y = preds),
    linewidth = 1, colour = "#2a7a3f"
  ) +
  labs(
    x = "Genus Size (logged)",
    y = NULL
  ) +
  theme(axis.text.y = element_text(size = 0)) +
  theme(plot.margin = margin(5, 10, 5, 10, "pt")) +
  theme_minimal()

# combine plots using the patchwork package
combined_plots <- ngram_science_plot + ngram_common_plot + log_ngenus_plot
combined_plots <- combined_plots + plot_layout(ncol = 3)

# print the combined plot
print(combined_plots)

#### Lint and style the code ####
lint(filename = here("scripts/05-explore_data_model.R"))
style_file(path = here("scripts/05-explore_data_model.R"))
