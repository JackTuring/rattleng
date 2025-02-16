# Use `actual_va` and `probability` for David Hand's classifier evaluation.
#
# Copyright (C) 2025, Togaware Pty Ltd.
#
# License: GNU General Public License, Version 3 (the "License")
# https://www.gnu.org/licenses/gpl-3.0.en.html
#
# Time-stamp: <Sunday 2025-02-02 14:53:49 +1100 Graham Williams>
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

# <TIMESTAMP>
#
# References:
#
# @williams:2017:essentials Chapter 7.
# https://survivor.togaware.com/datascience/ for further details.

# Evaluate the model using HMeasure.

results <- hmeasure::HMeasure(true.class=actual_va, scores=probability)

# Create a single SVG file that displays all 4 plots.

svg(filename = glue("<TEMPDIR>/model_evaluate_hand_{mtype}_{dtype}.svg"),
    width    = 11,
    height   = 8)

# Set up a 2x2 layout.

par(mfrow=c(2, 2))

# Generate the four plots within one device.

hmeasure::plotROC(results, which=1)
hmeasure::plotROC(results, which=2)
hmeasure::plotROC(results, which=3)
hmeasure::plotROC(results, which=4)

dev.off()
