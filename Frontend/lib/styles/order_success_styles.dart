import 'package:flutter/material.dart';

class OrderSuccessStyles {
  // Colors
  static const Color primaryColor = Color(0xFF704F38);
  static const Color darkTextColor = Color(0xFF1F2029);
  static const Color lightGrayColor = Color(0xFF797979);
  static const Color whiteColor = Colors.white;
  static const Color transparentColor = Colors.transparent;

  // Text Styles
  static const TextStyle appBarTitleStyle = TextStyle(
    color: darkTextColor,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle successTitleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );

  static const TextStyle successSubtitleStyle = TextStyle(
    fontSize: 16,
    color: lightGrayColor,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: whiteColor,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  // Decorations
  static const BoxDecoration successIconDecoration = BoxDecoration(
    color: primaryColor,
    shape: BoxShape.circle,
  );

  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    ),
    elevation: 0,
  );

  // Layout & Spacing
  static const EdgeInsets paddingAll24 = EdgeInsets.all(24);
  
  static const Widget sizedBoxHeight12 = SizedBox(height: 12);
  static const Widget sizedBoxHeight24 = SizedBox(height: 24);
  static const Widget sizedBoxHeight32 = SizedBox(height: 32);
  
  static const double successIconSize = 100.0;
  static const double successIconInsideSize = 50.0;
  static const double buttonHeight = 56.0;
}
