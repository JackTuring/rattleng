/// Verify multiple text content in the widget.
//
// Time-stamp: <Wednesday 2025-02-12 16:33:15 +1100 Graham Williams>
//
/// Copyright (C) 2023-2025, Togaware Pty Ltd
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
/// Authors: Kevin Wang, Graham Williams

library;

import 'package:flutter_test/flutter_test.dart';

Future<void> verifyText(
  WidgetTester tester,
  List<String> texts, {
  bool multi = false,
}) async {
  for (final text in texts) {
    final textFinder = find.text(text);
    expect(textFinder, multi ? findsAtLeastNWidgets(1) : findsOneWidget);
  }
}
