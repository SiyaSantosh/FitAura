import 'package:flutter/material.dart';
import 'app_colors.dart';

class AdminDashboardStyles {
  // Colors
  static const Color primaryColor = AppColors.brown;
  static const Color backgroundColor = AppColors.beige;
  static const Color surfaceColor = AppColors.white;
  static const Color textColor = AppColors.darkText;
  static const Color secondaryTextColor = AppColors.lightGray;
  static const Color dividerColor = Color(0xFFE0E0E0);
  
  // Status Colors
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orange;
  static const Color errorColor = Colors.red;
  static const Color errorColorAccent = Color(0xFFE53935);
  static const Color infoColor = Colors.blue;
  static const Color sellerColor = Colors.blue;
  static const Color customerColor = Colors.green;

  // Spacing
  static const double spacingTiny = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingExtraLarge = 24.0;
  static const double spacingXXL = 32.0;
  static const double spacingHuge = 48.0;
  
  static const EdgeInsets screenPadding = EdgeInsets.all(spacingLarge);

  static const Widget vSpaceTiny = SizedBox(height: spacingTiny);
  static const Widget vSpaceSmall = SizedBox(height: spacingSmall);
  static const Widget vSpaceMedium = SizedBox(height: spacingMedium);
  static const Widget vSpaceLarge = SizedBox(height: spacingLarge);
  static const Widget vSpaceExtraLarge = SizedBox(height: spacingExtraLarge);
  static const Widget vSpaceXXL = SizedBox(height: spacingXXL);
  static const Widget vSpaceHuge = SizedBox(height: spacingHuge);

  static const Widget hSpaceTiny = SizedBox(width: spacingTiny);
  static const Widget hSpaceSmall = SizedBox(width: spacingSmall);
  static const Widget hSpaceMedium = SizedBox(width: spacingMedium);
  static const Widget hSpaceLarge = SizedBox(width: spacingLarge);
  static const Widget hSpaceExtraLarge = SizedBox(width: spacingExtraLarge);

  // Animations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 200);
  static const Curve dialogScaleCurve = Curves.elasticOut;
  static const Curve defaultAnimationCurve = Curves.easeInOut;

