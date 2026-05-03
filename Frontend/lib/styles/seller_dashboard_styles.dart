import 'package:flutter/material.dart';

class SellerDashboardStyles {
  // Colors matching SellerDashboardScreen
  static const Color brownColor = Color(0xFF704F38);
  static const Color lightGray = Color(0xFF797979);
  static const Color darkText = Color(0xFF000000);
  static const Color whiteColor = Colors.white;
  static const Color beigeBackground = Color(0xFFF5F1EB);
  static const Color transparentColor = Colors.transparent;

  // Notification Specific Styles
  static BoxDecoration notificationCardDecoration(bool isRead) {
    return BoxDecoration(
      color: isRead ? whiteColor : brownColor.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      border: isRead 
          ? Border.all(color: transparentColor) 
          : Border.all(color: brownColor.withOpacity(0.2), width: 1),
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
    color: darkText,
  );

  static TextStyle notificationMessageStyle(bool isRead) {
    return TextStyle(
      fontSize: 14,
      fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
      color: darkText.withOpacity(isRead ? 0.7 : 1.0),
    );
  }

  static const TextStyle notificationTimeStyle = TextStyle(
    fontSize: 12,
    color: lightGray,
    fontWeight: FontWeight.w400,
  );

  static final BoxDecoration unreadIndicatorDecoration = BoxDecoration(
    color: brownColor,
    shape: BoxShape.circle,
    border: Border.all(color: whiteColor, width: 2),
  );

  static final BoxDecoration emptyStateIconDecoration = BoxDecoration(
    color: brownColor.withOpacity(0.1),
    shape: BoxShape.circle,
  );

  static BoxDecoration profileCardDecoration = BoxDecoration(
    color: whiteColor,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration infoSectionDecoration = BoxDecoration(
    color: beigeBackground.withOpacity(0.5),
    borderRadius: BorderRadius.circular(16),
  );

  static const TextStyle profileSectionTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: darkText,
  );

  static const TextStyle infoLabelStyle = TextStyle(
    fontSize: 12,
    color: lightGray,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle infoValueStyle = TextStyle(
    fontSize: 14,
    color: darkText,
    fontWeight: FontWeight.w600,
  );
}
