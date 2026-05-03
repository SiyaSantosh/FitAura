import 'package:flutter/material.dart';
import 'app_colors.dart';

class StoreProductsStyles {
  static const Color primaryColor = AppColors.brown;
  static const Color secondaryColor = AppColors.beige;
  static const Color textColor = AppColors.darkText;
  static const Color grayColor = AppColors.gray;
  static const Color lightGrayColor = AppColors.lightGray;
  static const Color whiteColor = AppColors.white;
  static const Color transparentColor = Colors.transparent;
  static const Color chipBackground = Color(0xFFA68470);

  static const double spacingTiny = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingExtraLarge = 24.0;
  static const double spacingXXL = 32.0;

  static const Widget vSpaceDragHandle = SizedBox(height: dragHandleTopMargin);
  static const Widget vSpaceTiny = SizedBox(height: spacingTiny);
  static const Widget vSpaceSmall = SizedBox(height: spacingSmall);
  static const Widget vSpaceMedium = SizedBox(height: spacingMedium);
  static const Widget vSpaceLarge = SizedBox(height: spacingLarge);
  static const Widget vSpaceExtraLarge = SizedBox(height: spacingExtraLarge);
  static const Widget vSpaceSection = SizedBox(height: 32.0);
  static const Widget vSpaceXXL = SizedBox(height: spacingXXL);

  static const Widget hSpaceSmall = SizedBox(width: spacingSmall);
  static const Widget hSpaceMedium = SizedBox(width: spacingMedium);
  static const Widget hSpaceLarge = SizedBox(width: spacingLarge);
  static const Widget hSpaceSection = SizedBox(width: spacingLarge);

  static const EdgeInsets screenPadding = EdgeInsets.all(spacingLarge);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: spacingLarge);
  static const EdgeInsets verticalPadding = EdgeInsets.symmetric(vertical: spacingSmall);
  static const EdgeInsets searchBarPadding = EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingSmall);
  static const EdgeInsets filterPadding = EdgeInsets.symmetric(horizontal: spacingExtraLarge);
  static const EdgeInsets filterContentPadding = EdgeInsets.symmetric(horizontal: spacingExtraLarge);
  static const EdgeInsets filterFooterPadding = EdgeInsets.all(spacingExtraLarge);
  static const EdgeInsets cardPadding = EdgeInsets.all(spacingMedium);

  static const TextStyle appBarTitleStyle = TextStyle(
    color: textColor,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headerStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textColor,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
    color: textColor,
  );

  static const TextStyle cardPriceStyle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: primaryColor,
  );

  static const TextStyle hintStyle = TextStyle(
    color: lightGrayColor,
    fontSize: 13,
  );

  static const TextStyle chipLabelStyle = TextStyle(
    fontSize: 13,
  );

  static const TextStyle priceRangeLabelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static final BoxDecoration searchBarDecoration = BoxDecoration(
    color: whiteColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.withOpacity(0.2)),
  );

  static final BoxDecoration filterIconDecoration = BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(12),
  );

  static final BoxDecoration productCardDecoration = BoxDecoration(
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

  static const BorderRadius cardTopRadius = BorderRadius.vertical(top: Radius.circular(16));

  static final BoxDecoration filterBottomSheetDecoration = BoxDecoration(
    color: whiteColor,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
  );

  static const double filterBottomSheetHeightFactor = 0.75;

  static final BoxDecoration dragHandleDecoration = BoxDecoration(
    color: Colors.grey[300],
    borderRadius: BorderRadius.circular(2),
  );

  static const double dragHandleWidth = 40.0;
  static const double dragHandleHeight = 4.0;
  static const double dragHandleTopMargin = 12.0;

  static const double wrapSpacing = 12.0;
  static const double wrapRunSpacing = 12.0;

  static ButtonStyle actionButtonStyle({required bool isPrimary}) {
    if (isPrimary) {
      return ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: whiteColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      );
    } else {
      return OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: Colors.grey[300]!),
      );
    }
  }

  static TextStyle actionButtonTextStyle({required bool isPrimary}) {
    return TextStyle(
      fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
      color: isPrimary ? whiteColor : textColor,
    );
  }

  static final VisualDensity compactDensity = VisualDensity.compact;

  static Color chipLabelColor(bool isSelected) => isSelected ? whiteColor : textColor;
  static FontWeight chipLabelWeight(bool isSelected) => isSelected ? FontWeight.bold : FontWeight.normal;
  static Color chipBackgroundColor(bool isSelected) => isSelected ? primaryColor : chipBackground.withOpacity(0.15);
  static Color chipBorderColor(bool isSelected) => isSelected ? primaryColor : Colors.transparent;

  static const SliverGridDelegate productGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.7,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
  );

  static const double fabSize = 70.0;
  static const double fabIconSize = 32.0;
  static const double fabElevation = 4.0;
  static const EdgeInsets fabMargin = EdgeInsets.only(bottom: 20, right: 10);

  static const double stickyHeaderHeight = 60.0;

  static const double searchFieldHeight = 44.0;
  static const double filterButtonSize = 44.0;

  static const double iconSizeSmall = 20.0;

  static const IconData closeIcon = Icons.close;
  static const IconData searchIcon = Icons.search;
  static const IconData filterIcon = Icons.tune;
  static const IconData backIcon = Icons.arrow_back;
  static const IconData cartIcon = Icons.shopping_cart;
  static const IconData errorIcon = Icons.image_not_supported;

  static OutlinedBorder chipShape(bool isSelected) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: chipBorderColor(isSelected),
      ),
    );
  }

  static const InputDecoration searchInputDecoration = InputDecoration(
    hintText: 'Search in store...',
    hintStyle: hintStyle,
    border: InputBorder.none,
    isDense: true,
  );

  static const ShapeBorder fabShape = CircleBorder();

  static const TextStyle noProductsFoundStyle = TextStyle(
    fontSize: 16,
    color: grayColor,
  );

  static const BoxFit imageFit = BoxFit.cover;
}
