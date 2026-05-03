
import 'package:flutter/material.dart';
import 'app_colors.dart';

class ProfileCompletionStyles {
  // Colors
  static const Color primaryColor = AppColors.brown;
  static const Color lightGrayColor = AppColors.lightGray;
  static const Color textColor = AppColors.darkText;
  static const Color backgroundColor = AppColors.beige;
  static const Color whiteColor = AppColors.white;
  static const Color errorColor = AppColors.error;
  static const Color errorTooltipColor = Color(0xFFFF6B35);
  static const Color tooltipTextColor = Color(0xFF333333);
  static final Color placeholderIconColor = Colors.grey[400]!;
  static final Color placeholderBackgroundColor = Colors.grey[200]!;

  // Spacing & Layout
  static const double spacingTiny = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 20.0;
  static const double spacingExtraLarge = 35.0; // Averaged between mobile/web
  
  static const EdgeInsets mobileScreenPadding = EdgeInsets.symmetric(horizontal: 24.0);
  static const EdgeInsets webScreenPadding = EdgeInsets.symmetric(horizontal: 48, vertical: 48);
  static const EdgeInsets webContainerPadding = EdgeInsets.all(40);
  static const EdgeInsets tooltipPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  static const EdgeInsets inputContentPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  
  // Dimensions
  static const double webCardMaxWidth = 450.0;
  static const double submitButtonHeight = 56.0;
  static const double tooltipIconContainerSize = 20.0;
  static const double iconSizeSmall = 14.0;
  static const double iconSizeMedium = 16.0;
  static const double iconSizeRegular = 20.0;
  static const double profilePicSizeMobile = 100.0;
  static const double profilePicSizeWeb = 80.0;
  static const double profileIconSizeMobile = 60.0;
  static const double profileIconSizeWeb = 48.0;

  // Animations
  static const Duration pageAnimationDuration = Duration(milliseconds: 800);
  static const Duration fieldAnimationDuration = Duration(milliseconds: 200);
  static const Curve animationCurve = Curves.easeOut;

  // Text Styles
  static const TextStyle headerStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle subHeaderStyle = TextStyle(
    fontSize: 14,
    color: lightGrayColor,
    height: 1.5,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textColor,
  );

  static const TextStyle inputTextStyle = TextStyle(
    fontSize: 14,
  );

  static TextStyle hintTextStyle = TextStyle(
    color: lightGrayColor.withOpacity(0.5),
    fontSize: 14,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: whiteColor,
  );

  static const TextStyle tooltipTextStyle = TextStyle(
    color: tooltipTextColor,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // Decorations
  static final BoxDecoration webCardDecoration = BoxDecoration(
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
    color: errorTooltipColor,
    borderRadius: BorderRadius.circular(4),
  );
  
  static const BoxDecoration editIconDecoration = BoxDecoration(
    color: primaryColor,
    shape: BoxShape.circle,
  );

  static BoxDecoration profilePlaceholderDecoration({required bool isError, required bool hasImage, ImageProvider? image}) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: placeholderBackgroundColor,
      border: Border.all(
        color: isError ? errorColor : Colors.transparent,
        width: 2,
      ),
      image: hasImage && image != null
          ? DecorationImage(
              image: image,
              fit: BoxFit.cover,
            )
          : null,
    );
  }

  // Input Decoration
  static InputDecoration inputDecoration({
    required String hintText,
    required IconData icon,
    String? errorText,
    Widget? suffixIcon,
    String? counterText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: hintTextStyle,
      counterText: counterText,
      filled: true,
      fillColor: whiteColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(
          color: errorText != null ? errorColor : lightGrayColor.withOpacity(0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(
          color: errorText != null ? errorColor : lightGrayColor.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: inputContentPadding,
      prefixIcon: Icon(
        icon,
        color: lightGrayColor.withOpacity(0.6),
        size: iconSizeRegular,
      ),
      suffixIcon: suffixIcon,
    );
  }

  // Button Style
  static ButtonStyle submitButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  );
  
  // Spacers
  static const SizedBox spaceTiny = SizedBox(height: spacingTiny);
  static const SizedBox spaceSmall = SizedBox(height: spacingSmall);
  static const SizedBox spaceMedium = SizedBox(height: spacingMedium);
  static const SizedBox spaceLarge = SizedBox(height: spacingLarge); // 20
  
  static const SizedBox hSpaceSmall = SizedBox(width: spacingSmall);

  static SizedBox headerSpacer(bool isMobile) => SizedBox(height: isMobile ? 55 : 25);
  static SizedBox subHeaderSpacer(bool isMobile) => SizedBox(height: isMobile ? 40 : 20);
  static SizedBox footerSpacer(bool isMobile) => SizedBox(height: isMobile ? 60 : 35);
}
