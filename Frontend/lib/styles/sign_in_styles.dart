import 'package:flutter/material.dart';
import 'app_colors.dart';

class SignInStyles {
  // Layout Constants
  static const double mobileHorizontalPadding = 0.08;
  static const double webCardMaxWidth = 450.0;
  static const double webContentPadding = 40.0;
  static const double fieldSpacing = 8.0;
  static const double sectionSpacing = 16.0;
  static const double largeSectionSpacing = 24.0;
  static const double mobileSignInTopPadding = 0.13;
  static const double mobileSignUpBottomPadding = 0.06;
  static const double webLogoTopPadding = 20.0;
  
  static const double primaryButtonHeight = 56.0;
  static const double secondaryButtonHeight = 52.0;
  static const double primaryButtonRadius = 28.0;
  static const double secondaryButtonRadius = 26.0;
  static const double dialogPadding = 24.0;
  static const double webLayoutPadding = 48.0;
  static const double forgotPasswordPaddingH = 8.0;
  static const double forgotPasswordPaddingV = 4.0;
  static const double mobileSignInSpacingRatio = 0.10;
  
  // Weights & Flex
  static const int webImageFlex = 5; // If applicable elsewhere
  static const double buttonScalePressed = 0.98;
  static const double buttonScaleNormal = 1.0;
  // Layout Helpers
  static EdgeInsets mobileScreenPadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return EdgeInsets.symmetric(horizontal: w * mobileHorizontalPadding);
  }

  // Alignment
  static const centerAlignment = TextAlign.center;
  static const startAlignment = CrossAxisAlignment.start;
  static const stretchAlignment = CrossAxisAlignment.stretch;
  static const centerMainAlignment = MainAxisAlignment.center;
  static const rightAlignment = Alignment.centerRight;

  // Text Styles
  static const TextStyle headerStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
    letterSpacing: -0.5,
  );

  static const TextStyle dialogTitleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
    letterSpacing: -0.5,
  );

  static const TextStyle subHeaderStyle = TextStyle(
    fontSize: 14,
    color: AppColors.lightGray,
    height: 1.5,
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

  static TextStyle passwordHintStyle = TextStyle(
    color: AppColors.darkText.withOpacity(0.3),
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

  static const TextStyle normalWeightStyle = TextStyle(fontWeight: FontWeight.w400);

  static const TextStyle buttonTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  // Input Decorations
  static InputDecoration inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? errorText,
    double borderRadius = 30,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: hintStyle,
      filled: true,
      fillColor: Colors.white,
      errorText: errorText,
      border: _outlineBorder(0.3, radius: borderRadius),
      enabledBorder: _outlineBorder(0.3, radius: borderRadius),
      focusedBorder: _outlineBorder(1.0, width: 2.0, color: AppColors.brown, radius: borderRadius),
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
  static ButtonStyle primaryButtonStyle({bool isLoading = false, double radius = 28}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.brown,
      disabledBackgroundColor: AppColors.brown.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      elevation: 4,
      shadowColor: AppColors.brown.withOpacity(0.4),
    );
  }

  static const TextStyle buttonSecondaryTextStyle = TextStyle(
    color: AppColors.lightGray,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle dialogButtonTextStyle = TextStyle(
    color: AppColors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

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

  static final dialogBarrierColor = Colors.black.withOpacity(0.5);

  // Spacing Widgets
  static const hSpaceTiny = SizedBox(width: 4);
  static const hSpaceSmall = SizedBox(width: 8);
  static const hSpaceMedium = SizedBox(width: 12);
  static const vSpaceTiny = SizedBox(height: 8);
  static const vSpaceSmall = SizedBox(height: 12);
  static const vSpaceMedium = SizedBox(height: 16);
  static const vSpaceLarge = SizedBox(height: 24);
  static const vSpaceWebTop = SizedBox(height: webLogoTopPadding);

  // Animations & Transitions
  static const Duration dialogAnimationDuration = Duration(milliseconds: 300);
  static const Duration buttonTransitionDuration = Duration(milliseconds: 200);
  static const Duration switcherDuration = Duration(milliseconds: 200);
  static const Duration navigationDelay = Duration(milliseconds: 500);
  static const Curve animationCurve = Curves.easeOut;
  static const Curve dialogScaleCurve = Curves.elasticOut;
  static const Curve dialogFadeCurve = Curves.easeIn;
  static const double slideBegin = 30.0;
  static const double slideEnd = 0.0;
  static const double fadeBegin = 0.0;
  static const double fadeEnd = 1.0;

  // Sizes
  static const double iconSizeSmall = 20.0;
  static const double loadingIndicatorSize = 24.0;
  static const double loadingIndicatorSizeSmall = 20.0;
  static const double loadingIndicatorStrokeWidth = 2.5;

  // Layout Helpers
  static double mobileLateralPadding(double screenWidth) => screenWidth * mobileHorizontalPadding;
  
  static double mobileMiddleSpacing(BuildContext context) {
    return MediaQuery.of(context).size.height * mobileSignInSpacingRatio;
  }

  static double mobileSignInButtonSpacing(BuildContext context) {
    return MediaQuery.of(context).size.height * mobileSignInTopPadding;
  }

  static double mobileSignUpBottomSpacing(BuildContext context, bool isSmallScreen) {
    final h = MediaQuery.of(context).size.height;
    return isSmallScreen ? h * 0.04 : h * mobileSignUpBottomPadding;
  }

  static EdgeInsets webScreenPadding = const EdgeInsets.symmetric(
    horizontal: webLayoutPadding, 
    vertical: webLayoutPadding,
  );

  static const EdgeInsets forgotPasswordLinkPadding = EdgeInsets.symmetric(
    horizontal: forgotPasswordPaddingH, 
    vertical: forgotPasswordPaddingV,
  );

  static EdgeInsets dialogInsetPadding(BuildContext context, bool isMobile, double screenWidth) {
    return EdgeInsets.symmetric(
      horizontal: isMobile 
        ? mobileDialogHorizontalPadding(screenWidth) 
        : webDialogHorizontalPadding(MediaQuery.of(context).size.width),
    );
  }

  static const double dialogStepBorderRadius = 25.0;

  static double mobileTopPadding(BuildContext context, bool isSmallScreen) {
    final h = MediaQuery.of(context).size.height;
    return isSmallScreen ? h * 0.04 : h * 0.09;
  }
  static double mobileDialogHorizontalPadding(double screenWidth) => screenWidth * 0.1;
  static double webDialogHorizontalPadding(double screenWidth) => screenWidth * 0.2;
  static double dialogMaxWidth(bool isMobile) => isMobile ? double.infinity : 500.0;

  // Animations & Transitions
  static const Duration animationDuration = Duration(milliseconds: 800);
}
