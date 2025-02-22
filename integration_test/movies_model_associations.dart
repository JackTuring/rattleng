/// Test MOVIES dataset MODEL tab ASSOCIATION feature.
//
// Time-stamp: <2025-02-06 15:45:41 gjw>
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

import 'package:rattle/features/association/panel.dart';
import 'package:rattle/main.dart' as app;
import 'package:rattle/widgets/image_page.dart';

import 'utils/delays.dart';
import 'utils/goto_next_page.dart';
import 'utils/navigate_to_feature.dart';
import 'utils/navigate_to_tab.dart';
import 'utils/load_demo_dataset.dart';
import 'utils/tap_button.dart';
import 'utils/verify_page.dart';
import 'utils/verify_selectable_text.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Movies Model Association.', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    await loadDemoDataset(tester, 'Movies');
    await navigateToTab(tester, 'Model');
    await navigateToFeature(tester, 'Associations', AssociationPanel);
    await tapButton(tester, 'Build Association Rules');
    await tester.pump(delay);
    await gotoNextPage(tester);
    await verifyPage('Association Rules - Meta Summary');
    await verifySelectableText(
      tester,
      [
        '44 rules',
      ],
    );
    await gotoNextPage(tester);
    await verifyPage('Association Rules - Discovered Rules');
    await verifySelectableText(
      tester,
      [
        'Patriot',
        '0.7500000  0.4      1.5000000 3',
      ],
    );

    await gotoNextPage(tester);
    await verifyPage('Item Frequency');
    var imageFinder = find.byType(ImagePage);
    expect(imageFinder, findsOneWidget);

    await gotoNextPage(tester);
    imageFinder = find.byType(ImagePage);
    expect(imageFinder, findsOneWidget);

    await gotoNextPage(tester);
    await verifyPage('Parrallel Coordinates Plot');
    imageFinder = find.byType(ImagePage);
    expect(imageFinder, findsOneWidget);
  });
}
