/// Test ksvm() svm with demo dataset.
//
// Time-stamp: <Saturday 2025-02-01 17:54:19 +1100 Graham Williams>
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
/// Authors: Zheyuan Xu

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:rattle/features/svm/panel.dart';
import 'package:rattle/main.dart' as app;

import 'utils/delays.dart';
import 'utils/navigate_to_feature.dart';
import 'utils/navigate_to_tab.dart';
import 'utils/load_demo_dataset.dart';
import 'utils/tap_button.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Load, Navigate, Build.', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.pump(interact);
    await loadDemoDataset(tester);
    await navigateToTab(tester, 'Model');
    await navigateToFeature(tester, 'SVM', SvmPanel);
    await tester.pump(interact);
    await tapButton(tester, 'Build SVM Model');
    await tester.pump(delay);
    await tapButton(tester, 'Build SVM Model');
    await tester.pump(interact);
    final titleFinder = find.textContaining(
      'Support Vector Machine object of class "ksvm"',
    );
    expect(titleFinder, findsOneWidget);
    await tester.pump(interact);
  });
}
