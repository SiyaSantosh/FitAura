import 'package:flutter/material.dart';
import 'app_colors.dart';

class SignUpStyles {
  // Layout Constants
  static const double mobileHorizontalPadding = 0.08;
  static const double webCardMaxWidth = 450.0;
  static const double webContentPadding = 40.0;
  static const double fieldSpacing = 8.0;
  static const double sectionSpacing = 16.0;
  static const double largeSectionSpacing = 24.0;
  
  static const double mobileHeaderTopPadding = 0.07;
  static const double mobileHeaderSmallTopPadding = 0.01;
  static const double mobileSignInButtonSpacing = 0.12;
  static const double mobileSignUpBottomPadding = 0.06;
  static const double mobileSignUpSmallBottomPadding = 0.04;
  
  static const double webLogoTopPadding = 20.0;
  static const double webCardWebPadding = 48.0;
  
  // Weights & Sizes
  static const double buttonScalePressed = 0.98;
  static const double buttonScaleNormal = 1.0;
  static const double primaryButtonHeight = 56.0;
  static const double secondaryButtonHeight = 52.0;
  static const double primaryButtonRadius = 28.0;
  static const double secondaryButtonRadius = 26.0;
  static const double dialogPadding = 24.0;
  static const double dialogStepBorderRadius = 25.0;
  static const double checkboxSize = 20.0;
  static const double checkboxRadius = 4.0;
  static const double checkboxBorderWidth = 2.0;
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 28.0;
  static const double iconSizeLarge = 56.0;
  static const double loadingIndicatorSize = 20.0;
  static const double loadingIndicatorStrokeWidth = 2.5;
  static const double errorTooltipTop = -8.0;
  static const double errorTooltipRight = 0.0;

  // Alignment
  static const centerAlignment = TextAlign.center;
  static const startAlignment = CrossAxisAlignment.start;
  static const stretchAlignment = CrossAxisAlignment.stretch;
  static const centerMainAlignment = MainAxisAlignment.center;
  static const rightAlignment = Alignment.centerRight;

  // Layout Helpers
  static double mobileMiddleSpacing(BuildContext context, double ratio) {
    return MediaQuery.of(context).size.height * ratio;
  }

  static double mobileTopPadding(BuildContext context, bool isSmallScreen) {
    final h = MediaQuery.of(context).size.height;
    return isSmallScreen ? h * mobileHeaderSmallTopPadding : h * mobileHeaderTopPadding;
  }

  static double mobileBottomPadding(BuildContext context, bool isSmallScreen) {
    final h = MediaQuery.of(context).size.height;
    return isSmallScreen ? h * mobileSignUpSmallBottomPadding : h * mobileSignUpBottomPadding;
  }

