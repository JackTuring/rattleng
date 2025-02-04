/// Widget to configure the BOOST tab: button.
///
/// Copyright (C) 2023-2024, Togaware Pty Ltd.
///
/// License: GNU General Public License, Version 3 (the "License")
/// https://www.gnu.org/licenses/gpl-3.0.en.html
//
// Time-stamp: <Monday 2025-02-03 16:05:12 +1100 Graham Williams>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rattle/constants/spacing.dart';
import 'package:rattle/features/boost/settings.dart';
import 'package:rattle/providers/boost.dart';
import 'package:rattle/providers/evaluate.dart';
import 'package:rattle/providers/page_controller.dart';
import 'package:rattle/r/source.dart';
import 'package:rattle/utils/get_target.dart';
import 'package:rattle/widgets/activity_button.dart';
import 'package:rattle/widgets/choice_chip_tip.dart';

/// The BOOST tab config currently consists of just an ACTIVITY button.
///
/// This is a StatefulWidget to pass the ref across to the rSource.

class BoostConfig extends ConsumerStatefulWidget {
  const BoostConfig({super.key});

  @override
  ConsumerState<BoostConfig> createState() => BoostConfigState();
}

class BoostConfigState extends ConsumerState<BoostConfig> {
  Map<String, String> boostAlgorithm = {
    'Extreme': '''

      A highly efficient gradient boosting algorithm designed for large-scale
      and complex data.

      ''',
    'Adaptive': '''

      A boosting algorithm that builds a strong classifier by iteratively
      combining weak learners, focusing on errors.

      ''',
  };

  @override
  Widget build(BuildContext context) {
    String algorithm = ref.read(algorithmBoostProvider.notifier).state;

    return Column(
      spacing: configRowSpace,
      children: [
        configTopGap,
        Row(
          spacing: configWidgetSpace,
          children: [
            configLeftGap,
            ActivityButton(
              pageControllerProvider: boostPageControllerProvider,
              tooltip: '''

              Tap here to build the $algorithm Boosted model using the parameter
              values set here.

              ''',
              onPressed: () async {
                // Run the R scripts.

                String mt = 'model_template';
                String mbx = 'model_build_xgboost';
                String mba = 'model_build_adaboost';

                if (algorithm == 'Extreme') {
                  await rSource(context, ref, [mt, mbx]);
                  ref.read(xgBoostEvaluateProvider.notifier).state = true;
                } else {
                  await rSource(context, ref, [mt, mba]);
                  ref.read(adaBoostEvaluateProvider.notifier).state = true;
                }

                // Update the state to make the boost evaluate tick box
                // automatically selected after the model build.

                ref.read(boostEvaluateProvider.notifier).state = true;
              },
              child: const Text('Build Boosted Trees'),
            ),
            Text('Target: ${getTarget(ref)}'),
            ChoiceChipTip<String>(
              options: boostAlgorithm.keys.toList(),
              selectedOption: algorithm,
              tooltips: boostAlgorithm,
              onSelected: (chosen) {
                setState(() {
                  if (chosen != null) {
                    algorithm = chosen;
                    ref.read(algorithmBoostProvider.notifier).state = chosen;
                  }
                });
              },
            ),
          ],
        ),
        BoostSettings(algorithm: algorithm),
      ],
    );
  }
}
