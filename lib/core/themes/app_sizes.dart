import 'package:flutter/material.dart';

class AppSizes {
  AppSizes._();

  static const double margin = 18;
  static const double padding = 18;
  static const double radius = 8;

  static const double tabletBreakpoint = 720;
  static const double desktopBreakpoint = 1100;

  static Size size(BuildContext context) => MediaQuery.sizeOf(context);
  static double screenWidth(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double screenHeight(BuildContext context) => MediaQuery.sizeOf(context).height;
  static double appBarHeight() => AppBar().preferredSize.height;
  static EdgeInsets viewPadding(BuildContext context) => MediaQuery.of(context).padding;

  static bool isPhone(BuildContext context) => screenWidth(context) < tabletBreakpoint;
  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= tabletBreakpoint && screenWidth(context) < desktopBreakpoint;
  static bool isDesktop(BuildContext context) => screenWidth(context) >= desktopBreakpoint;
}
