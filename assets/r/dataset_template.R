# Rattle Scripts: Dataset template variables are initialised after dataset prep.
#
# Copyright (C) 2023-2024, Togaware Pty Ltd.
#
# License: GNU General Public License, Version 3 (the "License")
# https://www.gnu.org/licenses/gpl-3.0.en.html
#
# Time-stamp: <Thursday 2025-02-06 20:38:37 +1100 Graham Williams>
#
# Licensed under the GNU General Public License, Version 3 (the "License");
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <https://www.gnu.org/licenses/>.
#
# Author: Graham Williams, Yixiang Yin

# <TIMESTAMP>
#
# Run this after the variable `ds` (dataset) has been loaded into
# Rattle and the dataset cleansed and prepared with roles
# assigned. The actions here in `dataset_template.R` will also setup
# the data after a dataset has changed, which may be called after, for
# example, a <TRANSFORM>.
#
# References:
#
# @williams:2017:essentials Chapter 3
#
# https://survivor.togaware.com/datascience/data-template.html

library(dplyr)        # Wrangling: select() sample_frac().
library(janitor)      # Cleanup: clean_names().

## # Index the original variable names by the new names.
##
## names(vnames) <- names(ds)
##
## # Display the list of vars.
##
## names(ds)

# Filter the variables in the dataset that are factors or ordered
# factors with more than 20 levels.

large_factors <- sapply(ds, is_large_factor)

# Get the names of those variables.

large_factor_vars <- names(large_factors)[large_factors]

# Print the variable names.

large_factor_vars

# Identify variable roles. The identifier is usually the first
# variable in the dataset that looks like an ID whilst all are
# recoreded in identifiers. Association rules, for example, use
# identifier, whilst we use identifiers to ignore columns from the
# list of inputs from the dataset used for model building.

target      <- <TARGET_VAR>
risk        <- <RISK_VAR>
identifier  <- <IDENT_VAR>
identifiers <- <IDENT_VARS>
ignore      <- <IGNORE_VARS>

## 20240829 gjw Ideally remove the ignored variables from ds for now as
## a bug fix to support the CORRELATION feature for selected
## variables. In future this dataset template will reload the dataset
## into ds from `get(dsname)` each time it is run afresh. FOR NOW do
## this for CORRELATION only.
##
## ds <- get(dsname)
## ds <- ds[setdiff(names(ds), ignore)]
##
##
##
# Record the number of observations.

nobs   <- nrow(ds)

# Note the variable names.

vars   <- names(ds)

# Make the target variable the last one.

vars   <- c(target, vars) %>% unique() %>% rev()

# Identify the input variables for modelling.

inputs <- setdiff(vars, target)  %>%
  setdiff(identifiers) %T>%
  print()

# Identify the numeric variables by name.

ds %>%
  select(-all_of(ignore)) %>%
  sapply(is.numeric) %>%
  which()  %>%
  names() %>%
  intersect(inputs) %T>%
  print() ->
numc

# Identify the categoric variables by name.

ds %>%
  select(-all_of(ignore)) %>%
  sapply(is.factor) %>%
  which() %>%
  names() %>%
  intersect(inputs) %T>%
  print() ->
catc

# Identify variables by name that have missing values.

missing <- colnames(ds)[colSums(is.na(ds)) > 0]

missing

# Identify the number of rows with missing values.

nmobs <- sum(apply(ds, 1, anyNA))

nmobs

## # 20240916 gjw This is required for building the ROLES table but
## # will eventually be replaced by the meta data.
##
## # 20241008 gjw I don't think these are required here now.
##
## # 20250205 gjw But they have been added into each of the transofrm
## # scripts so maybe it is just once here?
##
## # glimpse(ds)
## # summary(ds)
##
## # 20240814 gjw migrate to generating the meta data with rattle::meta_data(ds)
##
## # 20241008 gjw I think we now move this to PREP rather than
## # here. 20241212 gjw However this is required to update the <DATASET>
## # view of the data, particularly after a <TRANSFORM>. So add it back in
## # here. Without this the <DATASET> will not show that an imputed
## # IMN_rainfull, for example, has 54 unique values (it is 0 when
## # IMN_rainfall does not appear in metaData).

# Report on the meta data for `ds`.

meta_data(ds)
##
## # Filter the variables in the dataset that are factors or ordered
## # factors with more than 20 levels.
##
## # large_factors <- sapply(ds, is_large_factor)
##
## # Get the names of those variables.
##
## # large_factor_vars <- names(large_factors)[large_factors]
##
## # Print the variable names.
##
## # large_factor_vars

# Convert frequency table of target variable to numeric vector.
# It is used to check validation of sample size in building model rforest.

as.numeric(table(ds[[target]]))

split <- c(<DATA_SPLIT_TR_TU_TE>)


# Calculates the ceiling of the class frequencies multiplied by the split ratio.
# Returns integer values rounded up to ensure all classes are represented.

floor(as.numeric(table(ds[[target]])) * split[1])
