# From dataset `tcds` build a `glm()` linear model.
#
# Copyright (C) 2024-2025, Togaware Pty Ltd.
#
# License: GNU General Public License, Version 3 (the "License")
# https://www.gnu.org/licenses/gpl-3.0.en.html
#
# Time-stamp: <Friday 2025-01-24 12:27:22 +1100 Graham Williams>
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
# Author: Zheyuan Xu, Graham Williams

# TIMESTAMP
#
# References:
#
# @williams:2017:essentials.
# https://survivor.togaware.com/datascience/ for further details.

# Define model type and description to be used in following R scripts.

mtype <- "linear"
mdesc <- "Linear Model"

# Train a logistic regression model.

model_glm <- glm(
  form,
  data   = trds,
  family = binomial(link = <LINEAR_FAMILY>),
)

# Output a textual view of the model for review.

print(summary(model_glm))

# Output additional model statistics for review.

cat(sprintf("Log likelihood: %.3f (%d df)\n",
            logLik(model_glm)[1],
            attr(logLik(model_glm), "df")))

cat(sprintf("Null/Residual deviance difference: %.3f (%d df)\n",
            model_glm$null.deviance - model_glm$deviance,
            model_glm$df.null - model_glm$df.residual))

cat(sprintf("Pseudo R-Square (optimistic): %.8f\n",
             cor(model_glm$y, model_glm$fitted.values)))

cat('\n==== <ANOVA> ====\n\n')
print(anova(model_glm, test = "Chisq"))
cat("\n")

# Display diagnostics the model for review.

svg("<TEMPDIR>/model_glm_diagnostic_plots.svg")
par(mfrow = c(2, 2))
plot(model_glm)
dev.off()
