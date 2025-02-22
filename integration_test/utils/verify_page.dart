/// Verify the content of the page.
//
// Time-stamp: <Thursday 2025-01-23 15:46:23 +1100 Graham Williams>
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
import 'package:rattle/widgets/image_page.dart';
import 'package:flutter/material.dart';

/// Check that the expected title for the page is found and optionally some text
/// value on the page can be found.

Future<void> verifyPage(
  String title, [
  String? value,
]) async {
  final titleFinder = find.textContaining(title);
  expect(titleFinder, findsOneWidget);

  if (value != null) {
    final valueFinder = find.textContaining(value);
    expect(valueFinder, findsOneWidget);
  }
}

Future<void> verifyImage(WidgetTester tester) async {
  final imageFinder = find.byType(ImagePage);
  expect(imageFinder, findsOneWidget);
}

/// Verify that the markdown content is loaded.

Future<void> verifyMarkdown(WidgetTester tester) async {
  final markdownContent = find.byKey(const Key('markdown_file'));
  expect(markdownContent, findsOneWidget);
}

/// Verify that the selectable text contains the expected content.

Future<void> verifyPageSelectableText(String text) async {
  final textFinder = find.byWidgetPredicate(
    (widget) => widget is SelectableText && widget.data?.contains(text) == true,
  );
  expect(textFinder, findsOneWidget);
}

Future<void> verifyExist(Type widgetType) async {
  final finder = find.byType(widgetType);
  expect(finder, findsOneWidget);
}
