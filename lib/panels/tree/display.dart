/// Widget to display the Tree introduction or built tree.
///
/// Copyright (C) 2023-2024, Togaware Pty Ltd.
///
/// License: GNU General Public License, Version 3 (the "License")
/// https://www.gnu.org/licenses/gpl-3.0.en.html
//
// Time-stamp: <Tuesday 2024-06-18 17:22:57 +1000 Graham Williams>
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
/// Authors: Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rattle/constants/app.dart';
import 'package:rattle/constants/markdown.dart';
import 'package:rattle/constants/sunken_box_decoration.dart';
import 'package:rattle/providers/stdout.dart';
import 'package:rattle/r/extract_tree.dart';
import 'package:rattle/widgets/show_markdown_file.dart';

/// The tree panel displays the tree instructions or the tree biuld output.

class TreeDisplay extends ConsumerStatefulWidget {
  const TreeDisplay({super.key});

  @override
  ConsumerState<TreeDisplay> createState() => _TreeDisplayState();
}

class _TreeDisplayState extends ConsumerState<TreeDisplay> {
  late PageController _pageController;
  int _currentPage = 0;
  // number of pages available
  int numPages = 2;

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextPage() {
    if (_currentPage < numPages - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  Widget build(BuildContext context) {
    String stdout = ref.watch(stdoutProvider);
    String content = rExtractTree(stdout);

    final curHeight = MediaQuery.of(context).size.height;

    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_left,
            color: _currentPage > 0 ? Colors.black : Colors.grey,
            size: 32,
          ),
          onPressed: _currentPage > 0 ? _goToPreviousPage : null,
        ),
        Expanded(
          child: SizedBox(
            height: curHeight * displayRatio,
            // avoid this error
            // Horizontal viewport was given unbounded height.
            // Viewports expand in the cross axis to fill their container and constrain their children to match
            // their extent in the cross axis. In this case, a horizontal viewport was given an unlimited amount of
            // vertical space in which to expand.

            // The relevant error-causing widget was:
            //   PageView PageView:file:///Users/yinyixiang/repo/my_rattleng/lib/panels/tree/display.dart:112:20
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                showMarkdownFile(treeIntroFile, context),
                Container(
                  decoration: sunkenBoxDecoration,
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 10),
                  child: content.isEmpty
                      ? const Center(
                          child: Text(
                            'Click the build button to see the result',
                          ),
                        )
                      : SingleChildScrollView(
                          child: SelectableText(
                            content,
                            style: monoTextStyle,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.arrow_right,
            size: 32,
            color: _currentPage < numPages - 1 ? Colors.black : Colors.grey,
          ),
          onPressed: _currentPage < numPages - 1 ? _goToNextPage : null,
        ),
      ],
    );
  }
}
