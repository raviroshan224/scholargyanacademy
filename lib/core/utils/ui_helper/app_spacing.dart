import 'package:flutter/material.dart';

/** Using a Percentage of Screen Width (MediaQuery.of(context).size.width * 0.04): */

/// const Widget horizontalSpaceTiny = SizedBox(width: MediaQuery.of(context).size.width * 0.04);
///This approach creates a SizedBox with a width that's a percentage (4%) of the screen width.
/// It's a flexible solution because it adapts to different screen sizes and orientations.
/// This can be particularly useful for responsive design, where you want your
/// spacing to be proportional to the screen width.
///

/// Use the percentage of screen width approach when you want spacing that
/// scales with the screen size, making your UI more adaptable to different
/// devices and orientations.
/// Use the fixed size approach when you have specific design requirements
/// that demand consistent spacing regardless of the screen size.

class AppSpacing {
  static var propertyCardHeight = 330.0;

  // Padding sizes
  static double get tinyPadding => 4.0;

  static double get   smallPadding => 8.0;

  static double get averagePadding => 12.0;

  static double get mediumPadding => 16.0;

  static double get largePadding => 24.0;

  static double get veryLargePadding => 48.0;

  static double get massivePadding => 72.0;

  // Horizontal space widgets
  static Widget get horizontalSpaceTiny => SizedBox(width: tinyPadding);

  static Widget get horizontalSpaceSmall => SizedBox(width: smallPadding);

  static Widget get horizontalSpaceAverage => SizedBox(width: averagePadding);

  static Widget get horizontalSpaceMedium => SizedBox(width: mediumPadding);

  static Widget get horizontalSpaceLarge => SizedBox(width: largePadding);

  static Widget get horizontalSpaceVeryLarge =>
      SizedBox(width: veryLargePadding);

  static Widget get horizontalSpaceMassive => SizedBox(width: massivePadding);

  // Vertical space widgets
  static Widget get verticalSpaceTiny => SizedBox(height: tinyPadding);

  static Widget get verticalSpaceSmall => SizedBox(height: smallPadding);

  static Widget get verticalSpaceAverage => SizedBox(height: averagePadding);

  static Widget get verticalSpaceMedium => SizedBox(height: mediumPadding);

  static Widget get verticalSpaceLarge => SizedBox(height: largePadding);

  static Widget get verticalSpaceVeryLarge =>
      SizedBox(height: veryLargePadding);

  static Widget get verticalSpaceMassive => SizedBox(height: massivePadding);

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Dynamic spacing based on screen width
  static Widget horizontalSpacePercentage(
      BuildContext context, double percentage) {
    return SizedBox(width: MediaQuery.of(context).size.width * percentage);
  }

  // Dynamic spacing based on screen height
  static Widget verticalSpacePercentage(
      BuildContext context, double percentage) {
    return SizedBox(height: MediaQuery.of(context).size.height * percentage);
  }

  /// Search Bar Padding
  static var searchBarPadding =
      const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0);

  static double pagePadding = 12.0;
}

///  For a small to medium-sized project, your current approach is perfectly
///  reasonable. If you find that your codebase becomes harder to manage or
///  experiences naming conflicts in the future, consider transitioning to a
///  class-based organization.
