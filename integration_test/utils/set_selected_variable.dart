/// Function goes to variableChooser widget and then selects the given
/// variable name.
//
// Time-stamp: <Saturday 2024-12-28 06:23:43 +1100 Graham Williams>
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
/// Authors: Kevin Wang
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

Future<void> setSelectedVariable(
  WidgetTester tester,
  String variableName, {
  String? feature,
}) async {
  // For the Recode Feature there are 3 instances of the text "Variable"
  // The second one is the one we want to tap.

  if (feature == 'recode') {
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is MarkdownTooltip &&
            widget.child is DropdownMenu &&
            (widget.child as DropdownMenu).label is Text &&
            ((widget.child as DropdownMenu).label as Text).data == 'Variable',
      ),
      findsOneWidget,
      reason: 'Variable chooser dropdown not found',
    );

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is MarkdownTooltip &&
            widget.child is DropdownMenu &&
            (widget.child as DropdownMenu).label is Text &&
            ((widget.child as DropdownMenu).label as Text).data == 'Variable',
      ),
    );

    await tester.pumpAndSettle();

    // Find the second instance of the text and tap it.

    await tester.tap(find.text(variableName).at(1));
    await tester.pumpAndSettle();
  } else {
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DropdownMenu &&
            widget.label is Text &&
            (widget.label as Text).data == 'Variable',
      ),
      findsOneWidget,
      reason: 'Variable chooser dropdown not found',
    );

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is DropdownMenu &&
            widget.label is Text &&
            (widget.label as Text).data == 'Variable',
      ),
    );
    await tester.pumpAndSettle();

    // For other features, find the last instance of the text(dropdown selection)
    // and tap it.

    await tester.tap(find.text(variableName).last);
    await tester.pumpAndSettle();
  }
}
