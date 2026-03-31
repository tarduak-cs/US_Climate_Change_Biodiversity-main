# ESA Listing of Endangered Species in the Context of Climate Change

## Overview

This repo contains the data, `R` scripts and final `PDF` report used to in a replication of Moore et al.'s "Noah’s Ark in a Warming World: Climate Change, Biodiversity Loss, and Public Adaptation Costs in the United States" (2020), published in the *Journal of the Association of Environmental and Resource Economists*. This paper reproduces and extends three of its research claims as to the main determinants of actual U.S. government decisions about the listing of endangered species under the Endangered Species Act (ESA). It also extends the discussion, by providing some secondary research to estimate how species listing will evolve over the 21st century due to climate change, regarded as the most serious and persistent threat to biodiversity.

A minimal replication using the Social Science Reproduction Platform was also produced at the following link: https://doi.org/10.48152/ssrp-tpay-ac71.

Link to the original paper: https://www.journals.uchicago.edu/doi/10.1086/716662 

## File Structure

The repo is structured as:

-   `data/raw_data` contains the raw data, obtained from Moore et al.'s replication package, available at the link: https://dataverse.harvard.edu/file.xhtml?fileId=4931734&version=1.0, 
-   `data/analysis_data` contains the cleaned dataset that was constructed for this analysis,
-   `model` contains the fitted logistic regression model, 
-   `other` contains relevant details about LLM chat interactions, sketches and a supplemental datasheet for the cleaned dataset constructed for this analysis,  
-   `paper` contains the files used to generate the paper, including the Quarto document and reference bibliography file, as well as the PDF of the paper, 
-   `scripts` contains the R scripts used to simulate (`00-simulate_data.R`), download (`01-download_data.R`), clean (`02-data_cleaning.R`), test (`03-test_data.R`), model (`04-model_data.R`) and explore (`05-explore_data_model`) the data (and model), as well as to replicate the important figures from the original paper (`99-replications.R`). 

## Statement on LLM usage

No auto-complete tools such as GitHub Copilot were used in the course of this project. However, parts of the code and sections of the paper were written with the help of CHATGPT-3.5 and the entire chat history can be found in `inputs/llm/usage.txt`. 
