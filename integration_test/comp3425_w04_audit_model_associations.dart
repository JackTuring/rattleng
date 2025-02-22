/// COMP3425 W4 AUDIT dataset MODEL tab ASSOCIATION feature.
//
// Time-stamp: <Thursday 2025-02-06 08:33:00 +1100 Graham Williams>
//
/// Copyright (C) 2025, Togaware Pty Ltd
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
/// Authors: Graham Williams

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:rattle/features/association/panel.dart';
import 'package:rattle/features/impute/panel.dart';
import 'package:rattle/main.dart' as app;

import 'utils/delays.dart';
import 'utils/goto_next_page.dart';
import 'utils/navigate_to_feature.dart';
import 'utils/navigate_to_tab.dart';
import 'utils/load_demo_dataset.dart';
import 'utils/set_dataset_role.dart';
import 'utils/set_partition.dart';
import 'utils/set_selected_variable.dart';
import 'utils/tap_button.dart';
import 'utils/tap_chip.dart';
import 'utils/verify_page.dart';
import 'utils/verify_selectable_text.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AUDIT MODEL ASSOCIATION:', () {
    testWidgets('model, impute occupation, model.',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      // 20250206 gjw Turn partition on for now though the COMP3425 exercise
      // turns it off.
      await setPartition(tester, true);
      await loadDemoDataset(tester, 'Audit');
      await setDatasetRole(tester, 'employment', 'Ignore');
      await setDatasetRole(tester, 'occupation', 'Ignore');
      await setDatasetRole(tester, 'accounts', 'Ignore');
      await navigateToTab(tester, 'Model');
      await navigateToFeature(tester, 'Associations', AssociationPanel);
      await tapButton(tester, 'Build Association Rules');
      await tester.pump(delay);
      await gotoNextPage(tester);
      await verifyPage('Association Rules - Meta Summary');
      await verifySelectableText(
        tester,
        [
          '19 rules',
          'Min.   :0.1114   Min.   :0.1747   Min.   :0.1614   Min.   :0.8538',
          'Median :0.1457   Median :0.4403   Median :0.3436   Median :1.0425',
          'support = 0.1, confidence = 0.1, minlen = 2',
        ],
      );
      // 20250206 gjw If we turn partition off then we get different numbers.
      // await verifySelectableText(
      //   tester,
      //   [
      //     '19 rules',
      //     'Min.   :0.1035   Min.   :0.1557   Min.   :0.1125   Min.   :0.8435',
      //     'Median :0.1505   Median :0.5793   Median :0.3345   Median :1.0166',
      //     'transactions          2000     0.1        0.1',
      //     'support = 0.1, confidence = 0.1, minlen = 2',
      //   ],
      // );
      await gotoNextPage(tester);
      await verifyPage('Association Rules - Discovered Rules');
      await verifySelectableText(
        tester,
        [
          'marital=Married',
          'gender=Male',
          '0.4014286 0.8906498  0.4507143 1.3279123 562',
        ],
      );

      // Now IMPUTE missing for the Occupation and build again.

      await navigateToTab(tester, 'Dataset');
      await setDatasetRole(tester, 'occupation', 'Input');
      await navigateToTab(tester, 'Transform');
      await navigateToFeature(tester, 'Impute', ImputePanel);
      await setSelectedVariable(tester, 'occupation');
      await tapChip(tester, 'Constant');
      await tapButton(tester, 'Impute Missing Values');
      await gotoNextPage(tester);
      await verifySelectableText(
        tester,
        [
          'IMP_occupation',
        ],
      );

      // 20250205 gjw Rebuild the model and determin the difference?

      await navigateToTab(tester, 'Model');
      await navigateToFeature(tester, 'Associations', AssociationPanel);
      await tapButton(tester, 'Build Association Rules');
      await tester.pump(delay);

      // 20250205 gjw Don't go to next page here since we are already on the
      // right page.

      await verifyPage('Association Rules - Meta Summary');
      await verifySelectableText(
        tester,
        [
          '23 rules',
        ],
      );
      await gotoNextPage(tester);
      await verifyPage('Association Rules - Discovered Rules');
      await verifySelectableText(
        tester,
        [
          'marital=Married',
          'gender=Male',
          '0.4014286 0.8906498  0.4507143 1.3279123 562',
        ],
      );
    });
  });
}
