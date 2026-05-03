import 'package:flutter/material.dart';

class CustomerHomeStyles {
  // Colors
  static const Color primaryColor = Color(0xFF704F38); // brownColor
  static const Color beigeBackgroundColor = Color(0xFFF5F1EB);
  static const Color darkTextColor = Color(0xFF1F2029);
  static const Color lightGrayColor = Color(0xFF797979);
  static const Color whiteColor = Colors.white;
  static const Color lightBrownColor = Color(0xFFA68470);
  static const Color errorColor = Colors.red;
  static const Color transparentColor = Colors.transparent;
  static final Color shadowColor = Colors.black.withOpacity(0.05);
  static const Color ratingColor = Colors.amber;
  static final Color timerBoxColor = beigeBackgroundColor;

  // Text Styles
  static const TextStyle greetingLabelStyle = TextStyle(
    fontSize: 12,
    color: lightGrayColor,
  );

  static const TextStyle userNameStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: darkTextColor,
  );

  static const TextStyle searchHintStyle = TextStyle(
    color: lightGrayColor,
  );

  static const TextStyle searchTextStyle = TextStyle(
    color: darkTextColor,
  );

  static const TextStyle bannerTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );

  static const TextStyle bannerTitleWebStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );

  static const TextStyle bannerSubtitleStyle = TextStyle(
    fontSize: 12,
    color: lightGrayColor,
    height: 1.5,
  );

  static const TextStyle bannerSubtitleWebStyle = TextStyle(
    fontSize: 18,
    color: lightGrayColor,
    height: 1.5,
  );

  static const TextStyle bannerButtonTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bannerButtonWebTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle sectionHeaderStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );

  static const TextStyle seeAllButtonStyle = TextStyle(
    color: primaryColor,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle categoryLabelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: darkTextColor,
  );

  static const TextStyle categoryWebLabelStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: darkTextColor,
  );

  static const TextStyle storeNameStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: darkTextColor,
  );

  static const TextStyle storeRatingStyle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: darkTextColor,
  );

  static const TextStyle productNameStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );

  static const TextStyle productPriceStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle productStoreNameStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xB3704F38), // primaryColor with opacity
    letterSpacing: 0.5,
  );

  static const TextStyle timerLabelStyle = TextStyle(
    color: lightGrayColor, 
    fontSize: 12,
  );

  static const TextStyle timerValueStyle = TextStyle(
    color: primaryColor,
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );

  static const TextStyle filterTitleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );

  static const TextStyle filterSectionTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: darkTextColor,
  );

  static const TextStyle priceRangeLabelStyle = TextStyle(
    fontSize: 14,
    color: primaryColor,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle resetButtonTextStyle = TextStyle(
    color: darkTextColor,
  );

  static const TextStyle applyButtonTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: whiteColor,
  );

  static const TextStyle dialogTitleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
    letterSpacing: -0.5,
  );

  static const TextStyle dialogSubtitleStyle = TextStyle(
    fontSize: 14,
    color: lightGrayColor,
    height: 1.5,
  );

  // Decorations
  static const BoxDecoration notificationIconDecoration = BoxDecoration(
    color: beigeBackgroundColor,
    shape: BoxShape.circle,
  );

  static final BoxDecoration searchBarDecoration = BoxDecoration(
    color: whiteColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey.withOpacity(0.2)),
  );

  static final BoxDecoration filterIconDecoration = BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(16),
  );

  static final BoxDecoration bannerDecoration = BoxDecoration(
    color: beigeBackgroundColor,
    borderRadius: BorderRadius.circular(24),
  );

  static ButtonStyle bannerButtonStyle({bool isWeb = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 40 : 24, 
        vertical: isWeb ? 20 : 12
      ),
      elevation: 0,
    );
  }

  static const BoxDecoration categoryIconDecoration = BoxDecoration(
    color: beigeBackgroundColor,
    shape: BoxShape.circle,
  );

  static final BoxDecoration storeCardDecoration = BoxDecoration(
    color: whiteColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static final BoxDecoration productCardDecoration = BoxDecoration(
    color: whiteColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static final BoxDecoration favoriteIconDecoration = BoxDecoration(
    color: whiteColor,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static final BoxDecoration bottomNavBarContainerDecoration = BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(40),
  );

  static BoxDecoration navItemActiveDecoration(bool isSelected) {
    return BoxDecoration(
      color: isSelected ? whiteColor : transparentColor,
      shape: BoxShape.circle,
    );
  }

  static final BoxDecoration timerBoxDecoration = BoxDecoration(
    color: beigeBackgroundColor,
    borderRadius: BorderRadius.circular(4),
  );

  static final BoxDecoration filterSheetDecoration = BoxDecoration(
    color: whiteColor,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
  );

  static final BoxDecoration dragHandleDecoration = BoxDecoration(
    color: Colors.grey[300],
    borderRadius: BorderRadius.circular(2),
  );

  static ButtonStyle resetButtonStyle = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    side: BorderSide(color: Colors.grey[300]!),
  );

  static ButtonStyle applyButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: whiteColor,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 0,
  );

  static final BoxDecoration dialogDecoration = BoxDecoration(
    color: whiteColor,
    borderRadius: BorderRadius.circular(32),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  // Layout & Spacing
  static const EdgeInsets paddingSymmetricH24V16 = EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
  static const EdgeInsets paddingH24 = EdgeInsets.symmetric(horizontal: 24.0);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(12.0);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(24.0);
  static const EdgeInsets paddingTimerBox = EdgeInsets.symmetric(horizontal: 6, vertical: 4);
  static const EdgeInsets paddingV20H24 = EdgeInsets.symmetric(vertical: 20, horizontal: 24);
  static const EdgeInsets paddingNavContainer = EdgeInsets.all(12);

  static const Widget sizedBoxHeight4 = SizedBox(height: 4);
  static const Widget sizedBoxHeight8 = SizedBox(height: 8);
  static const Widget sizedBoxHeight12 = SizedBox(height: 12);
  static const Widget sizedBoxHeight16 = SizedBox(height: 16);
  static const Widget sizedBoxHeight24 = SizedBox(height: 24);
  static const Widget sizedBoxHeight32 = SizedBox(height: 32);
  static const Widget sizedBoxHeight110 = SizedBox(height: 110);

  static const Widget sizedBoxWidth4 = SizedBox(width: 4);
  static const Widget sizedBoxWidth8 = SizedBox(width: 8);
  static const Widget sizedBoxWidth12 = SizedBox(width: 12);
  static const Widget sizedBoxWidth16 = SizedBox(width: 16);

  // Sizes
  static const double searchIconSize = 24.0;
  static const double notificationIconSize = 24.0;
  static const double categoryIconSizeApp = 42.0;
  static const double categoryIconSizeWeb = 56.0;
  static const double storeIconSize = 40.0;
  static const double favoriteIconSize = 16.0;
  static const double navIconSize = 24.0;
  static const double dragHandleWidth = 40.0;
  static const double dragHandleHeight = 4.0;
  static const double bannerHeightApp = 200.0;
  static const double bannerHeightWeb = 350.0;
  static const double bannerImageHeightApp = 200.0;
  static const double bannerImageWidthApp = 150.0;
  static const double bannerImageHeightWeb = 320.0;
  static const double bannerImageWidthWeb = 500.0;
  static const double navBarHeight = 70.0;
  static const double fabSize = 70.0;
  static const double fabIconSize = 32.0;

  // Notification Specific Styles
  static BoxDecoration notificationCardDecoration(bool isRead) {
    return BoxDecoration(
      color: isRead ? whiteColor : primaryColor.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      border: isRead 
          ? Border.all(color: transparentColor) 
          : Border.all(color: primaryColor.withOpacity(0.2), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static const TextStyle notificationTitleStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: darkTextColor,
  );

  static TextStyle notificationMessageStyle(bool isRead) {
    return TextStyle(
      fontSize: 14,
      fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
      color: darkTextColor.withOpacity(isRead ? 0.7 : 1.0),
    );
  }

  static const TextStyle notificationTimeStyle = TextStyle(
    fontSize: 12,
    color: lightGrayColor,
    fontWeight: FontWeight.w400,
  );

  static final BoxDecoration unreadIndicatorDecoration = BoxDecoration(
    color: primaryColor,
    shape: BoxShape.circle,
    border: Border.all(color: whiteColor, width: 2),
  );
}
