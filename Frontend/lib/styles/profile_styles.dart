import 'package:flutter/material.dart';

class ProfileStyles {
  // Colors
  static const Color primaryColor = Color(0xFF704F38); // brownColor
  static const Color beigeBackgroundColor = Color(0xFFF5F1EB);
  static const Color darkTextColor = Color(0xFF1F2029);
  static const Color lightGrayColor = Color(0xFF797979);
  static const Color whiteColor = Colors.white;
  static const Color transparentColor = Colors.transparent;
  static final Color barrierColor = Colors.black.withOpacity(0.5);
  static final Color shadowColor = Colors.black.withOpacity(0.15); // For dialog
  static final Color weakShadowColor = Colors.black.withOpacity(0.1); // For profile image
  static final Color borderColor = Colors.grey[100]!;


  // Text Styles
  static const TextStyle logoutTitleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
    letterSpacing: -0.5,
  );

  static const TextStyle logoutSubtitleStyle = TextStyle(
    fontSize: 14,
    color: lightGrayColor,
    height: 1.5,
  );
  
  static const TextStyle cancelButtonStyle = TextStyle(
    color: darkTextColor,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle logoutButtonTextStyle = TextStyle(
    color: whiteColor,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle userNameStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );

  static const TextStyle menuItemStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: darkTextColor,
  );

  // Decorations
  static final BoxDecoration logoutDialogDecoration = BoxDecoration(
    color: whiteColor,
    borderRadius: BorderRadius.circular(32),
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        blurRadius: 30,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static final BoxDecoration profileImageDecoration = BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: whiteColor, width: 2),
    boxShadow: [
      BoxShadow(
        color: weakShadowColor,
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static final BoxDecoration editIconDecoration = BoxDecoration(
    color: primaryColor,
    shape: BoxShape.circle,
    border: Border.all(color: whiteColor, width: 2),
  );

  static final BoxDecoration menuItemDecoration = BoxDecoration(
    border: Border(bottom: BorderSide(color: borderColor)),
  );

  // Button Styles
  static final ButtonStyle cancelButtonStyleFrom = OutlinedButton.styleFrom(
    side: BorderSide(color: lightGrayColor.withOpacity(0.5), width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(26),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 14,
    ),
  );

  static final ButtonStyle logoutButtonStyleFrom = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(26),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 14,
    ),
    elevation: 0,
  );

  // Layout & Spacing
  static const EdgeInsets paddingHorizontal24 = EdgeInsets.symmetric(horizontal: 24.0);
  static const EdgeInsets paddingVertical16 = EdgeInsets.symmetric(vertical: 16.0);
  static const EdgeInsets paddingDialogMobile = EdgeInsets.all(20.0);
  static const EdgeInsets paddingDialogDesktop = EdgeInsets.all(32.0);
  static const EdgeInsets paddingButtonGeneric = EdgeInsets.symmetric(horizontal: 20, vertical: 14); // unused if button style covers it

  static const Widget sizedBoxHeight8 = SizedBox(height: 8);
  static const Widget sizedBoxHeight10 = SizedBox(height: 10);
  static const Widget sizedBoxHeight16 = SizedBox(height: 16);
  static const Widget sizedBoxHeight20 = SizedBox(height: 20);
  static const Widget sizedBoxHeight32 = SizedBox(height: 32);
  static const Widget sizedBoxHeight50 = SizedBox(height: 50);

  static const Widget sizedBoxWidth8 = SizedBox(width: 8);
  static const Widget sizedBoxWidth12 = SizedBox(width: 12);
  static const Widget sizedBoxWidth16 = SizedBox(width: 16);
  
  // Constraints
  static const BoxConstraints dialogConstraintsDesktop = BoxConstraints(maxWidth: 500);
}
