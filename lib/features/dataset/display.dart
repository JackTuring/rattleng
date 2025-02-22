/// Dataset display with pages.
//
// Time-stamp: <Monday 2024-12-16 08:19:17 +1100 Graham Williams>
//
/// Copyright (C) 2023-2024, Togaware Pty Ltd.
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
/// Authors: Graham Williams, Yixiang Yin， Bo Zhang, Kevin Wang

library;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:rattle/constants/app.dart';
import 'package:rattle/constants/markdown.dart';
import 'package:rattle/constants/spacing.dart';
import 'package:rattle/providers/meta_data.dart';
import 'package:rattle/providers/page_controller.dart';
import 'package:rattle/providers/path.dart';
import 'package:rattle/providers/roles_table_rebuild.dart';
import 'package:rattle/providers/selected_row.dart';
import 'package:rattle/providers/vars/roles.dart';
import 'package:rattle/providers/stdout.dart';
import 'package:rattle/providers/vars/types.dart';
import 'package:rattle/r/execute.dart';
import 'package:rattle/r/extract.dart';
import 'package:rattle/r/extract_large_factors.dart';
import 'package:rattle/r/extract_vars.dart';
import 'package:rattle/utils/get_target.dart';
import 'package:rattle/utils/get_unique_columns.dart';
import 'package:rattle/utils/is_numeric.dart';
import 'package:rattle/utils/show_ok.dart';
import 'package:rattle/utils/update_roles_provider.dart';
import 'package:rattle/utils/update_meta_data.dart';
import 'package:rattle/utils/debug_text.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:rattle/widgets/page_viewer.dart';
import 'package:rattle/utils/show_markdown_file_2.dart';
import 'package:rattle/widgets/text_page.dart';

const smallSpace = Gap(10);

/// The dataset panel displays the RattleNG welcome on the first page and the
/// ROLES as the second page.

class DatasetDisplay extends ConsumerStatefulWidget {
  const DatasetDisplay({super.key});

  @override
  ConsumerState<DatasetDisplay> createState() => _DatasetDisplayState();
}

class _DatasetDisplayState extends ConsumerState<DatasetDisplay> {
  // Constants for layout.

  final int typeFlex = 4;
  final int contentFlex = 3;

  // Track pressed keys for shift and control selection.

  bool _isShiftPressed = false;
  bool _isCtrlPressed = false;

