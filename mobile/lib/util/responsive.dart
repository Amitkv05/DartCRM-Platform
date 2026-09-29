import 'package:flutter/material.dart';

class Responsive {
  static bool isMediumMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 850 &&
      MediaQuery.of(context).size.width >= 390;
  static bool isSmallMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 390;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100 &&
      MediaQuery.of(context).size.width >= 850;

  // static bool isDesktop(BuildContext context) =>
  //     MediaQuery.of(context).size.width >= 1100;
}
