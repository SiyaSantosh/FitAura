import 'package:flutter/material.dart';
import 'app_colors.dart';

class WelcomeStyles {
  // Layout Constants
  static const double webMaxWidth = 1400.0;
  static const double webPadding = 40.0;
  static const double webSpacing = 60.0;
  static const double webImageSectionHeight = 700.0;
  
  static const double mobilePaddingRatio = 0.08;
  static const double mobileTopPaddingRatio = 0.02;

  // Border Radius
  static final BorderRadius outerBorderRadius = BorderRadius.circular(35);
  static const double circleRadius = 100.0;
  static final BorderRadius buttonBorderRadius = BorderRadius.circular(30);
  static final BorderRadius mobileButtonBorderRadius = BorderRadius.circular(28);

  // Text Styles
  static const TextStyle webHeaderStyle = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: AppColors.darkText,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle headerHighlightStyle = TextStyle(color: AppColors.brown);

  static const TextStyle webSubHeaderStyle = TextStyle(
    fontSize: 18,
    color: AppColors.lightGray,
    height: 1.6,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const TextStyle signinPromptStyle = TextStyle(
    fontSize: 16,
    color: AppColors.darkText,
  );

  static const TextStyle normalWeightStyle = TextStyle(fontWeight: FontWeight.w400);

  static const TextStyle signinLinkStyle = TextStyle(
    color: AppColors.brown,
    fontWeight: FontWeight.w600,
  );

  static TextStyle mobileHeaderStyle(double screenWidth) => TextStyle(
    fontSize: (screenWidth * 0.060),
    fontWeight: FontWeight.w800,
    color: AppColors.darkText,
    height: 1.3,
    letterSpacing: -0.1,
  );

  static TextStyle mobileSubHeaderStyle(double screenWidth) => TextStyle(
    fontSize: (screenWidth * 0.035),
    color: AppColors.lightGray,
    height: 1.5,
  );

  static TextStyle mobilePromptStyle(double screenWidth, bool isMobile) => TextStyle(
    fontSize: isMobile ? screenWidth * 0.035 : (screenWidth * 0.025).clamp(14.0, 16.0),
    color: AppColors.darkText,
  );

  static const TextStyle mobileStarStyle = TextStyle(
    color: Colors.black,
    fontSize: 82,
    fontWeight: FontWeight.normal,
    height: 1,
  );

  // Button Styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.brown,
    shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
    elevation: 0,
  );

  static final ButtonStyle mobilePrimaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.brown,
    shape: RoundedRectangleBorder(borderRadius: mobileButtonBorderRadius),
    elevation: 0,
  );

  static const buttonMaxWidth = BoxConstraints(maxWidth: 400);

  // Spacing
  static const hSpaceWeb = SizedBox(width: webSpacing);
  static const hSpaceSmall = SizedBox(width: 16);
  static const hSpaceTiny = SizedBox(width: 8);
  static const vSpaceSmall = SizedBox(height: 16);
  static const vSpaceMedium = SizedBox(height: 24);
  static const vSpaceLarge = SizedBox(height: 48);
  static const vSpaceWebTop = SizedBox(height: 20);

  // Paddings
  static const webPaddingAll = EdgeInsets.all(webPadding);
  static const webImagePadding = EdgeInsets.all(20);
  static const webLeftImageTopPadding = EdgeInsets.only(top: 20);

  // Layout Weights
  static int mobileImageFlex(bool isMobile) => isMobile ? 65 : 60;
  static int mobileTextFlex(bool isMobile) => isMobile ? 45 : 40;
  static const webImageFlex = 5;
  static const webTextFlex = 4;
  static const webImageGridMainFlex = 4;
  static const webImageGridSideFlex = 3;
  static const webImageGridSubFlex = 5;

  // Methods to compute screen-based values to keep screen logic clean
  static double mobileLateralPadding(double screenWidth) => screenWidth * mobilePaddingRatio;
  static double mobileTopPadding(BuildContext context) => MediaQuery.of(context).size.height * mobileTopPaddingRatio;

  static EdgeInsets leftImagePadding(BuildContext context, bool isMobile) {
    final h = MediaQuery.of(context).size.height;
    return EdgeInsets.only(top: isMobile ? h * 0.02 : h * 0.01);
  }
  
  static EdgeInsets mobileContentPadding(BuildContext context, double screenWidth, bool isMobile) {
    final h = MediaQuery.of(context).size.height;
    return EdgeInsets.only(
      left: isMobile ? screenWidth * mobilePaddingRatio : screenWidth * 0.05,
      right: screenWidth * 0.05,
      top: isMobile ? h * mobileTopPaddingRatio : h * 0.03,
      bottom: isMobile ? h * 0.02 : h * 0.03,
    );
  }

  static EdgeInsets textSectionPadding(BuildContext context, double screenWidth, bool isMobile) {
    final h = MediaQuery.of(context).size.height;
    return EdgeInsets.symmetric(
      horizontal: isMobile ? screenWidth * 0.075 : screenWidth * 0.1,
      vertical: isMobile ? h * 0.03 : h * 0.04,
    );
  }

  // Box Constraints
  static const webContainerConstraints = BoxConstraints(maxWidth: webMaxWidth);

  // Alignment & Layout
  static const centerAlignment = TextAlign.center;
  static const startAlignment = CrossAxisAlignment.start;
  static const centerCrossAlignment = CrossAxisAlignment.center;
  static const centerMainAlignment = MainAxisAlignment.center;
  static const stretchAlignment = CrossAxisAlignment.stretch;

  // Box Decorations
  static const desktopBackground = BoxDecoration(color: AppColors.white);
  static final beigeContainer = BoxDecoration(
    color: AppColors.beige,
    borderRadius: outerBorderRadius,
  );
  
  static final circleBeigeContainer = BoxDecoration(
    shape: BoxShape.circle,
    color: AppColors.beige,
  );

  static final borderCircle = BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.transparent,
    border: Border.all(color: AppColors.lightGray, width: 0.5),
  );

  // Specialized image builders or wrappers
  static Widget styledImage(String path) => ClipRRect(
    borderRadius: outerBorderRadius,
    child: Image.asset(path, fit: BoxFit.cover),
  );

  static Widget circleImage(String path, {double scale = 1.0, Offset offset = Offset.zero}) => ClipOval(
    child: Transform.translate(
      offset: offset,
      child: Transform.scale(
        scale: scale,
        child: Image.asset(path, fit: BoxFit.cover),
      ),
    ),
  );
}
