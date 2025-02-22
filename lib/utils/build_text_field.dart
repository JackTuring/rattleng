/// Build text field to input numeric input.
//
// Time-stamp: <Friday 2024-10-25 08:27:46 +1100 Graham Williams>
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
/// Authors: Zheyuan Xu

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:rattle/providers/forest.dart';

/// Creates a custom text input field with tooltip.
///
/// Builds a TextFormField wrapped in a MarkdownTooltip with specified styling and validation.
/// The field has configurable width, input formatting, and validation rules.
///
/// Returns a widget containing the styled and configured text field.

Widget buildTextField({
  required String label,
  required TextEditingController controller,
  required TextStyle textStyle,
  required String tooltip,
  required bool enabled,
  required String? Function(String?) validator,
  required TextInputFormatter inputFormatter,
  required int maxWidth,
  required Key key,
  WidgetRef? ref,
}) {
  return Flexible(
    child: MarkdownTooltip(
      message: tooltip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            // Set maximum width for the input field.

            width: maxWidth * 15.0,
            child: TextFormField(
              key: key,
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: const UnderlineInputBorder(),
                errorText: validator(controller.text),
                errorStyle: const TextStyle(fontSize: 10),
              ),
              style: textStyle,
              // Control enable state.

              enabled: enabled,
              inputFormatters: [
                inputFormatter,
                FilteringTextInputFormatter.singleLineFormatter,
              ],
              onEditingComplete: () {
                // Called when the user finishes editing the text field (e.g., pressing
                // the "Done" key on the keyboard). If this is the "Sample Size:" text field
                // and we have a valid Riverpod reference, update the forestSampleSizeProvider
                // with the current text from the controller.

                if (label == 'Sample Size:' && ref != null) {
                  ref.read(forestSampleSizeProvider.notifier).state =
                      controller.text;
                }
              },
              onSaved: (value) {
                // Called when the form containing this text field is saved (for example,
                // by calling Form.of(context).save()). If this is the "Sample Size:" text field
                // and we have a valid Riverpod reference, update the forestSampleSizeProvider
                // with the current text from the controller.

                if (label == 'Sample Size:' && ref != null) {
                  ref.read(forestSampleSizeProvider.notifier).state =
                      controller.text;
                }
              },
              onTapOutside: (event) {
                // Called when the user taps outside of the text field, causing it to lose focus.
                // If this is the "Sample Size:" text field and we have a valid Riverpod reference,
                // update the forestSampleSizeProvider with the current text from the controller.

                if (label == 'Sample Size:' && ref != null) {
                  ref.read(forestSampleSizeProvider.notifier).state =
                      controller.text;
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}
