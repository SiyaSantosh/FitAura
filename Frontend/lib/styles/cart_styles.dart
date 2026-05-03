import 'package:flutter/material.dart';

class CartStyles {
  // Colors
  static const Color primaryColor = Color(0xFF704F38); // brownColor
  static const Color beigeBackgroundColor = Color(0xFFF5F1EB);
  static const Color darkTextColor = Color(0xFF1F2029);
  static const Color lightGrayColor = Color(0xFF797979);
  static const Color whiteColor = Colors.white;
  static const Color dismissibleBgColor = Color(0xFFFFE6E6);
  static const Color errorColor = Colors.red;
  static const Color dividerColor = Colors.grey; // standard divider color
  static const Color transparentColor = Colors.transparent;
  static final Color shadowColor = Colors.black.withOpacity(0.05);

  // Text Styles
  static const TextStyle appBarTitleStyle = TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle productNameStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );

  static const TextStyle productAttributeStyle = TextStyle(
    fontSize: 14,
    color: lightGrayColor,
  );

  static const TextStyle productPriceStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );

  static const TextStyle quantityTextStyle = TextStyle(
    fontSize: 16, 
    fontWeight: FontWeight.bold,
  );

  static const TextStyle summaryLabelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: lightGrayColor,
  );

  static const TextStyle summaryValueStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: darkTextColor,
  );

  static const TextStyle summaryTotalLabelStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );

  static const TextStyle summaryTotalValueStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );

  static const TextStyle checkoutButtonTextStyle = TextStyle(
    color: whiteColor,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  // Decorations
  static final BoxDecoration productImageDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(15),
    color: beigeBackgroundColor,
  );

  static final BoxDecoration bottomSectionDecoration = BoxDecoration(
    color: whiteColor,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        blurRadius: 10,
        offset: const Offset(0, -5),
      ),
    ],
  );

  static final ButtonStyle checkoutButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    elevation: 4,
    shadowColor: primaryColor.withOpacity(0.4),
  );

  static final BoxDecoration dismissibleIconDecoration = BoxDecoration(
    color: errorColor,
    shape: BoxShape.circle,
  );

  static BoxDecoration quantityButtonDecoration({bool isAdd = false, bool isDisabled = false}) {
    return BoxDecoration(
      color: isDisabled ? Colors.grey.shade300 : (isAdd ? primaryColor : whiteColor),
      borderRadius: BorderRadius.circular(8),
      border: (isAdd || isDisabled) ? null : Border.all(color: Colors.grey.shade300),
      boxShadow: (isAdd && !isDisabled) ? [
        BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 4, offset:const Offset(0,2)) 
      ] : []
    );
  }

  // Layout & Spacing
  static const EdgeInsets paddingAll20 = EdgeInsets.all(20);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(24);
  static const EdgeInsets paddingOnlyLeft8Top4 = EdgeInsets.only(left: 8.0, top: 4.0);
  static const EdgeInsets paddingDismissibleRight20 = EdgeInsets.only(right: 20);
  static const EdgeInsets paddingIconAll10 = EdgeInsets.all(10);
  static const EdgeInsets paddingQuantityButton = EdgeInsets.all(4);

  static const Widget sizedBoxHeight4 = SizedBox(height: 4);
  static const Widget sizedBoxHeight8 = SizedBox(height: 8);
  static const Widget sizedBoxHeight12 = SizedBox(height: 12);
  static const Widget sizedBoxHeight24 = SizedBox(height: 24);
  static const double separatorHeight30 = 30.0;

  static const Widget sizedBoxWidth12 = SizedBox(width: 12);
  static const Widget sizedBoxWidth16 = SizedBox(width: 16);
  static const double quantityValueWidth30 = 30.0;

  // Sizes
  static const double backIconSize = 24.0;
  static const double productImageSize = 80.0;
  static const double dismissibleIconSize = 24.0;
  static const double quantityIconSize = 16.0;
  static const double checkoutButtonHeight = 56.0;
  static const double borderRadiusLarge = 30.0;
  static const double borderRadiusMedium = 15.0;
}
