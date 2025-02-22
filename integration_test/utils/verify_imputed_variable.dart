/// Verify that a variable has been imputed in the dataset display.
//
// Time-stamp: <Thursday 2025-01-30 16:33:35 +1100 Graham Williams>
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
/// Authors:  Kevin Wang

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattle/features/dataset/display.dart';
import 'package:rattle/providers/vars/roles.dart';

/// Verify that a variable has been imputed in the dataset display.
/// Check if the rolesProvider has the imputed variable.

Future<void> verifyImputedVariable(
  WidgetTester tester,
  String variable,
) async {
  // get the roles from the dataset display.

  final roles = tester
      .state<ConsumerState>(
        find.byType(DatasetDisplay),
      )
      .ref
      .read(rolesProvider);

  List<String> vars = [];
  roles.forEach((key, value) {
    if (value == Role.input ||
        value == Role.risk ||
        value == Role.target ||
        value == Role.ignore) {
      vars.add(key);
    }
  });

  // check if the variable is in the list of variables.

  expect(vars.contains(variable), true);
}