  @override
  Widget build(BuildContext context) {
    // Get the PageController from Riverpod.

    final pageController = ref.watch(pageControllerProvider);

    String path = ref.watch(pathProvider);
    String stdout = ref.watch(stdoutProvider);

    // Watch rebuildTriggerProvider to trigger a rebuild when its value changes.

    ref.watch(rebuildTriggerProvider);

    // FIRST PAGE: Welcome Message.

    List<Widget> pages = [
      showMarkdownFile2(welcomeIntroFile1, welcomeIntroFile2, context),
    ];

    // Handle different file types.

    if (path.endsWith('.txt')) {
      _addTextFilePage(stdout, pages);
    } else if (path == weatherDemoFile || path.endsWith('.csv')) {
      // 20240815 gjw Update the metaData provider here if needed.

      updateMetaData(ref);

      _addDatasetPage(stdout, pages);
    }

    // Listen for shift and control key events.

    HardwareKeyboard.instance.addHandler((event) {
      setState(() {
        _isShiftPressed = HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.shiftLeft) ||
            HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.shiftRight);

        _isCtrlPressed = HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.controlLeft) ||
            HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.controlRight);
      });

      // Return a boolean value.

      return false;
    });

    return PageViewer(
      pageController: pageController,
      pages: pages,
    );
  }

  ////////////////////////////////////////////////////////////////////////

  // Add a page for text file (a .txt file) content for Word Cloud.

  void _addTextFilePage(String stdout, List<Widget> pages) {
    String content = rExtract(stdout, '> cat(txt,');
    String title = '''

        # Text Content

        Generated using
        [base::cat(txt)](https://www.rdocumentation.org/packages/base/topics/cat).

        ''';

    if (content.isNotEmpty) {
      pages.add(TextPage(title: title, content: '\n$content'));
    }
  }

  ////////////////////////////////////////////////////////////////////////

  // Add a page for dataset summary.
  void _addDatasetPage(String stdout, List<Widget> pages) {
    Map<String, Role> currentRoles = ref.read(rolesProvider);
    List<VariableInfo> vars = extractVariables(stdout);
    List<String> highVars = extractLargeFactors(stdout);

    _initializeRoles(vars, highVars, currentRoles);

    // When a new row is added after transformation, initialize its role and
    // update the role of the old variable.

    updateVariablesProvider(ref);
    Map<String, String> rolesOption = {
      'Ignore': '''

      For the selected variables in the data table below set their role to
      **Ignore**. Ignored variables will not be used in any analysis and can be
      removed from the dataset using the **Cleanup** feature under the
      **Transform** tab.

      ''',
      'Input': '''

      For the slected variables in the data table below set their role to
      **Input**. Input variables are used for predictive modelling in the
      **Model** tab, for example, to predict a **Target** variable.

      ''',
    };

    // Function to update the role for multiple selected rows.

    void _updateRoleForSelectedRows(String newRole) {
      setState(() {
        final selectedRows = ref.read(selectedRowIndicesProvider);
        String stdout = ref.watch(stdoutProvider);

        List<VariableInfo> vars = extractVariables(stdout);

        // Update roles for each selected row

        selectedRows.forEach((index) {
          String columnName = vars[index].name;
          ref.read(rolesProvider.notifier).state[columnName] =
              newRole == 'Ignore' ? Role.ignore : Role.input;
        });

        // Clear selection after updating

        selectedRows.clear();

        // Increment the rebuild trigger to refresh DatasetDisplay

        ref.read(rebuildTriggerProvider.notifier).state++;
      });
    }

    pages.add(
      Stack(
        children: [
          Row(
            children: [
              configWidgetGap,
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ...rolesOption.keys.map(
                      (roleKey) => MarkdownTooltip(
                        message: rolesOption[roleKey]!,
                        wait: const Duration(
                          seconds: 1,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ElevatedButton(
                            onPressed: () {
                              final selectedRows =
                                  ref.read(selectedRowIndicesProvider);

                              if (selectedRows.isEmpty) {
                                // Show a warning dialog if no rows are selected.

                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('No Row Selected'),
                                      content: const Text(
                                        'You have not selected a row to set the Role.',
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                // Proceed to update the role if rows are selected.

                                _updateRoleForSelectedRows(roleKey);
                              }
                            },
                            child: Text(roleKey),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              MarkdownTooltip(
                message: '''

                **Viewer.** Tap here to open a separate window to view the
                current dataset. The default and quite simple data viewer in R
                will be used. It is invoked as `View(ds)`.

              ''',
                child: IconButton(
                  icon: const Icon(
                    Icons.table_view,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    String path = ref.read(pathProvider);
                    if (path.isEmpty) {
                      showOk(
                        context: context,
                        title: 'No Dataset Loaded',
                        content: '''

                      Please choose a dataset to load from the **Dataset** tab. There is
                      not much we can do until we have loaded a dataset.

                      ''',
                      );
                    } else {
                      rExecute(ref, 'View(ds)\n');
                    }
                  },
                ),
              ),
            ],
          ),

          // Main ListView for displaying data table.
          Padding(
            padding: const EdgeInsets.only(top: 56.0),
            child: _buildDataTable(vars),
          ),
        ],
      ),
    );
  }

  // Initialise ROLES. Default to INPUT and identify TARGET, RISK,
  // IDENTS. Also record variable types.

  void _initializeRoles(
    List<VariableInfo> vars,
    List<String> highVars,
    Map<String, Role> currentRoles,
  ) {
    if (currentRoles.isEmpty && vars.isNotEmpty) {
      for (var column in vars) {
        _setInitialRole(column, ref);
      }
      _setTargetRole(vars, ref);
      _setIdentRole(ref);

      // 20241213 gjw Let's turn off the IGNORE heursitic for now. Leave it to a
      // user to decide. For the PROTEIN dataset we want COUNTRY to be IDENT r
      // TARGET rather than IGNORE.

      // _setIgnoreRoleForHighVars(highVars, ref);
    }
  }

  // Set initial role for a variable.

  void _setInitialRole(VariableInfo column, WidgetRef ref) {
    String name = column.name.toLowerCase();

    // Default is INPUT unless a prefix is found.

    Role role = Role.input;

    if (name.startsWith('risk_')) role = Role.risk;
    if (name.startsWith('ignore_')) role = Role.ignore;
    if (name.startsWith('target_')) role = Role.target;

    ref.read(rolesProvider.notifier).state[column.name] = role;
    ref.read(typesProvider.notifier).state[column.name] =
        isNumeric(column.type) ? Type.numeric : Type.categoric;
  }

  // Treat the last variable as a TARGET by default. We will eventually
  // implement Rattle heuristics to identify the TARGET if the final
  // variable has more than 5 levels. If so we'll check if the first
  // variable looks like a TARGET (another common practise) and if not
  // then no TARGET will be identified by default.

  void _setTargetRole(List<VariableInfo> vars, WidgetRef ref) {
    String target = getTarget(ref);
    if (target == 'NULL') {
      ref.read(rolesProvider.notifier).state[vars.last.name] = Role.target;
    } else if (target != '""') {
      // TODO 20241216 gjw HOW DOES target BECOME '""' - TO BE FIXED
      ref.read(rolesProvider.notifier).state[target] = Role.target;
    }
  }

  void _setIdentRole(WidgetRef ref) {
    // Any variables that have a unique value for every row in the dataset is
    // considered to be an IDENTifier.

    for (var id in getUniqueColumns(ref)) {
      ref.read(rolesProvider.notifier).state[id] = Role.ident;
    }

    Map metaData = ref.read(metaDataProvider);

    // 20241211 gjw A hueristic that says if there are only two columns in the
    // dataset, expect it to be a basket dataset for association rule
    // analysis. Set the firt column as the basket identifier (IDENT) and the
    // second column as the basket item (TARGET). As we move away from the
    // DATASET tab we also set the BASKETS checkbox in the ASSOCIATE feature to
    // match this heuristic. That is done in `lib/home.dart`.

    if (metaData.length == 2) {
      ref.read(rolesProvider.notifier).state[metaData.keys.first] = Role.ident;
      ref.read(rolesProvider.notifier).state[metaData.keys.last] = Role.target;
    }
  }

  // Set ignore role for high cardinality variables.

  // 20241213 gjw Remove this for now until we decide how to best deal with
  // identifying variables to IGNORE.

  // void _setIgnoreRoleForHighVars(List<String> highVars, WidgetRef ref) {
  //   for (var highVar in highVars) {
  //     if (ref.read(rolesProvider.notifier).state[highVar] != Role.target) {
  //       ref.read(rolesProvider.notifier).state[highVar] = Role.ignore;
  //     }
  //   }
  // }

  // Build data table with row selection logic.

  Widget _buildDataTable(List<VariableInfo> vars) {
    Map<String, Role> currentRoles = ref.watch(rolesProvider);
    final selectedRows = ref.watch(selectedRowIndicesProvider);

    var formatter = NumberFormat('#,###');

    return Container(
      child: SingleChildScrollView(
        key: const Key('roles listView'),
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: [
            DataColumn(
              label: MarkdownTooltip(
                message: '''

                To select or deselect all variables shift-click the checkbox to
                the left here in the header row.

                ''',
                child: Text(
                  'Variable',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataColumn(
              label:
                  Text('Role', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label:
                  Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label:
                  Text('Unique', style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Missing',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
            ),
            DataColumn(
              label:
                  Text('Sample', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: vars.map((variable) {
            int rowIndex = vars.indexOf(variable);
            bool isSelected = selectedRows.contains(rowIndex);

            return DataRow(
              selected: isSelected,
              onSelectChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    if (_isShiftPressed) {
                      // Shift-click: Add multiple selections from the last selected row.

                      selectedRows.add(rowIndex);
                    } else if (_isCtrlPressed && selectedRows.isNotEmpty) {
                      // Ctrl-click: Auto-select range between the first selected row and this row.

                      int firstSelectedRow = selectedRows.first;
                      int lastSelectedRow = rowIndex;

                      // Ensure that we have a start and end point correctly ordered.

                      if (lastSelectedRow < firstSelectedRow) {
                        int temp = firstSelectedRow;
                        firstSelectedRow = lastSelectedRow;
                        lastSelectedRow = temp;
                      }

                      // Select all rows in the range between first and last selected rows.

                      for (int i = firstSelectedRow;
                          i <= lastSelectedRow;
                          i++) {
                        selectedRows.add(i);
                      }
                    } else {
                      // Single click: Clear previous selection and select only the current row.

                      selectedRows.clear();
                      selectedRows.add(rowIndex);
                    }
                  } else {
                    // Deselect the row if it was previously selected.

                    selectedRows.remove(rowIndex);
                  }
                });
              },
              cells: [
                DataCell(Text(variable.name)),
                DataCell(
                  _buildRoleChips(variable.name, currentRoles),
                ),
                DataCell(Text(variable.type)),
                DataCell(
                  Text(
                    formatter.format(
                      ref.watch(metaDataProvider)[variable.name]?['unique']
                              ?[0] ??
                          0,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    formatter.format(
                      ref.watch(metaDataProvider)[variable.name]?['missing']
                              ?[0] ??
                          0,
                    ),
                  ),
                ),
                DataCell(SelectableText(_truncateContent(variable.details))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // Build role choice chips.

  Widget _buildRoleChips(String columnName, Map<String, Role> currentRoles) {
    return Center(
      key: Key('role-${columnName}'),
      // Set width to fit 5 ChoiceChips in a row.

      child: SizedBox(
        width: choiceChipRowWidth,
        child: Wrap(
          spacing: 5.0,
          runSpacing: choiceChipRowSpace,
          children: choices.map((choice) {
            return ChoiceChip(
              label: Text(choice.displayString),
              disabledColor: Colors.grey,
              selectedColor: Colors.lightBlue[200],
              backgroundColor: Colors.lightBlue[50],
              showCheckmark: false,
              shadowColor: Colors.grey,
              pressElevation: 8.0,
              elevation: 2.0,
              selected: remap(currentRoles[columnName]!, choice),
              onSelected: (bool selected) => _handleRoleSelection(
                selected,
                choice,
                columnName,
                currentRoles,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Handle role selection.

  void _handleRoleSelection(
    bool selected,
    Role choice,
    String columnName,
    Map<String, Role> currentRoles,
  ) {
    // The parameter selected can be false when a chip
    // is tapped when it is already selected. That could
    // be useful as a toggle button.

    setState(() {
      if (selected) {
        // Only one variable can be TARGET, RISK, or WEIGHT, so any previous
        // variable with that role should become INPUT.

        if (choice == Role.target ||
            choice == Role.risk ||
            choice == Role.weight) {
          currentRoles.forEach((key, value) {
            if (value == choice) {
              ref.read(rolesProvider.notifier).state[key] = Role.input;
            }
          });
        }
        ref.read(rolesProvider.notifier).state[columnName] = choice;
        debugText('  $choice', columnName);
      }
    });
  }

  // Truncate content for display.

  String _truncateContent(String content) {
    int maxLength = 45;
    String subStr =
        content.length > maxLength ? content.substring(0, maxLength) : content;
    int lastCommaIndex = subStr.lastIndexOf(',') + 1;

    return '${lastCommaIndex > 0 ? content.substring(0, lastCommaIndex) : subStr} ...';
  }
}
