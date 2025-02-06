/// Support for running an R script using R source().
///
// Time-stamp: <Friday 2025-02-07 05:21:20 +1100 Graham Williams>
///
/// Copyright (C) 2023-2025, Togaware Pty Ltd.
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
///
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
/// Authors: Graham Williams, Yixiang Yin, Zheyuan Xu, Kevin Wang

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rattle/providers/dataset.dart';

import 'package:universal_io/io.dart' show Platform;

import 'package:rattle/constants/temp_dir.dart';
import 'package:rattle/providers/association.dart';
import 'package:rattle/providers/boost.dart';
import 'package:rattle/providers/cleanse.dart';
import 'package:rattle/providers/cluster.dart';
import 'package:rattle/providers/complexity.dart';
import 'package:rattle/providers/evaluate.dart';
import 'package:rattle/providers/forest.dart';
import 'package:rattle/providers/group_by.dart';
import 'package:rattle/providers/imputed.dart';
import 'package:rattle/providers/interval.dart';
import 'package:rattle/providers/ignore_missing_group_by.dart';
import 'package:rattle/providers/linear.dart';
import 'package:rattle/providers/loss_matrix.dart';
import 'package:rattle/providers/max_depth.dart';
import 'package:rattle/providers/neural.dart';
import 'package:rattle/providers/number.dart';
import 'package:rattle/providers/min_bucket.dart';
import 'package:rattle/providers/min_split.dart';
import 'package:rattle/providers/normalise.dart';
import 'package:rattle/providers/partition.dart';
import 'package:rattle/providers/path.dart';
import 'package:rattle/providers/priors.dart';
import 'package:rattle/providers/pty.dart';
import 'package:rattle/providers/selected.dart';
import 'package:rattle/providers/selected2.dart';
import 'package:rattle/providers/settings.dart';
import 'package:rattle/providers/summary_crosstab.dart';
import 'package:rattle/providers/svm.dart';
import 'package:rattle/providers/tree_include_missing.dart';
import 'package:rattle/providers/vars/roles.dart';
import 'package:rattle/providers/visualise.dart';
import 'package:rattle/providers/wordcloud/checkbox.dart';
import 'package:rattle/providers/wordcloud/language.dart';
import 'package:rattle/providers/wordcloud/maxword.dart';
import 'package:rattle/providers/wordcloud/minfreq.dart';
import 'package:rattle/providers/wordcloud/punctuation.dart';
import 'package:rattle/providers/wordcloud/stem.dart';
import 'package:rattle/providers/wordcloud/stopword.dart';
import 'package:rattle/r/strip_comments.dart';
import 'package:rattle/r/strip_header.dart';
import 'package:rattle/r/strip_todo.dart';
import 'package:rattle/utils/debug_text.dart';
import 'package:rattle/utils/get_ignored.dart';
import 'package:rattle/utils/get_missing.dart';
import 'package:rattle/utils/set_status.dart';
import 'package:rattle/utils/timestamp.dart';
import 'package:rattle/utils/to_r_vector.dart';
import 'package:rattle/utils/update_script.dart';

/// Run the R [script] and append to the [rattle] script.
///
/// Various PARAMETERS that are found in the R script will be replaced with
/// actual values before the code is run. An early approach was to wrap the
/// PARAMETERS within angle brackets, as in `<PARAMETERS`> but then the R
/// scripts do not run standalone. Whlist it did ensure the parameters were
/// properly mapped, it is useful to be able to run the scripts as is outside of
/// rattleNG. So decided to remove the angle brackets. The scripts still can not
/// tun standalone as such since they will have undefined vairables, but we can
/// define the variables and then run the scripts.
///

