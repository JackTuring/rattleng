/// Widget to configure the EVALUATE tab.
///
/// Copyright (C) 2024, Togaware Pty Ltd.
///
/// License: GNU General Public License, Version 3 (the "License")
/// https://www.gnu.org/licenses/gpl-3.0.en.html
//
// Time-stamp: <Wednesday 2025-02-12 10:24:37 +1100 Graham Williams>
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
/// Authors: Zheyuan Xu

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rattle/constants/spacing.dart';
import 'package:rattle/constants/style.dart';
import 'package:rattle/providers/evaluate.dart';
import 'package:rattle/providers/page_controller.dart';
import 'package:rattle/providers/partition.dart';
import 'package:rattle/providers/settings.dart';
import 'package:rattle/r/source.dart';
import 'package:rattle/utils/check_function_executed.dart';
import 'package:rattle/widgets/activity_button.dart';
import 'package:rattle/widgets/choice_chip_tip.dart';
import 'package:rattle/widgets/labelled_checkbox.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EvaluateConfig extends ConsumerStatefulWidget {
  const EvaluateConfig({super.key});

  @override
  ConsumerState<EvaluateConfig> createState() => EvaluateConfigState();
}

class EvaluateConfigState extends ConsumerState<EvaluateConfig> {
  final List<_ModelConfig> modelConfigs = [
    _ModelConfig(
      key: 'treeEvaluate',
      label: 'Tree',
      checkCommands: [
        ['print(model_rpart)', 'printcp(model_rpart)'],
        ['print(model_ctree)', 'summary(model_ctree)'],
      ],
      checkFiles: [
        ['model_tree_rpart.svg'],
        ['model_tree_ctree.svg'],
      ],
      provider: treeEvaluateProvider,
    ),
    _ModelConfig(
      key: 'forestEvaluate',
      label: 'Forest',
      checkCommands: [
        ['print(model_conditionalForest)', 'print(importance_df)'],
        ['print(model_randomForest)', 'printRandomForests'],
      ],
      checkFiles: [
        ['model_conditional_forest.svg'],
        [
          'model_random_forest_varimp.svg',
          'model_random_forest_error_rate.svg',
          'model_random_forest_oob_roc_curve.svg',
        ],
      ],
      provider: forestEvaluateProvider,
    ),
    _ModelConfig(
      key: 'boostEvaluate',
      label: 'Boost',
      checkCommands: [
        ['print(model_ada)', 'summary(model_ada)'],
        ['print(model_xgb)', 'summary(model_xgb)'],
      ],
      checkFiles: [
        ['model_ada_boost.svg'],
        ['model_xgb_importance.svg'],
      ],
      provider: boostEvaluateProvider,
    ),
    _ModelConfig(
      key: 'svmEvaluate',
      label: 'SVM',
      checkCommands: [
        ['print(svm_model)'],
      ],
      checkFiles: [[]],
      provider: svmEvaluateProvider,
    ),
    _ModelConfig(
      key: 'linearEvaluate',
      label: 'Linear',
      checkCommands: [
        [
          'print(summary(model_glm))',
          'print(anova(model_glm, test = "Chisq"))',
        ],
      ],
      checkFiles: [
        ['model_glm_diagnostic_plots.svg'],
      ],
      provider: linearEvaluateProvider,
    ),
    _ModelConfig(
      key: 'neuralNetEvaluate',
      label: 'Neural',
      checkCommands: [
        ['print(model_neuralnet)', 'summary(model_neuralnet)'],
        ['print(model_nn)', 'summary(model_nn)'],
      ],
      checkFiles: [
        ['model_neuralnet.svg'],
        ['model_nn_nnet.svg'],
      ],
      provider: neuralEvaluateProvider,
    ),
    _ModelConfig(
      key: 'KMeansEvaluate',
      label: 'KMeans',
      checkCommands: [
        ['print(colMeans(tds))'],
      ],
      checkFiles: [
        ['model_cluster_discriminant.svg'],
      ],
      provider: kMeansEvaluateProvider,
    ),
    _ModelConfig(
      key: 'HClustEvaluate',
      label: 'HClust',
      checkCommands: [
        ['print("Within-Cluster Sum of Squares:")'],
      ],
      checkFiles: [
        ['model_cluster_hierarchical.svg'],
      ],
      provider: hClusterEvaluateProvider,
    ),
  ];

