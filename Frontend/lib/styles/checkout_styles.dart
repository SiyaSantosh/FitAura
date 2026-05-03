import 'package:flutter/material.dart';

class CheckoutStyles {
  // Colors
  static const Color primaryColor = Color(0xFF704F38); // brownColor
  static const Color beigeBackgroundColor = Color(0xFFF5F1EB);
  static const Color darkTextColor = Color(0xFF1F2029);
  static const Color lightGrayColor = Color(0xFF797979);
  static const Color whiteColor = Colors.white;
  static const Color dividerColor = Color(0xFFEEEEEE);
  static const Color errorColor = Colors.red;
  static const Color transparentColor = Colors.transparent;
  static final Color shadowColor = Colors.black.withOpacity(0.05);
  static final Color modalShadowColor = Colors.black.withOpacity(0.02);

  // Text Styles
  static const TextStyle appBarTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );

  static const TextStyle sectionHeaderStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontWeight: FontWeight.bold, 
    fontSize: 16,
  );

  static const TextStyle cardSubtitleStyle = TextStyle(
    color: lightGrayColor, 
    fontSize: 14,
  );

  static const TextStyle changeButtonStyle = TextStyle(
    color: primaryColor, 
    fontWeight: FontWeight.bold, 
    fontSize: 12,
  );

  static const TextStyle storeHeaderStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
    color: primaryColor,
  );

  static const TextStyle itemNameStyle = TextStyle(
    fontWeight: FontWeight.bold, 
    fontSize: 14,
  );

  static const TextStyle itemAttrStyle = TextStyle(
    color: lightGrayColor, 
    fontSize: 13,
  );

  static const TextStyle itemPriceStyle = TextStyle(
    fontWeight: FontWeight.bold, 
    fontSize: 16,
  );

  static const TextStyle storeTotalLabelStyle = TextStyle(
    fontWeight: FontWeight.w600,
    color: lightGrayColor,
    fontSize: 14,
  );

  static const TextStyle storeTotalValueStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: darkTextColor,
  );

  static const TextStyle bottomBarLabelStyle = TextStyle(
    color: lightGrayColor, 
    fontSize: 14,
  );

  static const TextStyle bottomBarValueStyle = TextStyle(
    fontSize: 18, 
    fontWeight: FontWeight.bold, 
    color: darkTextColor,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: whiteColor,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle dialogTitleStyle = TextStyle(
    fontSize: 18, 
    fontWeight: FontWeight.bold,
  );

  // Decorations
  static const BoxDecoration iconContainerDecoration = BoxDecoration(
    color: beigeBackgroundColor,
    shape: BoxShape.circle,
  );

  static final BoxDecoration storeHeaderDecoration = BoxDecoration(
    color: beigeBackgroundColor,
    borderRadius: BorderRadius.circular(8),
  );

  static final BoxDecoration itemImageDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    color: beigeBackgroundColor,
  );

  static final BoxDecoration bottomBarDecoration = BoxDecoration(
    color: whiteColor,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        blurRadius: 20,
        offset: const Offset(0, -5),
      ),
    ],
  );

  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    elevation: 0,
  );

  static InputDecoration textFieldDecoration(String hint, {String? errorText}) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
    );
  }

  // Layout & Spacing
  static const EdgeInsets paddingAll24 = EdgeInsets.all(24);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(12);
  static const EdgeInsets paddingSymmetricHorizontal20Vertical10 = EdgeInsets.symmetric(horizontal: 20, vertical: 10);
  static const EdgeInsets paddingStoreHeader = EdgeInsets.symmetric(vertical: 8, horizontal: 12);
  static const EdgeInsets paddingCardContent = EdgeInsets.symmetric(horizontal: 16);

  static const Widget sizedBoxHeight4 = SizedBox(height: 4);
  static const Widget sizedBoxHeight8 = SizedBox(height: 8);
  static const Widget sizedBoxHeight12 = SizedBox(height: 12);
  static const Widget sizedBoxHeight16 = SizedBox(height: 16);
  static const Widget sizedBoxHeight24 = SizedBox(height: 24);
  static const Widget sizedBoxHeight32 = SizedBox(height: 32);

  static const Widget sizedBoxWidth8 = SizedBox(width: 8);
  static const Widget sizedBoxWidth12 = SizedBox(width: 12);
  static const Widget sizedBoxWidth16 = SizedBox(width: 16);

  // Sizes
  static const double backIconSize = 24.0;
  static const double storeIconSize = 20.0;
  static const double cardIconSize = 24.0;
  static const double itemImageSize = 70.0;
  static const double buttonHeight = 56.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double shelfIndicatorHeight = 80.0;
}
