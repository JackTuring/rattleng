/// Test the EXPLORE tab MISSING feature with th LARGE dataset.
//
// Time-stamp: <Sunday 2025-01-26 07:35:34 +1100 Graham Williams>
//
/// Copyright (C) 2023-2024, Togaware Pty Ltd
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

import 'package:rattle/features/missing/panel.dart';
import 'package:rattle/main.dart' as app;

import 'utils/delays.dart';
import 'utils/goto_next_page.dart';
import 'utils/navigate_to_feature.dart';
import 'utils/navigate_to_tab.dart';
import 'utils/load_dataset_by_path.dart';
import 'utils/tap_button.dart';
import 'utils/verify_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Large Dataset, Explore, Missing.', (
    WidgetTester tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.pump(interact);
    await loadDatasetByPath(tester, 'integration_test/data/medical.csv');
    await navigateToTab(tester, 'Explore');
    await navigateToFeature(tester, 'Missing', MissingPanel);
    await tapButton(tester, 'Perform Missing Analysis');

    // 20250123 gjw I had to add this delay in order to ensure the R script had
    // finsihed generating the various analyses.

    await tester.pump(delay);
    await gotoNextPage(tester);
    await verifyPage('Patterns of Missing Data - Textual');
    await gotoNextPage(tester);
    await verifyPage('Patterns of Missing Values');
    await gotoNextPage(tester);
    await verifyPage(
      'Aggregation of Missing Values',
    );
    await gotoNextPage(tester);
    await verifyPage(
      'Aggregation of Missing Values',
    );
    await gotoNextPage(tester);
    await verifyPage(
      'Visualisation of Observations with Missing Values',
    );
    await gotoNextPage(tester);
    await verifyPage(
      'Comparison of Counts of Missing Values',
    );
    await gotoNextPage(tester);
    await verifyPage('Patterns of Missingness');
  });
}
