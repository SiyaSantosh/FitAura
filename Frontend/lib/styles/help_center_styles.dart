import 'package:flutter/material.dart';

class HelpCenterStyles {
  // Colors
  static const Color primaryColor = Color(0xFF704F38); // brownColor
  static const Color beigeBackgroundColor = Color(0xFFF5F1EB);
  static const Color darkTextColor = Color(0xFF1F2029);
  static const Color lightGrayColor = Color(0xFF797979);
  static const Color whiteColor = Colors.white;
  static const Color transparentColor = Colors.transparent;
  static final Color borderColor = Colors.grey[100]!;
  static final Color shadowColor = Colors.black.withOpacity(0.02);

  // Text Styles
  static const TextStyle appBarTitleStyle = TextStyle(
    color: darkTextColor,
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );

  static const TextStyle tabLabelStyle = TextStyle(
    fontWeight: FontWeight.bold, 
    fontSize: 16,
  );

  static const TextStyle tabUnselectedLabelStyle = TextStyle(
    fontWeight: FontWeight.w500, 
    fontSize: 16,
  );

  static const TextStyle faqQuestionStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );

  static const TextStyle faqAnswerStyle = TextStyle(
    color: lightGrayColor,
    fontSize: 14,
    height: 1.5,
  );

  static const TextStyle contactTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );

  static const TextStyle contactDetailStyle = TextStyle(
    color: lightGrayColor,
    fontSize: 14,
  );

  // Decorations
  static final BoxDecoration faqCardDecoration = BoxDecoration(
    color: whiteColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static final BoxDecoration contactCardDecoration = BoxDecoration(
    color: whiteColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static const BoxDecoration contactIconDecoration = BoxDecoration(
    color: beigeBackgroundColor,
    shape: BoxShape.circle,
  );

  static const BoxDecoration bulletDecoration = BoxDecoration(
    color: primaryColor,
    shape: BoxShape.circle,
  );

  // Layout & Spacing
  static const EdgeInsets paddingAll24 = EdgeInsets.all(24.0);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(20.0);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(16.0);
  static const EdgeInsets paddingAll10 = EdgeInsets.all(10.0);
  static const EdgeInsets paddingOnlyLeft8 = EdgeInsets.only(left: 8.0);
  static const EdgeInsets paddingFaqMargin = EdgeInsets.only(bottom: 16);
  static const EdgeInsets paddingContactMargin = EdgeInsets.only(bottom: 16);

  static const Widget sizedBoxHeight12 = SizedBox(height: 12);
  static const Widget sizedBoxHeight16 = SizedBox(height: 16);
  static const Widget sizedBoxWidth12 = SizedBox(width: 12);
  static const Widget sizedBoxWidth16 = SizedBox(width: 16);

  // Sizes
  static const double backIconSize = 20.0;
  static const double tabIndicatorWeight = 3.0;
  static const double contactIconSize = 24.0;
  static const double bulletSize = 8.0;
}
