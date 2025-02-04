/// AUDIT dataset TRANSFORM tab IMPUTE feature.
//
// Time-stamp: <Friday 2025-01-31 15:50:39 +1100 Graham Williams>
//
/// Copyright (C) 2024-2025, Togaware Pty Ltd
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
/// Authors:  Kevin Wang

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:rattle/features/impute/panel.dart';
import 'package:rattle/main.dart' as app;

import 'utils/delays.dart';
import 'utils/goto_next_page.dart';
import 'utils/load_demo_dataset.dart';
import 'utils/navigate_to_feature.dart';
import 'utils/navigate_to_tab.dart';
import 'utils/set_selected_variable.dart';
import 'utils/tap_button.dart';

import 'utils/unify_on.dart';

import 'utils/verify_page.dart';
import 'utils/verify_selectable_text.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AUDIT TRANSFORM IMPUTE:', () {
    testWidgets('xxxx.', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(interact);
      await unifyOn(tester);
      await loadDemoDataset(tester, 'Audit');

      await navigateToTab(tester, 'Transform');
      await navigateToFeature(tester, 'Impute', ImputePanel);

      await setSelectedVariable(tester, 'occupation');

      // // Step 1: Test imputation with Mean.

      await tapButton(tester, 'Impute Missing Values');

      await tester.pump(delay);
      await gotoNextPage(tester);

      // Verify that the page content includes the expected dataset summary with
      // 'IMN_occupation'.

      await verifyPage(
        'Dataset Summary',
        'IMN_occupation',
      );

      // Verify specific statistical values for the imputed 'IMN_occupation' variable.

      await verifySelectableText(
        tester,
        [
          'Min.   : 1.000', // Minimum value of 'IMN_occupation'.
          '1st Qu.: 3.000', // First quartile value of 'IMN_occupation'.
          'Median : 8.000', // Median value of 'IMN_occupation'.
          'Mean   : 7.387', // Mean value of 'IMN_occupation'.
          '3rd Qu.:11.000', // Third quartile value of 'IMN_occupation'.
          'Max.   :14.000', // Maximum value of 'IMN_occupation'.
          'NA\'s   :101', // Number of missing values of 'IMN_occupation'.
        ],
      );
    });
  });
}
