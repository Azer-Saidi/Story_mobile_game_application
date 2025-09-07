import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isSmallPhone(BuildContext context) {
    return screenWidth(context) < 360;
  }

  static bool isMediumPhone(BuildContext context) {
    return screenWidth(context) >= 360 && screenWidth(context) < 400;
  }

  static bool isLargePhone(BuildContext context) {
    return screenWidth(context) >= 400 && screenWidth(context) < 600;
  }

  static bool isTablet(BuildContext context) {
    return screenWidth(context) >= 600;
  }

  // Responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isSmallPhone(context)) {
      return const EdgeInsets.all(12.0);
    } else if (isMediumPhone(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isLargePhone(context)) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  // Responsive font sizes
  static double responsiveFontSize(
    BuildContext context, {
    double small = 12.0,
    double medium = 14.0,
    double large = 16.0,
    double xlarge = 18.0,
  }) {
    if (isSmallPhone(context)) {
      return small;
    } else if (isMediumPhone(context)) {
      return medium;
    } else if (isLargePhone(context)) {
      return large;
    } else {
      return xlarge;
    }
  }

  // Responsive icon sizes
  static double responsiveIconSize(
    BuildContext context, {
    double small = 16.0,
    double medium = 20.0,
    double large = 24.0,
    double xlarge = 28.0,
  }) {
    if (isSmallPhone(context)) {
      return small;
    } else if (isMediumPhone(context)) {
      return medium;
    } else if (isLargePhone(context)) {
      return large;
    } else {
      return xlarge;
    }
  }

  // Responsive avatar sizes
  static double responsiveAvatarSize(
    BuildContext context, {
    double small = 40.0,
    double medium = 50.0,
    double large = 60.0,
    double xlarge = 70.0,
  }) {
    if (isSmallPhone(context)) {
      return small;
    } else if (isMediumPhone(context)) {
      return medium;
    } else if (isLargePhone(context)) {
      return large;
    } else {
      return xlarge;
    }
  }

  // Responsive card heights
  static double responsiveCardHeight(
    BuildContext context, {
    double small = 80.0,
    double medium = 100.0,
    double large = 120.0,
    double xlarge = 140.0,
  }) {
    if (isSmallPhone(context)) {
      return small;
    } else if (isMediumPhone(context)) {
      return medium;
    } else if (isLargePhone(context)) {
      return large;
    } else {
      return xlarge;
    }
  }

  // Responsive button heights
  static double responsiveButtonHeight(
    BuildContext context, {
    double small = 40.0,
    double medium = 48.0,
    double large = 56.0,
    double xlarge = 64.0,
  }) {
    if (isSmallPhone(context)) {
      return small;
    } else if (isMediumPhone(context)) {
      return medium;
    } else if (isLargePhone(context)) {
      return large;
    } else {
      return xlarge;
    }
  }

  // Responsive spacing
  static double responsiveSpacing(
    BuildContext context, {
    double small = 8.0,
    double medium = 12.0,
    double large = 16.0,
    double xlarge = 20.0,
  }) {
    if (isSmallPhone(context)) {
      return small;
    } else if (isMediumPhone(context)) {
      return medium;
    } else if (isLargePhone(context)) {
      return large;
    } else {
      return xlarge;
    }
  }

  // Responsive grid cross axis count
  static int responsiveGridCrossAxisCount(BuildContext context) {
    if (isSmallPhone(context)) {
      return 2;
    } else if (isMediumPhone(context)) {
      return 2;
    } else if (isLargePhone(context)) {
      return 3;
    } else {
      return 4;
    }
  }

  // Responsive child aspect ratio
  static double responsiveChildAspectRatio(BuildContext context) {
    if (isSmallPhone(context)) {
      return 1.2; // Increased to prevent overflow
    } else if (isMediumPhone(context)) {
      return 1.1;
    } else if (isLargePhone(context)) {
      return 1.0;
    } else {
      return 0.9;
    }
  }

  // Responsive bottom navigation bar height
  static double responsiveBottomNavHeight(BuildContext context) {
    if (isSmallPhone(context)) {
      return 60.0;
    } else if (isMediumPhone(context)) {
      return 65.0;
    } else if (isLargePhone(context)) {
      return 70.0;
    } else {
      return 75.0;
    }
  }

  // Responsive text scale factor
  static double responsiveTextScaleFactor(BuildContext context) {
    if (isSmallPhone(context)) {
      return 0.85;
    } else if (isMediumPhone(context)) {
      return 0.9;
    } else if (isLargePhone(context)) {
      return 0.95;
    } else {
      return 1.0;
    }
  }
}

// Responsive text styles
class ResponsiveTextStyles {
  static TextStyle headlineLarge(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.responsiveFontSize(context,
          small: 24.0, medium: 26.0, large: 28.0, xlarge: 32.0),
      fontWeight: FontWeight.bold,
      fontFamily: 'ComicNeue',
    );
  }

  static TextStyle headlineMedium(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.responsiveFontSize(context,
          small: 20.0, medium: 22.0, large: 24.0, xlarge: 26.0),
      fontWeight: FontWeight.bold,
      fontFamily: 'ComicNeue',
    );
  }

  static TextStyle titleLarge(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.responsiveFontSize(context,
          small: 18.0, medium: 20.0, large: 22.0, xlarge: 24.0),
      fontWeight: FontWeight.bold,
      fontFamily: 'ComicNeue',
    );
  }

  static TextStyle titleMedium(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.responsiveFontSize(context,
          small: 16.0, medium: 18.0, large: 20.0, xlarge: 22.0),
      fontWeight: FontWeight.w600,
      fontFamily: 'ComicNeue',
    );
  }

  static TextStyle bodyLarge(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.responsiveFontSize(context,
          small: 14.0, medium: 16.0, large: 18.0, xlarge: 20.0),
      fontFamily: 'ComicNeue',
    );
  }

  static TextStyle bodyMedium(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.responsiveFontSize(context,
          small: 12.0, medium: 14.0, large: 16.0, xlarge: 18.0),
      fontFamily: 'ComicNeue',
    );
  }

  static TextStyle bodySmall(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.responsiveFontSize(context,
          small: 10.0, medium: 12.0, large: 14.0, xlarge: 16.0),
      fontFamily: 'ComicNeue',
    );
  }

  static TextStyle caption(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.responsiveFontSize(context,
          small: 8.0, medium: 10.0, large: 12.0, xlarge: 14.0),
      fontFamily: 'ComicNeue',
    );
  }
}