Future<void> rSource(
  BuildContext context,
  WidgetRef ref,
  List<String> scripts,
) async {
  // Initialise the state variables obtained from the different providers.

  // TODO 20250131 gjw MIGRATE TO NOT CACHE THE VALUES HERE
  //
  // Instead directly use ref.read() later as with neuralMaxWeightsProvider.

  int randomSeedSetting = ref.read(randomSeedSettingProvider);
  bool randomPartitionSetting = ref.read(randomPartitionSettingProvider);

  bool checkbox = ref.read(checkboxProvider);
  bool cleanse = ref.read(cleanseProvider);
  bool normalise = ref.read(normaliseProvider);
  bool partition = ref.read(partitionProvider);
  bool punctuation = ref.read(punctuationProvider);
  bool stem = ref.read(stemProvider);
  bool stopword = ref.read(stopwordProvider);

  String groupBy = ref.read(groupByProvider);
  String imputed = ref.read(imputedProvider);
  String language = ref.read(languageProvider);
  String maxWord = ref.read(maxWordProvider);
  String minFreq = ref.read(minFreqProvider).toString();
  String path = ref.read(pathProvider);
  String selected = ref.read(selectedProvider);
  String selected2 = ref.read(selected2Provider);

  int minSplit = ref.read(minSplitProvider);
  int maxDepth = ref.read(maxDepthProvider);

  String priors = ref.read(priorsProvider);
  bool includingMissing = ref.read(treeIncludeMissingProvider);
  bool nnetTrace = ref.read(traceNeuralProvider);
  bool nnetSkip = ref.read(neuralSkipProvider);
  bool neuralIgnoreCategoric = ref.read(ignoreCategoricNeuralProvider);
  int minBucket = ref.read(minBucketProvider);
  double complexity = ref.read(complexityProvider);
  String lossMatrix = ref.read(lossMatrixProvider);
  List<double> partitionRatios = ref.read(partitionSettingProvider);
  String partitionString =
      '${partitionRatios.first}, ${partitionRatios[1]}, ${partitionRatios.last}';

  // ASSOCIATION

  bool associationBaskets = ref.read(basketsAssociationProvider);
  double associationSupport = ref.read(supportAssociationProvider);
  double associationConfidence = ref.read(confidenceAssociationProvider);
  int associationMinLength = ref.read(minLengthAssociationProvider);
  int associationInterestMeasureLimit =
      ref.read(interestMeasuresAssociationProvider);
  String associationRulesSortBy =
      ref.read(sortByAssociationProvider).toLowerCase();

  // BOOST

  int boostMaxDepth = ref.read(maxDepthBoostProvider);
  int boostMinSplit = ref.read(minSplitBoostProvider);
  int boostXVal = ref.read(xValueBoostProvider);
  int boostThreads = ref.read(threadsBoostProvider);
  int boostIterations = ref.read(iterationsBoostProvider);
  double boostLearningRate = ref.read(learningRateBoostProvider);
  double boostComplexity = ref.read(complexityBoostProvider);
  String boostObjective = ref.read(objectiveBoostProvider);

  // CLUSTER

  int clusterNum = ref.read(numberClusterProvider);
  int clusterRun = ref.read(runClusterProvider);
  int clusterProcessor = ref.read(processorClusterProvider);
  bool clusterReScale = ref.read(reScaleClusterProvider);
  String clusterDistance = ref.read(distanceClusterProvider);
  String clusterLink = ref.read(linkClusterProvider);
  String clusterType = ref.read(typeClusterProvider);

  // EVALUATE

  String chosenDataType = ref.read(datasetTypeProvider);

  // FOREST

  int forestTrees = ref.read(treeNumForestProvider);
  String? forestSampleSize = ref.read(forestSampleSizeProvider);
  int forestPredictorNum = ref.read(predictorNumForestProvider);
  int forestNo = ref.read(treeNoForestProvider);
  bool forestImpute = ref.read(imputeForestProvider);

  // LINEAR

  String linearFamily = ref.read(familyLinearProvider).toLowerCase();

  // NEURAL

  double neuralThreshold = ref.read(thresholdNeuralProvider);

  int hiddenLayerSizes = ref.read(hiddenLayerNeuralProvider);
  int neuralStepMax = ref.read(stepMaxNeuralProvider);
  int nnetMaxit = ref.read(maxitNeuralProvider);

  String hiddenNeurons = ref.read(hiddenLayersNeuralProvider);
  String neuralActivationFct = ref.read(activationFctNeuralProvider);
  String neuralErrorFct = ref.read(errorFctNeuralProvider);

  // SETTINGS

  bool useValidation = ref.read(useValidationSettingProvider);

  String theme = ref.read(settingsGraphicThemeProvider);

  // SVM

  RegExp regex = RegExp(r'\(([^)]+)\)');
  String svmKernelItem = ref.read(kernelSVMProvider);
  final match = regex.firstMatch(svmKernelItem);
  String svmKernel = match != null ? match.group(1)! : '';

  int svmDegree = ref.read(degreeSVMProvider);

  // VISUAL

  bool ignoreMissingGroupBy = ref.read(ignoreMissingGroupByProvider);
  bool exploreVisualBoxplotNotch = ref.read(exploreVisualBoxplotNotchProvider);

  int interval = ref.read(intervalProvider);

  // First obtain the text from each script and combine.

  String code = '';
  String newCode = '';

  for (String script in scripts) {
    debugText('R SOURCE', '$script.R');

    String asset = 'assets/r/$script.R';

    newCode = await DefaultAssetBundle.of(context).loadString(asset);
    newCode = rStripHeader(newCode);
    newCode = rStripTodo(newCode);
    newCode = "\n${'#' * 72}\n## -- $script.R --\n${'#' * 72}\n$newCode";

    code += newCode;
  }

  ////////////////////////////////////////////////////////////////////////
  // GLOBAL
  //
  // Replace Global template patterns with their values. These are not specific
  // to any particular feature,

  code = code.replaceAll('<TIMESTAMP>', 'RattleNG ${timestamp()}');

  PackageInfo info = await PackageInfo.fromPlatform();

  code = code.replaceAll('<VERSION>', info.version);

  // 20240825 lutra Fix the path to the dataset to ensure that the Windows path
  // has been correctly converted to a Unix path for R.

  if (Platform.isWindows) {
    path = path.replaceAll(r'\', '/');
  }
  code = code.replaceAll('<FILENAME>', path);

  code = code.replaceAll('<TEMPDIR>', tempDir);

  String package = ref.read(packageProvider);
  code = code.replaceAll('<PACKAGE>', package);

  String dataset = ref.read(datasetProvider);
  code = code.replaceAll('<DATASET>', dataset);

  ////////////////////////////////////////////////////////////////////////
  // SETTINGS

  // TODO 20240916 gjw VALUE OF MAXFACTOR NEEDS TO COME FROM SETTINGS.

  code = code.replaceAll('<MAXFACTOR>', '20');

  code = code.replaceAll(
    '<RANDOM_PARTITION>',
    randomPartitionSetting.toString().toUpperCase(),
  );
  code = code.replaceAll('<RANDOM_SEED>', randomSeedSetting.toString());

  code = code.replaceAll('<SETTINGS_GRAPHIC_THEME>', theme);

  code =
      code.replaceAll('<TUNING_TYPE>', useValidation ? 'validation' : 'tuning');

  ////////////////////////////////////////////////////////////////////////
  // DATASET ROLES
  //
  // The `roles` Provider lists the roles for the different variables which we
  // need to know for parsing the R scripts.

  Map<String, Role> roles = ref.read(rolesProvider);

  // Initialise the different roles for the global dataset variables.

  String target = 'NULL'; // 20250202 gjw Required for predictive models.
  String risk = 'NULL'; // 20250202 gjw Optional for predictive models.

  // TARGET

  // Extract the target variable from the rolesProvider.

  roles.forEach((key, value) {
    if (value == Role.target) {
      target = key;
    }
  });

  // 20250202 gjw If the target is NULL (no target has been identified) then we
  // need to ensure expressions in the R code like
  //
  // target <- <TARGET_VAR>
  //
  // becomes
  //
  // target <- NULL
  //
  // otherwise
  //
  // target <- "rain_tomorrow"
  //
  // A naive approach ends up with "NULL" as the variable called NULL rather
  // than being NULL. We handle this special case and then replace any other
  // TARGET_VAR replacement as usual.

  code = code.replaceAll(
    '<TARGET_VAR>',
    target == 'NULL' ? 'NULL' : '"$target"',
  );

  //code = code.replaceAll('<TARGET_VAR>', ref.read(rolesProvider));

  // RISK

  // Extract the risk variable from the rolesProvider and use that for now as
  // the variable to visualise.

  roles.forEach((key, value) {
    if (value == Role.risk) {
      risk = key;
    }
  });

  code = code.replaceAll(
    '<RISK_VAR>',
    risk == 'NULL' ? 'NULL' : '"$risk"',
  );

  // IDENTIFIERS

  // 20250202 gjw If we need a single identifier then take the first one
  // available.

  String ident = 'NULL'; // 20250202 gjw Used in associations.

  roles.forEach((key, value) {
    if (ident == 'NULL' && value == Role.ident) {
      ident = key;
    }
  });

  code = code.replaceAll('<IDENT_VAR>', ident == 'NULL' ? 'NULL' : '"$ident"');

  // 20250206 gjw If we need to identify all identifiers then build the list.

  String idents = '';

  roles.forEach((key, value) {
    if (value == Role.ident) {
      idents = '$idents${idents.isNotEmpty ? ", " : ""}"$key"';
    }
  });

  code = code.replaceAll('<IDENT_VARS>', idents == '' ? 'NULL' : 'c($idents)');

  // IGNORED

  List<String> ignoredVars = getIgnored(ref);
  String ignoredVarsString = toRVector(ignoredVars);
  code = code.replaceAll('<IGNORE_VARS>', ignoredVarsString);

  List<String> result = getMissing(ref);
  code = code.replaceAll('<MISSING_VARS>', toRVector(result));

  ////////////////////////////////////////////////////////////////////////
  // BOOST

  code = code.replaceAll('<BOOST_MAX_DEPTH>', boostMaxDepth.toString());
  code = code.replaceAll('<BOOST_MIN_SPLIT>', boostMinSplit.toString());
  code = code.replaceAll('<BOOST_X_VALUE>', boostXVal.toString());
  code = code.replaceAll('<BOOST_LEARNING_RATE>', boostLearningRate.toString());
  code = code.replaceAll('<BOOST_COMPLEXITY>', boostComplexity.toString());
  code = code.replaceAll('<BOOST_THREADS>', boostThreads.toString());
  code = code.replaceAll('<BOOST_ITERATIONS>', boostIterations.toString());
  code = code.replaceAll('<BOOST_OBJECTIVE>', '"$boostObjective"');

  ////////////////////////////////////////////////////////////////////////

  // LINEAR

  code = code.replaceAll('<LINEAR_FAMILY>', '"$linearFamily"');

  // NEEDS_INIT is true for Windows as main.R does not get run on startup on
  // Windows.

  // String needsInit = 'FALSE';
  // if (Platform.isWindows) needsInit = 'TRUE';

  // code = code.replaceAll('<NEEDS_INIT>', needsInit);

  // Do we split the dataset? The option is presented on the DATASET GUI, and if
  // set we split the dataset.

  // TODO if (script.contains('^dataset_')) {

  // Do we split the dataset? The option is presented on the DATASET GUI, and if
  // set we split the dataset.

  code = code.replaceAll('<SPLIT_DATASET>', partition ? 'TRUE' : 'FALSE');

  // Do we want to normalise the dataset? The option is presented on the DATASET
  // GUI, and if set we normalise the dataset's variable names.

  code = code.replaceAll('<NORMALISE_NAMES>', normalise ? 'TRUE' : 'FALSE');

  // Do we want to cleanse the dataset? The option is presented on the DATASET
  // GUI, and if it is set we will cleanse the dataset columns.

  code = code.replaceAll('<CLEANSE_DATASET>', cleanse ? 'TRUE' : 'FALSE');

  code = code.replaceAll('<INTERVAL>', interval.toString());
  code = code.replaceAll('<NUMBER>', ref.read(numberProvider).toString());
  code = code.replaceAll('<SELECTED_VAR>', selected);

  code = code.replaceAll('<SELECTED_2_VAR>', selected2);

  code =
      code.replaceAll('<GROUP_BY_VAR>', groupBy == 'None' ? 'NULL' : groupBy);

  code = code.replaceAll('<IMPUTED_VALUE>', imputed);

  // Replace DATA_SPLIT_TR_TU_TE with the current values from partitionSettingProvider.

  code = code.replaceAll('<DATA_SPLIT_TR_TU_TE>', partitionString);

  // TODO if (script == 'model_build_rpart')) {

  // TODO 20231016 gjw THESE SHOULD BE SET IN THE MODEL TAB AND ARE THEN
  // REPLACED WITHING model_build_rpart.R

  code = code.replaceAll(
    ' <PRIORS>',
    priors.isNotEmpty ? ', prior = c($priors)' : '',
  );
  code = code.replaceAll(
    ' <LOSS>',
    lossMatrix.isNotEmpty ? ', loss = matrix(c($lossMatrix))' : '',
  );
  code = code.replaceAll(' <MAXDEPTH>', ' maxdepth = ${maxDepth.toString()}');
  code = code.replaceAll(' <MINSPLIT>', ' minsplit = ${minSplit.toString()}');
  code =
      code.replaceAll(' <MINBUCKET>', ' minbucket = ${minBucket.toString()}');
  code = code.replaceAll(' <CP>', ' cp = ${complexity.toString()}');

  ////////////////////////////////////////////////////////////////////////
  // ASSOCIATE

  code = code.replaceAll(
    '<ASSOCIATION_BASKETS>',
    associationBaskets ? 'TRUE' : 'FALSE',
  );
  code = code.replaceAll(
    '<ASSOCIATION_SUPPORT>',
    associationSupport.toString(),
  );
  code = code.replaceAll(
    '<ASSOCIATION_CONFIDENCE>',
    associationConfidence.toString(),
  );
  code = code.replaceAll(
    '<ASSOCIATION_MIN_LENGTH>',
    associationMinLength.toString(),
  );

  code = code.replaceAll(
    '<ASSOCIATION_INTEREST_MEASURE>',
    associationInterestMeasureLimit.toString(),
  );

  code = code.replaceAll(
    '<ASSOCIATION_RULES_SORT_BY>',
    '"$associationRulesSortBy"',
  );

  ////////////////////////////////////////////////////////////////////////

  // BOOST

  code = code.replaceAll('<BOOST_MAX_DEPTH>', boostMaxDepth.toString());
  code = code.replaceAll('<BOOST_MIN_SPLIT>', boostMinSplit.toString());
  code = code.replaceAll('<BOOST_X_VALUE>', boostXVal.toString());
  code = code.replaceAll('<BOOST_LEARNING_RATE>', boostLearningRate.toString());
  code = code.replaceAll('<BOOST_COMPLEXITY>', boostComplexity.toString());
  code = code.replaceAll('<BOOST_THREADS>', boostThreads.toString());
  code = code.replaceAll('<BOOST_ITERATIONS>', boostIterations.toString());
  code = code.replaceAll('<BOOST_OBJECTIVE>', '"$boostObjective"');

  ////////////////////////////////////////////////////////////////////////
  // CLUSTER

  code = code.replaceAll('<CLUSTER_NUM>', clusterNum.toString());
  code = code.replaceAll('<CLUSTER_RUN>', clusterRun.toString());
  code =
      code.replaceAll('<CLUSTER_RESCALE>', clusterReScale ? 'TRUE' : 'FALSE');
  code = code.replaceAll('<CLUSTER_TYPE>', '"${clusterType.toString()}"');
  code =
      code.replaceAll('<CLUSTER_DISTANCE>', '"${clusterDistance.toString()}"');
  code = code.replaceAll('<CLUSTER_LINK>', '"${clusterLink.toString()}"');
  code = code.replaceAll('<CLUSTER_PROCESSOR>', clusterProcessor.toString());

  ////////////////////////////////////////////////////////////////////////
  // EXPLORE - VISUAL - BOXPLOT

  code = code.replaceAll(
    '<BOXPLOT_NOTCH>',
    exploreVisualBoxplotNotch.toString().toUpperCase(),
  );

  code = code.replaceAll(
    '<IGNORE_MISSING_GROUP_BY>',
    ignoreMissingGroupBy.toString().toUpperCase(),
  );

  // EVALUATE

  code = code.replaceAll('<DATASET_TYPE>', chosenDataType.toUpperCase());

  ////////////////////////////////////////////////////////////////////////
  // FOREST

  code = code.replaceAll('<RF_NUM_TREES>', forestTrees.toString());
  code = code.replaceAll('<RF_MTRY>', forestPredictorNum.toString());
  code = code.replaceAll('<RF_NO_TREE>', forestNo.toString());
  code = code.replaceAll(
    '<RF_NA_ACTION>',
    forestImpute ? 'randomForest::na.roughfix' : 'na.omit',
  );

  code = code.replaceAll(
    '<RF_INPUT_SAMPSIZE>',
    forestSampleSize == null
        ? ''
        : forestSampleSize.isEmpty
            ? ''
            : ', sampsize = c($forestSampleSize)',
  );

  ////////////////////////////////////////////////////////////////////////
  // NEURAL

  code = code.replaceAll('<NNET_HIDDEN_LAYERS>', hiddenLayerSizes.toString());

  code = code.replaceAll('<NEURAL_HIDDEN_LAYERS>', 'c($hiddenNeurons)');
  code = code.replaceAll('<NEURAL_MAXIT>', nnetMaxit.toString());
  code = code.replaceAll(
    '<NEURAL_MAX_NWTS>',
    ref.read(neuralMaxWeightsProvider).toString(),
  );
  code =
      code.replaceAll('<NEURAL_ERROR_FCT>', '"${neuralErrorFct.toString()}"');
  code = code.replaceAll(
    '<NEURAL_ACT_FCT>',
    '"${neuralActivationFct.toString()}"',
  );
  if (neuralActivationFct != 'relu') {
    code = code.replaceAll(
      '<NEURAL_ACT_FCT>',
      '"${neuralActivationFct.toString()}"',
    );
  } else if (neuralActivationFct == 'relu') {
    // relu corresponds to the ReLU function from the sigmoid package in R.

    code = code.replaceAll('<NEURAL_ACT_FCT>', 'relu');
  }

  code = code.replaceAll('<NEURAL_THRESHOLD>', neuralThreshold.toString());
  code = code.replaceAll('<NEURAL_STEP_MAX>', neuralStepMax.toString());

  code = code.replaceAll(
    '<NEURAL_IGNORE_CATEGORIC>',
    neuralIgnoreCategoric.toString().toUpperCase(),
  );

  ////////////////////////////////////////////////////////////////////////
  // SVM

  code = code.replaceAll('<SVM_KERNEL>', '"${svmKernel.toString()}"');
  code = code.replaceAll('<SVM_DEGREE>', svmDegree.toString());

  ////////////////////////////////////////////////////////////////////////
  // WORD CLOUD

  code = code.replaceAll('<RANDOMORDER>', checkbox.toString().toUpperCase());
  code = code.replaceAll('<STEM>', stem ? 'TRUE' : 'FALSE');
  code = code.replaceAll('<PUNCTUATION>', punctuation ? 'TRUE' : 'FALSE');
  code = code.replaceAll('<STOPWORD>', stopword ? 'TRUE' : 'FALSE');
  code = code.replaceAll('<LANGUAGE>', language);
  code = code.replaceAll('<MINFREQ>', minFreq);
  code = code.replaceAll('<MAXWORD>', maxWord);

  ////////////////////////////////////////////////////////////////////////

  if (includingMissing) {
    code = code.replaceAll('usesurrogate=0,', '');
    code = code.replaceAll('maxsurrogate=0', '');
  }

  code = code.replaceAll('<NNET_TRACE>', nnetTrace ? 'TRUE' : 'FALSE');
  code = code.replaceAll('<NNET_SKIP>', nnetSkip ? 'TRUE' : 'FALSE');

  ////////////////////////////////////////////////////////////////////////

  // read the boolean value from the provider.

  bool includeCrossTab = ref.watch(crossTabSummaryProvider);

  // Cross tabulation summary.

  code = code.replaceAll(
    '<SUMMARY_CROSS_TAB>',
    includeCrossTab ? 'TRUE' : 'FALSE',
  );

  ////////////////////////////////////////////////////////////////////////

  // Add the code to the script provider so it will be displayed in the script
  // tab and available to be exported there.

  updateScript(ref, code);

  // Run the code without comments.

  code = rStripComments(code);

  // Add a completion marker.

  // code = '$code\nprint("Processing $script Completed")\n';

  ref.read(ptyProvider).write(const Utf8Encoder().convert(code));

  // Optionally, show a SnackBar when the script finishes executing.

//  if (code.contains('Processing $script Completed')) {
  setStatus(
    ref,
    'R scripts completed. See **Console** for details, **Script** for R code.\n'
    '**$scripts**',
  );
  // if (context.mounted) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Row(
  //         children: [
  //           const Icon(Icons.thumb_up, color: Colors.blue),
  //           const SizedBox(width: 40),
  //           Expanded(
  //             child: Text(
  //               'Execution of $script.R is completed.',
  //               style: const TextStyle(color: Colors.blue),
  //             ),
  //           ),
  //         ],
  //       ),
  //       backgroundColor: const Color(0xFFBBDEFB),
  //       elevation: 5,
  //       behavior: SnackBarBehavior.floating,
  //       shape: const StadiumBorder(),
  //       width: 600,
  //       // margin: const EdgeInsets.fromLTRB(10, 0, 300, 0),
  //       // Set a short duration
  //       duration: const Duration(seconds: 1),
  //       action: SnackBarAction(
  //         label: 'Okay',
  //         disabledTextColor: Colors.white,
  //         textColor: Colors.blue,
  //         onPressed: () {},
  //       ),
  //     ),
  //   );
  // }
//  }
}
