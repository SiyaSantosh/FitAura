
import 'package:flutter/material.dart';
import 'app_colors.dart';

class StoreInformationStyles {
  // Colors
  static const Color primaryColor = AppColors.brown;
  static const Color lightGrayColor = AppColors.lightGray;
  static const Color textColor = AppColors.darkText;
  static const Color backgroundColor = AppColors.beige;
  static const Color whiteColor = AppColors.white;
  static const Color errorColor = AppColors.errorAccent;
  static const Color tooltipErrorColor = Color(0xFFFF6B35);
  static const Color tooltipTextColor = Color(0xFF333333);
  static final Color placeholderIconColor = Colors.grey[400]!;
  static final Color placeholderBackgroundColor = Colors.grey[200]!;
  
  // Spacing
  static const double spacingTiny = 4.0;
  static const double spacingSmall = 6.0;
  static const double spacingStandard = 8.0;
  static const double spacingMedium = 10.0;
  static const double spacingLarge = 18.0;
  static const double spacingExtraLarge = 30.0;
  static const double spacingHeaderMobile = 40.0;
  static const double spacingHeader = 30.0;
  
  // Animation Constants
  static const Duration pageAnimationDuration = Duration(milliseconds: 800);
  static const Duration fieldAnimationDuration = Duration(milliseconds: 200);
  static const Curve animationCurve = Curves.easeOut;
  static const double buttonScalePressed = 0.98;
  static const double buttonScaleNormal = 1.0;

  // Layout Constants
  static const EdgeInsets mobileScreenPadding = EdgeInsets.symmetric(horizontal: 24.0);
  static const EdgeInsets webScreenPadding = EdgeInsets.symmetric(horizontal: 48, vertical: 48);
  static const EdgeInsets webContainerPadding = EdgeInsets.symmetric(horizontal: 40, vertical: 32);
  static const EdgeInsets tooltipPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  static const double submitButtonHeight = 56.0;
  static const double tooltipIconContainerSize = 20.0;
  
  // Icon Sizes
  static const double iconSizeSmall = 14.0;
  static const double iconSizeMedium = 16.0;
  static const double iconSizeRegular = 20.0;
  
  // Common Spacers
  static const SizedBox spaceTiny = SizedBox(height: spacingTiny);
  static const SizedBox spaceSmall = SizedBox(height: spacingSmall);
  static const SizedBox spaceStandard = SizedBox(height: spacingStandard);
  static const SizedBox spaceMedium = SizedBox(height: spacingMedium);
  static const SizedBox spaceLarge = SizedBox(height: spacingLarge);
  static const SizedBox spaceExtraLarge = SizedBox(height: spacingExtraLarge);
  static const SizedBox spaceHeaderMobile = SizedBox(height: spacingHeaderMobile);
  static const SizedBox spaceHeader = SizedBox(height: spacingHeader);
  static const SizedBox hSpaceTiny = SizedBox(width: spacingTiny);
  static const SizedBox hSpaceSmall = SizedBox(width: spacingSmall); // 6
  static const SizedBox hSpaceMedium = SizedBox(width: 8); // 8
  
  // Responsive Spacers
  static SizedBox headerSpacer(bool isMobile) => SizedBox(height: isMobile ? 40 : 30);
  static SizedBox sectionSpacer(bool isMobile) => SizedBox(height: isMobile ? 24 : 18);
  static SizedBox fieldSpacer(bool isMobile) => SizedBox(height: isMobile ? 12 : 10);
  static SizedBox footerSpacer(bool isMobile) => SizedBox(height: isMobile ? 44 : 30);
  
  
  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 13,
    color: lightGrayColor,
    height: 1.4,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textColor,
  );

  static const TextStyle inputTextStyle = TextStyle(
    fontSize: 14,
  );

  static const TextStyle hintStyle = TextStyle(
    color: lightGrayColor,
    fontSize: 14,
  );
  
  static const TextStyle tooltipTextStyle = TextStyle(
    color: tooltipTextColor,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: whiteColor,
  );

  // Decorations
  static final BoxDecoration webContainerDecoration = BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 30,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static final BoxDecoration errorTooltipDecoration = BoxDecoration(
    color: whiteColor,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static final BoxDecoration errorIconDecoration = BoxDecoration(
    color: tooltipErrorColor,
    borderRadius: BorderRadius.circular(4),
  );

  static BoxDecoration logoPlaceholderDecoration(bool isError) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.grey[200],
      border: Border.all(
        color: isError ? errorColor : Colors.transparent,
        width: 2,
      ),
    );
  }

  static const BoxDecoration editIconDecoration = BoxDecoration(
    color: primaryColor,
    shape: BoxShape.circle,
  );

  // Input Decoration
  static InputDecoration inputDecoration({
    required String hintText,
    required IconData icon,
    String? errorText,
    bool isError = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: hintStyle,
      filled: true,
      fillColor: whiteColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(
          color: isError ? errorColor : lightGrayColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(
          color: isError ? errorColor : lightGrayColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(
          color: isError ? errorColor : primaryColor,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      prefixIcon: icon == Icons.description_outlined
          ? Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Icon(
                icon,
                color: lightGrayColor.withOpacity(0.6),
                size: 20,
              ),
            )
          : Icon(
              icon,
              color: lightGrayColor.withOpacity(0.6),
              size: 20,
            ),
    );
  }

  // Button Styles
  static ButtonStyle submitButtonStyle(bool isPressed, bool isLoading) {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: whiteColor,
      elevation: isPressed ? 2 : 4,
      shadowColor: primaryColor.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      minimumSize: const Size(double.infinity, 56),
    ).copyWith(
      overlayColor: MaterialStateProperty.resolveWith(
        (states) => Colors.black.withOpacity(0.1),
      ),
    );
  }
}