  Map<String, String> datasetTypes = {
    'Training': '''

    Evaluate the model using the **training** dataset.  This will give an
    optimistic estimate of the performance of the model since it is using the
    same data that trained the model to then test the model. It should do well.

    ''',
    'Tuning': '''

    Evaluate the model using the **tuning/validation** dataset.  This is used
    whilst the model parameters are still being tuned but not for the final
    unbiased estimate of error. This option is only available if partitioning is
    enabled in the Data tab and a tuning/validation dataset is specified.

    ''',
    'Testing': '''

    Evaluate the performance of the model over the **testing** dataset, which is
    the remainder of the dataset not used for training (and tuning), and so will
    provide an unbiased estimate. This option is only available if partitioning
    is enabled in the Data tab and a testing dataset is specified.

    ''',
    'Complete': '''

    Evaluate the performance on the **complete** dataset.

    ''',
  };

  bool _isEvaluationEnabled(_ModelConfig config) {
    for (var i = 0; i < config.checkCommands.length; i++) {
      if (checkFunctionExecuted(
        ref,
        config.checkCommands[i],
        config.checkFiles[i],
      )) {
        return true;
      }
    }

    return false;
  }

  /// Executes model evaluation based on the given parameters and conditions.
  ///
  /// [executed] - Boolean indicating if the model evaluation should proceed.
  /// [parameters] - List of parameters specific to the model.
  /// [datasetSplitType] - String indicating the dataset split type ('Training', 'Tuning', etc.).
  /// [context] - Build context for the operation.
  /// [ref] - Reference used in the evaluation (e.g., for dependency injection).

  Future<void> executeEvaluation({
    required bool executed,
    required List parameters,
    required String datasetSplitType,
    required BuildContext context,
    required dynamic ref,
  }) async {
    // 20241220 gjw One of the following templates then needs to be
    // run to convert the appropriate predictions and probabilities
    // to the variables that are non-specific to a dataset
    // partition.

    final templateMap = {
      'Training': 'evaluate_template_tr',
      'Tuning': 'evaluate_template_tu',
      'Validation': 'evaluate_template_tu',
      'Testing': 'evaluate_template_te',
      'Complete': 'evaluate_template_tc',
    };

    if (executed) {
      final template = templateMap[datasetSplitType] ??
          (throw Exception('Invalid datasetSplitType: $datasetSplitType'));

      // Insert 'template' as the second item in the parameters list.

      final selectedParameters = [
        parameters.first,
        template,
        ...parameters.skip(1),
      ];

      await rSource(context, ref, selectedParameters.cast<String>());
    }
  }

  // Load settings from shared preferences and update providers.

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Load useValidation setting from shared preferences.

    ref.read(useValidationSettingProvider.notifier).state =
        prefs.getBool('useValidation') ?? false;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    String datasetType = ref.watch(datasetTypeProvider.notifier).state;