  static EdgeInsets mobileScreenPadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return EdgeInsets.symmetric(horizontal: w * mobileHorizontalPadding);
  }

  static EdgeInsets webScreenPadding = const EdgeInsets.symmetric(
    horizontal: webCardWebPadding, 
    vertical: webCardWebPadding,
  );

  static EdgeInsets dialogInsetPadding(BuildContext context, bool isMobile, double screenWidth, {double? webMaxWidth}) {
    return EdgeInsets.symmetric(
      horizontal: isMobile ? screenWidth * 0.1 : MediaQuery.of(context).size.width * 0.2,
    );
  }

  static double dialogMaxWidth(bool isMobile, {double? customWidth}) {
    return isMobile ? double.infinity : (customWidth ?? 500.0);
  }

  // Text Styles
  static const TextStyle headerStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
    letterSpacing: -0.5,
  );

  static const TextStyle subHeaderStyle = TextStyle(
    fontSize: 14,
    color: AppColors.lightGray,
    height: 1.5,
  );

  static const TextStyle dialogTitleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
    letterSpacing: -0.5,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.darkText,
  );

  static const TextStyle fieldTextStyle = TextStyle(fontSize: 14);

  static const TextStyle hintStyle = TextStyle(
    color: AppColors.lightGray,
    fontSize: 14,
  );

  static TextStyle hintWithOpacity(double opacity) => TextStyle(
    color: AppColors.lightGray.withOpacity(opacity),
    fontSize: 14,
  );

  static const TextStyle linkStyle = TextStyle(
    fontSize: 14,
    color: AppColors.brown,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle promptStyle = TextStyle(
    fontSize: 14,
    color: AppColors.darkText,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const TextStyle dialogButtonTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const TextStyle secondaryButtonTextStyle = TextStyle(
    color: AppColors.lightGray,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle termsTextStyle = TextStyle(
    fontSize: 13,
    color: AppColors.darkText,
  );

  static const TextStyle errorTooltipStyle = TextStyle(
    color: Color(0xFF333333),
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle roleCardTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle roleCardDescStyle = TextStyle(
    fontSize: 13,
    color: AppColors.lightGray,
    height: 1.3,
  );

  static const TextStyle termItemTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.darkText,
  );

  static TextStyle termItemContentStyle = TextStyle(
    fontSize: 14,
    color: AppColors.darkText.withOpacity(0.7),
    height: 1.5,
  );

  // Input Decorations
  static InputDecoration inputDecoration({
    required BuildContext context,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? errorText,
    double borderRadius = 30,
  }) {
    final bool hasError = errorText != null;
    return InputDecoration(
      hintText: hint,
      hintStyle: hintWithOpacity(0.5),
      filled: true,
      fillColor: Colors.white,
      errorText: null, // We handle error with tooltips manually in this screen structure
      border: _outlineBorder(0.3, radius: borderRadius, color: hasError ? Colors.red : null),
      enabledBorder: _outlineBorder(0.3, radius: borderRadius, color: hasError ? Colors.red : null),
      focusedBorder: _outlineBorder(1.0, width: 2.0, radius: borderRadius, color: hasError ? Colors.red : AppColors.brown),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      prefixIcon: Icon(
        prefixIcon,
        color: AppColors.lightGray.withOpacity(0.6),
        size: 20,
      ),
      suffixIcon: suffixIcon,
    );
  }

  static OutlineInputBorder _outlineBorder(double opacity, {double width = 1.0, Color? color, double radius = 30}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(
        color: color ?? AppColors.lightGray.withOpacity(opacity),
        width: width,
      ),
    );
  }

  // Button Styles
  static ButtonStyle primaryButtonStyle({bool isLoading = false, double? radius}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.brown,
      disabledBackgroundColor: AppColors.brown.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius ?? primaryButtonRadius),
      ),
      elevation: 4,
      shadowColor: AppColors.brown.withOpacity(0.4),
    );
  }

  // Box Decorations
  static final webCardDecoration = BoxDecoration(
    color: AppColors.beige,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 30,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static final dialogDecoration = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(32),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static final errorTooltipDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static final errorIconDecoration = BoxDecoration(
    color: const Color(0xFFFF6B35),
    borderRadius: BorderRadius.circular(4),
  );

  static BoxDecoration roleCardDecoration(bool isSelected) {
    return BoxDecoration(
      color: isSelected ? AppColors.beige : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isSelected ? AppColors.brown : AppColors.lightGray.withOpacity(0.2),
        width: isSelected ? 2 : 1.5,
      ),
      boxShadow: isSelected
          ? [
              BoxShadow(
                color: AppColors.brown.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]
          : [],
    );
  }

  static BoxDecoration roleIconDecoration(bool isSelected) {
    return BoxDecoration(
      color: isSelected ? AppColors.brown : AppColors.brown.withOpacity(0.1),
      shape: BoxShape.circle,
    );
  }

  static BoxDecoration selectionIndicatorDecoration(bool isSelected) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: isSelected ? AppColors.brown : Colors.transparent,
      border: Border.all(
        color: isSelected ? AppColors.brown : AppColors.lightGray.withOpacity(0.5),
        width: 2,
      ),
    );
  }

  static BoxDecoration termNumberDecoration = const BoxDecoration(
    color: AppColors.brown,
    shape: BoxShape.circle,
  );

  static BoxDecoration checkboxDecoration(bool isChecked) {
    return BoxDecoration(
      color: isChecked ? AppColors.brown : Colors.transparent,
      border: Border.all(
        color: isChecked ? AppColors.brown : AppColors.lightGray,
        width: checkboxBorderWidth,
      ),
      borderRadius: BorderRadius.circular(checkboxRadius),
    );
  }

  // Spacing Widgets
  static const hSpaceTiny = SizedBox(width: 4);
  static const hSpaceSmall = SizedBox(width: 8);
  static const hSpaceMedium = SizedBox(width: 12);
  static const hSpaceLarge = SizedBox(width: 16);
  static const vSpaceTiny = SizedBox(height: 4);
  static const vSpaceSmall = SizedBox(height: 8);
  static const vSpaceMedium = SizedBox(height: 12);
  static const vSpaceLarge = SizedBox(height: 16);
  static const vSpaceXL = SizedBox(height: 20);
  static const vSpaceXXL = SizedBox(height: 24);
  static const vSpaceWebTop = SizedBox(height: webLogoTopPadding);

  // Animations & Transitions
  static const Duration animationDuration = Duration(milliseconds: 800);
  static const Duration dialogAnimationDuration = Duration(milliseconds: 300);
  static const Duration buttonTransitionDuration = Duration(milliseconds: 200);
  static const Duration switcherDuration = Duration(milliseconds: 200);
  static const Duration navigationDelay = Duration(seconds: 1);
  static const Duration otpVerificationDelay = Duration(seconds: 1);
  static const Curve animationCurve = Curves.easeOut;
  static const Curve dialogScaleCurve = Curves.elasticOut;
  static const Curve dialogFadeCurve = Curves.easeIn;
  static const Curve fastCurve = Curves.easeOut;
  static const Curve roleCardCurve = Curves.easeInOut;
  
  static const double slideBegin = 30.0;
  static const double slideEnd = 0.0;
  static const double fadeBegin = 0.0;
  static const double fadeEnd = 1.0;

  static final Color dialogBarrierColor = Colors.black.withOpacity(0.5);
}
