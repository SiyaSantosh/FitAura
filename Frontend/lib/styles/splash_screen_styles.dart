import 'package:flutter/material.dart';
import 'app_colors.dart';

class SplashScreenStyles {
  static const double logoSize = 50.0;
  static const double spacingBetweenLogoAndText = 12.0;
  static const double fFontSize = 30.0;
  static const double titleFontSize = 30.0;

  static const centerAlignment = MainAxisAlignment.center;

  static const TextStyle fTextStyle = TextStyle(
    color: AppColors.white,
    fontSize: fFontSize,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle titleStyle = TextStyle(
    color: Colors.black,
    fontSize: titleFontSize,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle titleStyleDark = TextStyle(
    color: AppColors.darkText,
    fontSize: titleFontSize,
    fontWeight: FontWeight.bold,
  );

  static const BoxDecoration logoDecoration = BoxDecoration(
    color: AppColors.brown,
    shape: BoxShape.circle,
  );

  static Widget splashLogo(String text) => Container(
    width: logoSize,
    height: logoSize,
    decoration: logoDecoration,
    child: Center(
      child: Text(
        text,
        style: fTextStyle,
      ),
    ),
  );

  static const hSpaceMedium = SizedBox(width: spacingBetweenLogoAndText);

  static Widget fullContent(String logoText, String titleText) => Center(
    child: Row(
      mainAxisAlignment: centerAlignment,
      children: [
        splashLogo(logoText),
        hSpaceMedium,
        Text(
          titleText,
          style: titleStyleDark,
        ),
      ],
    ),
  );
}