    return Column(
      spacing: configRowSpace,
      children: [
        // 20241215 gjw Add comment into this file here to force the automatic
        // code formatter to allow empty lines between widgets.

        configTopGap,

        Row(
          spacing: configWidgetSpace,
          children: [
            // 20241215 gjw Add comment to allow empty lines between widgets.

            configLeftGap,

            ActivityButton(
              pageControllerProvider: evaluatePageControllerProvider,
              onPressed: () async {
                // Retrieve the boolean state indicating if the evaluation was executed.

                bool adaBoostExecuted = ref.watch(adaBoostEvaluateProvider);
                bool boostTicked = ref.watch(boostEvaluateProvider);
                bool conditionalForestExecuted =
                    ref.watch(conditionalForestEvaluateProvider);
                bool ctreeExecuted = ref.watch(cTreeEvaluateProvider);
                String datasetSplitType = ref.watch(datasetTypeProvider);
                bool forestTicked = ref.watch(forestEvaluateProvider);
                bool linearExecuted = ref.watch(linearEvaluateProvider);
                bool nnetExecuted = ref.watch(nnetEvaluateProvider);
                bool neuralNetExecuted = ref.watch(neuralNetEvaluateProvider);
                bool neuralTicked = ref.watch(neuralEvaluateProvider);
                bool randomForestExecuted =
                    ref.watch(randomForestEvaluateProvider);
                bool rpartExecuted = ref.watch(rpartTreeEvaluateProvider);
                bool svmExecuted = ref.watch(svmEvaluateProvider);
                bool treeExecuted = ref.watch(treeEvaluateProvider);
                bool xgBoostExecuted = ref.watch(xgBoostEvaluateProvider);

                // 20241220 gjw Identify constants corresponding to the various
                // evaluation commands for each model to generate the required
                // TEMPLATE variables. This is being updated to use the TEMPLATE
                // variables one model at a time. Those that have _model_ are
                // updated.

                String ea = 'evaluate_model_adaboost';
                String ec = 'evaluate_model_ctree';
                String el = 'evaluate_model_linear';
                String en = 'evaluate_model_nnet';
                String er = 'evaluate_model_rpart';
                String es = 'evaluate_model_svm';
                String ex = 'evaluate_model_xgboost';
                String ent = 'evaluate_model_neuralnet';

                String ecf = 'evaluate_model_cforest';
                String erf = 'evaluate_model_rforest';

                // 20241220 gjw Finally we will run the generic templates for
                // the various performance measures.

                String em = 'evaluate_measure_error_matrix';
                String ro = 'evaluate_measure_roc';
                String erc = 'evaluate_measure_riskchart';
                String hd = 'evaluate_measure_hand';

                // Execute evaluation for rpart model if it was executed and treeExecuted is true.

                await executeEvaluation(
                  executed: rpartExecuted && treeExecuted,
                  parameters: [er, em, ro, erc, hd],
                  datasetSplitType: datasetSplitType,
                  context: context,
                  ref: ref,
                );

                // Execute evaluation for ctree model if it was executed and treeExecuted is true.

                await executeEvaluation(
                  executed: ctreeExecuted && treeExecuted,
                  parameters: [ec, em, ro, erc, hd],
                  datasetSplitType: datasetSplitType,
                  context: context,
                  ref: ref,
                );

                // Execute evaluation for Random Forest model if executed and forest box is ticked.

                await executeEvaluation(
                  executed: randomForestExecuted && forestTicked,
                  parameters: [erf, em, ro, erc, hd],
                  datasetSplitType: datasetSplitType,
                  context: context,
                  ref: ref,
                );

                // Execute evaluation for Conditional Forest model if executed and forest box is ticked.

                await executeEvaluation(
                  executed: conditionalForestExecuted && forestTicked,
                  parameters: [ecf, em, ro, erc, hd],
                  datasetSplitType: datasetSplitType,
                  context: context,
                  ref: ref,
                );

                // Execute evaluation for AdaBoost model if executed and boost box is ticked.

                await executeEvaluation(
                  executed: adaBoostExecuted && boostTicked,
                  parameters: [ea, em, ro, erc, hd],
                  datasetSplitType: datasetSplitType,
                  context: context,
                  ref: ref,
                );

                // Execute evaluation for XGBoost model if executed and boost box is ticked.

                await executeEvaluation(
                  executed: xgBoostExecuted && boostTicked,
                  parameters: [ex, em, ro, erc, hd],
                  datasetSplitType: datasetSplitType,
                  context: context,
                  ref: ref,
                );

                // Execute evaluation for SVM model if executed.

                await executeEvaluation(
                  executed: svmExecuted,
                  parameters: [es, em, ro, erc, hd],
                  datasetSplitType: datasetSplitType,
                  context: context,
                  ref: ref,
                );

                // Execute evaluation for linear model if executed.

                await executeEvaluation(
                  executed: linearExecuted,
                  parameters: [el, em, ro, erc, hd],
                  datasetSplitType: datasetSplitType,
                  context: context,
                  ref: ref,
                );

                // Execute evaluation for Neural Network model if executed and neural network box is ticked.

                await executeEvaluation(
                  executed: neuralTicked && nnetExecuted,
                  parameters: [en, em, ro, erc, hd],
                  datasetSplitType: datasetSplitType,
                  context: context,
                  ref: ref,
                );

                // Execute evaluation for Neural Net model if executed and neural network box is ticked.

                await executeEvaluation(
                  executed: neuralTicked && neuralNetExecuted,
                  parameters: [ent, em, ro, erc, hd],
                  datasetSplitType: datasetSplitType,
                  context: context,
                  ref: ref,
                );

                await ref.read(evaluatePageControllerProvider).animateToPage(
                      // Index of the second page.
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
              },
              child: const Text('Evaluate'),
            ),

            const Text('Model:', style: normalTextStyle),
            ...modelConfigs.map((config) {
              bool enabled = _isEvaluationEnabled(config);

              String buildMsg = enabled
                  ? ''
                  : ' You will need to build a ${config.label} model '
                      'before you can evaluate it. '
                      'Visit the **Model** tab to do so.';

              return Row(
                children: [
                  LabelledCheckbox(
                    key: Key(config.key),
                    tooltip: 'Evaluate the performace of any '
                        '**${config.label}** model(s).$buildMsg',
                    label: config.label,
                    provider: config.provider,
                    enabled: enabled,
                    onSelected: (ticked) {
                      setState(() {
                        if (ticked != null) {
                          ref.read(config.provider.notifier).state = ticked;
                        }
                      });
                    },
                  ),
                ],
              );
            }).toList(),
          ],
        ),

        Row(
          spacing: configWidgetSpace,
          children: [
            configLeftGap,
            Text('Evaluation Dataset: '),
            // Widget to display dataset type selection as choice chips with tooltips.

            ChoiceChipTip<String>(
              // Generate list of dataset type options, filtering based on partition toggles.

              options: datasetTypes.keys
                  .where(
                    (key) => ref.read(partitionProvider) || key == 'Complete',
                  )
                  .map(
                    (key) => key == 'Tuning' &&
                            ref.watch(useValidationSettingProvider)
                        ? 'Validation'
                        : key,
                  )
                  .toList(),
              // Set selected option, handling Tuning/Validation text swap and defaulting to Complete when partitions disabled.

              selectedOption: !ref.read(partitionProvider)
                  ? 'Complete'
                  : (datasetType == 'Tuning' &&
                          ref.watch(useValidationSettingProvider)
                      ? 'Validation'
                      : datasetType),
              // Create tooltips map, replacing 'Tuning' key with 'Validation'
              // when validation is enabled and filtering based on partition setting.

              tooltips: Map.fromEntries(
                datasetTypes.entries
                    .where(
                      (entry) =>
                          ref.read(partitionProvider) ||
                          entry.key == 'Complete',
                    )
                    .map(
                      (entry) => MapEntry(
                        entry.key == 'Tuning' &&
                                ref.watch(useValidationSettingProvider)
                            ? 'Validation'
                            : entry.key,
                        entry.value,
                      ),
                    ),
              ),
              // Handle selection changes by updating state and provider.

              onSelected: (chosen) {
                setState(() {
                  if (chosen != null) {
                    datasetType = chosen;
                    ref.read(datasetTypeProvider.notifier).state = chosen;
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _ModelConfig {
  final String key;
  final String label;
  final List<List<String>> checkCommands;
  final List<List<String>> checkFiles;
  final StateProvider<bool> provider;

  const _ModelConfig({
    required this.key,
    required this.label,
    required this.checkCommands,
    required this.checkFiles,
    required this.provider,
  });
}
