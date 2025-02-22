/// Test the Transform tab Impute/Rescale/Recode feature on the DEMO dataset.
//
// Time-stamp: <Friday 2025-01-31 15:46:36 +1100 Graham Williams>
//
/// Copyright (C) 2024, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
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
/// Authors:  Kevin Wang, Graham Williams

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:rattle/features/impute/panel.dart';
import 'package:rattle/main.dart' as app;

import 'utils/delays.dart';
import 'utils/goto_next_page.dart';
import 'utils/navigate_to_feature.dart';
import 'utils/navigate_to_tab.dart';
import 'utils/load_dataset_by_path.dart';
import 'utils/tap_chip.dart';
import 'utils/tap_button.dart';
import 'utils/verify_page.dart';
import 'utils/verify_selectable_text.dart';
// import 'utils/check_missing_variable.dart';
// import 'utils/check_variable_not_missing.dart';
// import 'utils/init_app.dart';
// import 'utils/verify_imputed_variable.dart';

void main() {
  // Ensure that the integration test bindings are initialized before running tests.

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Define a group of tests related to the Transform tab on a large dataset.

  group('Transform LARGE:', () {
    testWidgets('build, page.', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(interact);
      await loadDatasetByPath(tester, 'integration_test/data/medical.csv');
      await navigateToTab(tester, 'Transform');
      await navigateToFeature(tester, 'Impute', ImputePanel);
      await tapChip(tester, 'Constant');
      await tapButton(tester, 'Impute Missing Values');
      await tester.pump(hack);
      await gotoNextPage(tester);
      await verifyPage('Dataset Summary');
      await verifySelectableText(
        tester,
        [
          'IMP_middle_name',
          'Missing: 1987', // Number of missing values imputed.
          'lee    :  563', // Frequency of 'lee' in the imputed data.
          'michael:  262', // Frequency of 'michael' in the imputed data.
          'ann    :  253', // Frequency of 'ann' in the imputed data.
          'wayne  :  239', // Frequency of 'wayne' in the imputed data.
          'edward :  237', // Frequency of 'edward' in the imputed data.
        ],
      );

      // Step 2.5: Navigate to the 'Dataset' tab to ensure the UI updates correctly.

      await navigateToTab(tester, 'Dataset');

      await tester.pump(interact);

      // Allow time for the UI to settle after the tab change.

      await tester.pump(hack);

      // Step 3: Verify that the imputed variable 'IZR_middle_name' is present in the dataset.

      // await verifyImputedVariable(container, 'IZR_middle_name');

      // Step 4: Check that the imputed variable 'IZR_middle_name' is no longer listed as missing.

      // await checkVariableNotMissing(container, 'IZR_middle_name');

      // Dispose of the ProviderContainer to clean up resources and prevent memory leaks.

      // container.dispose();
    });
  });
}
