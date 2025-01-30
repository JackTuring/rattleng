///  Press a button with the given text.
//
// Time-stamp: <Friday 2024-12-27 14:06:30 +1100 Graham Williams>
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
/// Authors: Kevin Wang, Graham Williams

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

Future<void> tapButton(
  WidgetTester tester,
  String buttonText,
) async {
  final buttonFinder = find.text(buttonText).first;
  expect(buttonFinder, findsOneWidget);

  await tester.tap(buttonFinder);
  await tester.pumpAndSettle();
}

Future<void> tapButtonByKey(WidgetTester tester, String key) async {
  final buttonFinder = find.byKey(Key(key));
  expect(buttonFinder, findsOneWidget);

  await tester.tap(buttonFinder);
  await tester.pumpAndSettle();
}