  // Text Styles
  static const TextStyle headerTitleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: -0.5,
  );

  static const TextStyle headerSubtitleStyle = TextStyle(
    fontSize: 14,
    color: secondaryTextColor,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle sidebarLogoStyle = TextStyle(
    color: surfaceColor,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1,
  );

  static const TextStyle sidebarBrandStyle = TextStyle(
    color: textColor,
    fontSize: 20,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle navItemStyle = TextStyle(
    fontSize: 15,
    letterSpacing: -0.2,
  );

  static const TextStyle subNavItemStyle = TextStyle(
    fontSize: 14,
    letterSpacing: -0.2,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: -0.3,
  );

  static const TextStyle dialogTitleStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: -0.5,
  );

  static const TextStyle dialogSubtitleStyle = TextStyle(
    fontSize: 16,
    color: secondaryTextColor,
    height: 1.5,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle labelTextStyle = TextStyle(
    fontSize: 12,
    color: secondaryTextColor,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle detailValueStyle = TextStyle(
    fontSize: 14,
    color: textColor,
    fontWeight: FontWeight.w600,
  );

  // Decorations
  static final BoxDecoration sidebarDecoration = BoxDecoration(
    color: surfaceColor,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(2, 0),
      ),
    ],
  );

  static final BoxDecoration headerDecoration = BoxDecoration(
    color: surfaceColor,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static final BoxDecoration logoContainerDecoration = const BoxDecoration(
    color: primaryColor,
    shape: BoxShape.circle,
  );

  static BoxDecoration navItemDecoration(bool isSelected) {
    return BoxDecoration(
      color: isSelected ? primaryColor.withOpacity(0.12) : transparentColor,
      borderRadius: BorderRadius.circular(12),
      border: isSelected ? Border.all(color: primaryColor.withOpacity(0.4), width: 1.5) : null,
    );
  }

  static final BoxDecoration cardDecoration = BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static final BoxDecoration detailCardDecoration = BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: secondaryTextColor.withOpacity(0.1), width: 1),
  );

  static final BoxDecoration detailHeaderDecoration = BoxDecoration(
    color: primaryColor,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(24),
    ),
  );

  static final BoxDecoration dialogDecoration = BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(32),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 30,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static final BoxDecoration detailDialogDecoration = BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 30,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static const Color transparentColor = Colors.transparent;
  static final Color dialogBarrierColor = Colors.black.withOpacity(0.5);

  // Button Styles
  static ButtonStyle primaryButtonStyle({double radius = 16, Color? color}) {
    return ElevatedButton.styleFrom(
      backgroundColor: color ?? primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      padding: const EdgeInsets.symmetric(vertical: 16),
      elevation: 0,
    );
  }

  static ButtonStyle outlinedButtonStyle({double radius = 26, Color? color}) {
    return OutlinedButton.styleFrom(
      side: BorderSide(color: color ?? secondaryTextColor.withOpacity(0.5), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      padding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  static ButtonStyle actionButtonStyle({required bool isPrimary, Color? color, bool isMobile = false}) {
    if (isPrimary) {
      return ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.green,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 12 : 18,
        ),
        minimumSize: Size(0, isMobile ? 48 : 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    } else {
      return OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 12 : 18,
        ),
        minimumSize: Size(0, isMobile ? 48 : 56),
        side: BorderSide(color: color ?? Colors.red, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    }
  }

  // Sidebar specific
  static const double sidebarExpandedWidth = 280.0;
  static const double sidebarCollapsedWidth = 80.0;

  // Header specific
  static InputDecoration searchInputDecoration(bool isMobile) {
    return InputDecoration(
      hintText: 'Search here',
      hintStyle: TextStyle(color: secondaryTextColor, fontSize: isMobile ? 13 : 14),
      prefixIcon: const Icon(Icons.search, color: secondaryTextColor, size: 20),
      filled: true,
      fillColor: backgroundColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: secondaryTextColor.withOpacity(0.2), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 18, vertical: isMobile ? 12 : 14),
    );
  }

  // Mobile Top Bar
  static const double mobileAppBarHeight = 64.0;

  // Recent Activity Styles
  static const TextStyle recentActivityTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle emptyStateTextStyle = TextStyle(
    fontSize: 16,
    color: secondaryTextColor,
  );

  // Filter Chip Styles
  static BoxDecoration filterChipDecoration(bool isSelected) {
    return BoxDecoration(
      color: isSelected ? primaryColor : surfaceColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isSelected ? primaryColor : secondaryTextColor.withOpacity(0.2),
        width: 1.2,
      ),
      boxShadow: isSelected
          ? [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ]
          : null,
    );
  }

  static TextStyle filterChipTextStyle(bool isSelected) {
    return TextStyle(
      color: isSelected ? surfaceColor : textColor.withOpacity(0.7),
      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
      fontSize: 13,
    );
  }

  // Dialog Styles
  static EdgeInsets dialogInsetPadding(bool isMobile, double screenWidth) {
    return EdgeInsets.symmetric(
      horizontal: isMobile ? 24 : screenWidth * 0.1,
    );
  }

  static BoxConstraints dialogConstraints(bool isMobile, double screenHeight) {
    return BoxConstraints(
      maxWidth: isMobile ? double.infinity : 800,
      maxHeight: screenHeight * 0.85,
    );
  }

  static const BoxDecoration detailImageContainerDecoration = BoxDecoration(
    color: Color(0x338D6E63), // primaryColor.withOpacity(0.2)
    shape: BoxShape.circle,
  );

  static const TextStyle detailNameStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: surfaceColor,
  );

  static const BoxDecoration detailRoleTagBackground = BoxDecoration(
    color: Color(0x33FFFFFF), // surfaceColor.withOpacity(0.2)
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  static const TextStyle detailRoleTagStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: surfaceColor,
  );

  // Sidebar Nav Item Styles
  static const EdgeInsets sidebarNavItemMargin = EdgeInsets.symmetric(horizontal: 8, vertical: 4);
  
  static EdgeInsets sidebarNavItemPadding(bool isHovered) {
    return EdgeInsets.symmetric(
      horizontal: isHovered ? 16 : 8,
      vertical: 14,
    );
  }

  static BoxDecoration sidebarNavItemDecoration(bool isSelected, bool hasSelectedSubItem) {
    return BoxDecoration(
      color: (isSelected || hasSelectedSubItem)
          ? primaryColor.withOpacity(0.12)
          : transparentColor,
      borderRadius: BorderRadius.circular(12),
      border: (isSelected || hasSelectedSubItem)
          ? Border.all(color: primaryColor.withOpacity(0.4), width: 1.5)
          : null,
    );
  }

  static TextStyle sidebarNavItemTextStyle(bool isSelected, bool hasSelectedSubItem) {
    return TextStyle(
      fontSize: 15,
      color: (isSelected || hasSelectedSubItem) ? primaryColor : textColor,
      fontWeight: (isSelected || hasSelectedSubItem) ? FontWeight.w600 : FontWeight.w500,
      letterSpacing: -0.2,
    );
  }
  
  static const EdgeInsets sidebarSubItemMargin = EdgeInsets.symmetric(horizontal: 8, vertical: 2);
  static const EdgeInsets sidebarSubItemPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  // Bottom Navigation Styles
  static final BoxDecoration bottomNavDecoration = BoxDecoration(
    color: const Color(0xFF2C2C2E),
    borderRadius: BorderRadius.circular(32),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: 2,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 10,
        offset: const Offset(0, 4),
        spreadRadius: 1,
      ),
    ],
  );

  static BoxDecoration bottomNavItemDecoration(bool isSelected) {
    return isSelected
        ? BoxDecoration(
            color: surfaceColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          )
        : const BoxDecoration(); // Empty decoration
  }

  static TextStyle bottomNavItemTextStyle = TextStyle(
    color: surfaceColor.withOpacity(0.7),
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );

  // Stat Card Styles
  static final BoxDecoration statCardDecoration = BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration statCardIconDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    );
  }

  static TextStyle statCardValueStyle(bool isMobile) {
    return TextStyle(
      fontSize: isMobile ? 22 : 28,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
  }

  static const TextStyle statCardLabelStyle = TextStyle(
    fontSize: 14,
    color: secondaryTextColor,
    fontWeight: FontWeight.w500,
  );

  // User/Product Card Styles
  static final BoxDecoration commonCardDecoration = BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static final BoxDecoration imageBackgroundDecoration = BoxDecoration(
    color: primaryColor.withOpacity(0.1),
    shape: BoxShape.circle,
  );

  static const TextStyle cardNameStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static BoxDecoration roleTagDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    );
  }

  static TextStyle roleTagTextStyle(Color color) {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static const TextStyle emailStyle = TextStyle(
    fontSize: 14,
    color: secondaryTextColor,
  );

  static ButtonStyle reviewButtonStyle = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
    minimumSize: const Size(0, 56),
    side: const BorderSide(color: primaryColor, width: 1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static const TextStyle reviewButtonTextStyle = TextStyle(
    color: primaryColor, 
    fontSize: 12,
  );

  // Info Item Styles
  static const TextStyle infoItemLabelStyle = TextStyle(
    fontSize: 11,
    color: secondaryTextColor,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle infoItemValueStyle = TextStyle(
    fontSize: 13,
    color: textColor,
    fontWeight: FontWeight.w500,
  );

  // Admin Profile Styles
  static final BoxDecoration adminProfileDecoration = BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(12),
  );

  static final BoxDecoration adminAvatarDecoration = BoxDecoration(
    color: primaryColor,
    shape: BoxShape.circle,
    border: Border.all(
      color: surfaceColor,
      width: 2,
    ),
  );

  static TextStyle adminAvatarTextStyle(bool isMobile) {
    return TextStyle(
      color: surfaceColor,
      fontSize: isMobile ? 16 : 18,
      fontWeight: FontWeight.bold,
    );
  }

  static const TextStyle adminNameStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textColor,
  );
  
  // Drawer Header
  static final BoxDecoration drawerHeaderDecoration = BoxDecoration(
    color: surfaceColor,
    border: Border(
      bottom: BorderSide(color: secondaryTextColor.withOpacity(0.1), width: 1),
    ),
  );

  static TextStyle drawerItemTextStyle(bool isSelected, bool isSubItem) {
    return TextStyle(
      fontSize: isSubItem ? 15 : 16,
      color: textColor,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
    );
  }

  // Notification Specific Styles
  static BoxDecoration notificationCardDecoration(bool isRead) {
    return BoxDecoration(
      color: isRead ? surfaceColor : primaryColor.withOpacity(0.12),
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
    color: textColor,
  );

  static TextStyle notificationMessageStyle(bool isRead) {
    return TextStyle(
      fontSize: 14,
      fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
      color: textColor.withOpacity(isRead ? 0.7 : 1.0),
    );
  }

  static const TextStyle notificationTimeStyle = TextStyle(
    fontSize: 12,
    color: secondaryTextColor,
    fontWeight: FontWeight.w400,
  );

  static final BoxDecoration unreadIndicatorDecoration = BoxDecoration(
    color: primaryColor,
    shape: BoxShape.circle,
    border: Border.all(color: surfaceColor, width: 2),
  );
}
