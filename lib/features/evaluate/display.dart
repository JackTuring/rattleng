/// Widget to display the Evaluate introduction.
///
/// Copyright (C) 2024, Togaware Pty Ltd.
///
/// License: GNU General Public License, Version 3 (the "License")
/// https://www.gnu.org/licenses/gpl-3.0.en.html
//
// Time-stamp: <Tuesday 2024-10-15 20:09:06 +1100 Graham Williams>
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

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rattle/constants/markdown.dart';
import 'package:rattle/constants/temp_dir.dart';
import 'package:rattle/providers/page_controller.dart';
import 'package:rattle/providers/stdout.dart';
import 'package:rattle/r/extract_evaluate.dart';
import 'package:rattle/utils/image_exists.dart';
import 'package:rattle/utils/show_markdown_file.dart';
import 'package:rattle/widgets/image_page.dart';
import 'package:rattle/widgets/page_viewer.dart';
import 'package:rattle/widgets/text_page.dart';

/// The EVALUATE panel displays the instructions and then the build output.

class EvaluateDisplay extends ConsumerStatefulWidget {
  const EvaluateDisplay({super.key});

  @override
  ConsumerState<EvaluateDisplay> createState() => _EvaluateDisplayState();
}

class _EvaluateDisplayState extends ConsumerState<EvaluateDisplay> {
  @override
  Widget build(BuildContext context) {
    final pageController = ref.watch(
      evaluatePageControllerProvider,
    ); // Get the PageController from Riverpod

    String stdout = ref.watch(stdoutProvider);

    List<Widget> pages = [showMarkdownFile(evaluateIntroFile, context)];

    String content = '';

    content = rExtractEvaluate(stdout, ref);

    bool showContentMaterial = content.trim().split('\n').length > 1;

    if (showContentMaterial) {
      pages.add(
        TextPage(
          title: '# Error Matrix\n\n',
          content: '\n$content',
        ),
      );
    }

    String handRpartImage = '$tempDir/model_rpart_evaluate_hand.svg';

    String handCtreeImage = '$tempDir/model_ctree_evaluate_hand.svg';

    String handAdaBoostImage = '$tempDir/model_ada_evaluate_hand.svg';

    List<String> existingImages = [];
    List<String> imagesTitles = [];

    if (imageExists(handRpartImage)) {
      existingImages.add(handRpartImage);
      imagesTitles.add('RPART');
    }

    if (imageExists(handCtreeImage)) {
      existingImages.add(handCtreeImage);
      imagesTitles.add('CTREE');
    }

    if (imageExists(handAdaBoostImage)) {
      existingImages.add(handAdaBoostImage);
      imagesTitles.add('ADA BOOST');
    }

    if (existingImages.isNotEmpty) {
      pages.add(
        ImagePage(
          titles: imagesTitles,
          paths: existingImages,
        ),
      );
    }

    return PageViewer(
      pageController: pageController,
      pages: pages,
    );
  }
}
