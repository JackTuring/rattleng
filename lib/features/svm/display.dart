/// Widget to display the SVM introduction or output.
///
/// Copyright (C) 2024, Togaware Pty Ltd.
///
/// License: GNU General Public License, Version 3 (the "License")
/// https://www.gnu.org/licenses/gpl-3.0.en.html
//
// Time-stamp: <Friday 2025-01-10 10:09:24 +1100 Graham Williams>
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
/// Authors: Graham Williams, Zheyuan Xu

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rattle/constants/markdown.dart';
import 'package:rattle/providers/page_controller.dart';
import 'package:rattle/providers/stdout.dart';
import 'package:rattle/r/extract.dart';
import 'package:rattle/utils/show_markdown_file_image.dart';
import 'package:rattle/widgets/page_viewer.dart';
import 'package:rattle/widgets/text_page.dart';

/// The panel displays the instructions or the output.

class SvmDisplay extends ConsumerStatefulWidget {
  const SvmDisplay({super.key});

  @override
  ConsumerState<SvmDisplay> createState() => _SvmDisplayState();
}

class _SvmDisplayState extends ConsumerState<SvmDisplay> {
  @override
  Widget build(BuildContext context) {
    final pageController = ref.watch(
      svmPageControllerProvider,
    );
    String stdout = ref.watch(stdoutProvider);
    String content = '';

    List<Widget> pages = [
      showMarkdownFile(
        context,
        svmIntroFile,
        'assets/svg/svm.svg',
      ),
    ];

    content = rExtract(stdout, 'print(model_svm)');

    if (content.isNotEmpty) {
      pages.add(
        TextPage(
          title: '# SVM Model\n\n'
              'Built using `kernlab::ksvm()`.\n\n',
          content: '\n$content',
        ),
      );
    }

    return PageViewer(
      pageController: pageController,
      pages: pages,
    );
  }
}
