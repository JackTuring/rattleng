/// A numerical text input field.
//
// Time-stamp: <Friday 2024-12-13 08:49:23 +1100 Graham Williams>
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

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:rattle/constants/style.dart';

class NumberField extends ConsumerStatefulWidget {
  final String label;
  final TextEditingController controller;
  final StateProvider stateProvider;
  final String tooltip;
  final bool enabled;
  final String? Function(String?) validator;
  final TextInputFormatter inputFormatter;
  final int maxWidth;
  final num interval;
  final int decimalPlaces;
  final num? min;
  final num? max;
  final Future<void> Function(String? newValue)? onValueChanged;

  const NumberField({
    super.key,
    required this.controller,
    required this.stateProvider,
    required this.validator,
    required this.inputFormatter,
    this.min,
    this.max,
    this.label = '',
    this.tooltip = '',
    this.enabled = true,
    this.maxWidth = 5,
    this.decimalPlaces = 0,
    this.interval = 1, // Default interval is 1, can be set as double or int

    // Optional parameter for onValueChanged callback.

    this.onValueChanged,
  });

  @override
  NumberFieldState createState() => NumberFieldState();
}

class NumberFieldState extends ConsumerState<NumberField> {
  final FocusNode _focusNode = FocusNode();

  // Flag to prevent update loops between the TextEditingController and StateProvider.

  bool _isInternalChange = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Stores the current cursor position to maintain it during updates.

  TextSelection? _previousSelection;

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      updateField();
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);

    // Listen to provider changes and update the controller.

    ref.listenManual(
      widget.stateProvider,
      (previous, next) {
        if (!_isInternalChange) {
          setState(() {
            // Store the current selection before updating text.

            _previousSelection = widget.controller.selection;

            widget.controller.text = next.toString();

            // Restore the cursor position after text update.

            if (_previousSelection != null && _focusNode.hasFocus) {
              widget.controller.selection = TextSelection.collapsed(
                offset: min(
                  _previousSelection!.baseOffset,
                  widget.controller.text.length,
                ),
              );
            }
          });
        }
      },
      fireImmediately: true,
    );
  }

  void increment() {
    num currentValue = num.tryParse(widget.controller.text) ?? 0;
    currentValue += widget.interval;

    // Automatically cap at the max if specified.

    if (widget.max != null) {
      currentValue = min(currentValue, widget.max!);
    }

    // Update the state provider directly.

    ref.read(widget.stateProvider.notifier).state = currentValue;
  }

  void decrement() {
    num currentValue = num.tryParse(widget.controller.text) ?? 0;
    currentValue -= widget.interval;

    // Automatically floor at min if specified.

    if (widget.min != null) {
      currentValue = max(currentValue, widget.min!);
    }

    // Update state provider directly.

    ref.read(widget.stateProvider.notifier).state = currentValue;
  }

  // A timer for continuous incrementing/decrementing.

  Timer? timer;

  void startIncrementing() {
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      increment();
    });
  }

  void stopIncrementing() {
    timer?.cancel();
  }

  void startDecrementing() {
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      decrement();
    });
  }

  void stopDecrementing() {
    timer?.cancel();
  }

  void updateField() {
    // Store current cursor position.

    _previousSelection = widget.controller.selection;

    String updatedText = widget.controller.text;
    num? v = num.tryParse(updatedText);

    if (v == null) {
      // If the parsing fails, set to 0 or min.

      v = widget.min ?? 0;
    } else {
      // Apply min and max constraints.

      if (widget.min != null) {
        v = max(v, widget.min!);
      }
      if (widget.max != null) {
        v = min(v, widget.max!);
      }
    }

    // Controller text automatically updates to
    // the range of [widget.min] and [widget.max].

    widget.controller.text = v.toString();

    // Apply decimal places if needed.

    if (widget.decimalPlaces > 0) {
      v = double.parse(v.toStringAsFixed(widget.decimalPlaces));
    }

    _isInternalChange = true;

    // Update the state.
    ref.read(widget.stateProvider.notifier).state = v;

    // Restore cursor position if needed.

    if (_previousSelection != null && _focusNode.hasFocus) {
      widget.controller.selection = TextSelection.collapsed(
        offset:
            min(_previousSelection!.baseOffset, widget.controller.text.length),
      );
    }

    _isInternalChange = false;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the state provider to ensure the widget rebuilds when the value changes.

    ref.watch(widget.stateProvider);

    return MarkdownTooltip(
      message: widget.tooltip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: widget.maxWidth * 30.0,
            child: Stack(
              children: [
                TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    labelText: widget.label,
                    border: const UnderlineInputBorder(),
                    contentPadding: const EdgeInsets.only(
                      right: 40,
                      left: 10,
                    ),
                    errorText: widget.validator(widget.controller.text),
                    errorStyle: const TextStyle(
                      fontSize: 10,
                    ),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onEditingComplete: () {
                    // Store selection before completing edit.

                    _previousSelection = widget.controller.selection;
                    updateField();
                  },
                  onChanged: (value) {
                    // Store the current selection.

                    _previousSelection = widget.controller.selection;

                    // Only perform basic validation, don't update field yet.

                    if (value.isNotEmpty &&
                        !RegExp(r'^[0-9.]+$').hasMatch(value)) {
                      String newValue =
                          value.replaceAll(RegExp(r'[^0-9.]'), '');
                      widget.controller.value = TextEditingValue(
                        text: newValue,
                        selection: TextSelection.collapsed(
                          offset: min(
                            _previousSelection!.baseOffset,
                            newValue.length,
                          ),
                        ),
                      );
                    }
                  },
                  style: widget.enabled ? normalTextStyle : disabledTextStyle,
                  enabled: widget.enabled,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    widget.inputFormatter,
                  ],
                ),
                // Positioned Arrow Buttons.

                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: widget.enabled ? increment : null,
                        onLongPressStart: widget.enabled
                            ? (details) => startIncrementing()
                            : null,
                        onLongPressEnd: widget.enabled
                            ? (details) => stopIncrementing()
                            : null,
                        child: const Icon(Icons.arrow_drop_up),
                      ),
                      GestureDetector(
                        onTap: widget.enabled ? decrement : null,
                        onLongPressStart: widget.enabled
                            ? (details) => startDecrementing()
                            : null,
                        onLongPressEnd: widget.enabled
                            ? (details) => stopDecrementing()
                            : null,
                        child: const Icon(Icons.arrow_drop_down),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Validation logic for integer fields.

String? validateInteger(
  String? value, {
  required int min,
  int? max,
}) {
  if (value == null || value.isEmpty) return 'Cannot be empty';

  int? intValue = int.tryParse(value);
  if (intValue == null) {
    return 'Must be a valid number';
  }

  if (intValue < min) {
    return 'Must be at least $min';
  }

  if (max != null && intValue > max) {
    return 'Must be at most $max';
  }

  return null;
}

// Validation logic for decimal field.

String? validateDecimal(String? value) {
  if (value == null || value.isEmpty) return 'Cannot be empty';
  double? doubleValue = double.tryParse(value);
  if (doubleValue == null || doubleValue < 0.0000 || doubleValue > 1.0000) {
    return 'Must be between 0.0000 and 1.0000';
  }

  return null;
}
