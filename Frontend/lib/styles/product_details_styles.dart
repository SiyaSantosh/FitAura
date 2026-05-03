import 'package:flutter/material.dart';

class ProductDetailsStyles {
  // Colors
  static const Color primaryColor = Color(0xFF704F38); // brownColor
  static const Color beigeBackgroundColor = Color(0xFFF5F1EB);
  static const Color darkTextColor = Color(0xFF1F2029);
  static const Color lightGrayColor = Color(0xFF797979);
  static const Color whiteColor = Colors.white;
  static const Color transparentColor = Colors.transparent;
  static const Color starColor = Colors.amber;
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color errorColor = Colors.red;
  static final Color greyBorderColor = Colors.grey.shade300;
  static final Color shadowColor = Colors.black.withValues(alpha: 0.05);

  // Text Styles
  static const TextStyle storeNameStyle = TextStyle(
    color: lightGrayColor, 
    fontSize: 14,
  );

  static const TextStyle ratingStyle = TextStyle(
    fontWeight: FontWeight.bold, 
    fontSize: 14,
  );

  static const TextStyle productTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );

  static const TextStyle sectionHeaderStyle = TextStyle(
    fontSize: 18, 
    fontWeight: FontWeight.bold, 
    color: darkTextColor,
  );
  
  static const TextStyle selectorHeaderStyle = TextStyle(
    fontSize: 16, 
    fontWeight: FontWeight.bold, 
    color: darkTextColor,
  );

  static const TextStyle descriptionStyle = TextStyle(
    color: lightGrayColor, 
    height: 1.5,
  );

  static const TextStyle readMoreStyle = TextStyle(
    color: primaryColor,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle totalPriceLabelStyle = TextStyle(
    color: lightGrayColor, 
    fontSize: 12,
  );

  static const TextStyle totalPriceValueStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );

  static const TextStyle addToCartButtonStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: whiteColor,
  );

  static const TextStyle buttonTextStyleBold = TextStyle(
    fontWeight: FontWeight.bold,
  );
  
  static final TextStyle cancelButtonTextStyle = TextStyle(
    color: primaryColor,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle updateButtonTextStyle = TextStyle(
    color: whiteColor,
    fontWeight: FontWeight.bold,
  );
  
  static TextStyle variantOptionStyle(bool isSelected) {
    return TextStyle(
      color: isSelected ? whiteColor : darkTextColor,
      fontWeight: FontWeight.bold,
    );
  }
  
  static const TextStyle colorNameStyle = TextStyle(
    fontSize: 16, 
    color: lightGrayColor,
  );
  
  static const TextStyle quantityTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );
  
  static const TextStyle maxQuantityStyle = TextStyle(
    fontSize: 12, 
    color: lightGrayColor,
  );

  // Decorations
  static const BoxDecoration mainImageContainerDecoration = BoxDecoration(
    color: beigeBackgroundColor,
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(32),
      bottomRight: Radius.circular(32),
    ),
  );

  static const BoxDecoration roundButtonDecoration = BoxDecoration(
    color: beigeBackgroundColor,
    shape: BoxShape.circle,
  );
  
  static BoxDecoration thumbnailDecoration(bool isSelected) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isSelected ? primaryColor : whiteColor,
        width: 2,
      ),
      color: whiteColor,
    );
  }

  static BoxDecoration sizeOptionDecoration(bool isSelected) {
    return BoxDecoration(
      color: isSelected ? primaryColor : whiteColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isSelected ? primaryColor : Colors.grey.shade300,
      ),
    );
  }
  
  static BoxDecoration colorOptionOuterDecoration(bool isSelected) {
    return BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: isSelected ? primaryColor : transparentColor,
        width: 2,
      ),
    );
  }
  
  static BoxDecoration colorOptionInnerDecoration(Color color) {
    return BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.grey.shade300),
    );
  }
  
  static BoxDecoration quantityButtonDecoration(bool isAdd) {
    return BoxDecoration(
      color: isAdd ? primaryColor : whiteColor,
      borderRadius: BorderRadius.circular(8),
      border: isAdd ? null : Border.all(color: Colors.grey.shade300),
    );
  }
  
  static final BoxDecoration bottomBarDecoration = BoxDecoration(
    color: whiteColor,
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        blurRadius: 10,
        offset: const Offset(0, -5),
      ),
    ],
  );
  
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    padding: paddingSymmetricHorizontal24Vertical12,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 0,
  );
  
  static final ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    side: const BorderSide(color: primaryColor),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  static final BoxDecoration addToCartButtonDecoration = BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(16),
  );

  // Layout & Spacing
  static const EdgeInsets padding24 = EdgeInsets.all(24.0);
  static const EdgeInsets paddingSymmetricHorizontal24Vertical12 = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static const EdgeInsets paddingSymmetricHorizontal16Vertical8 = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsets paddingSymmetricHorizontal20 = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets paddingAll4 = EdgeInsets.all(4);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(8);
  static const EdgeInsets paddingOnlyTop8 = EdgeInsets.only(top: 8.0);
  static const EdgeInsets paddingOnlyRight12 = EdgeInsets.only(right: 12);
  
  static const Widget sizedBoxHeight4 = SizedBox(height: 4);
  static const Widget sizedBoxHeight8 = SizedBox(height: 8);
  static const Widget sizedBoxHeight12 = SizedBox(height: 12);
  static const Widget sizedBoxHeight16 = SizedBox(height: 16);
  static const Widget sizedBoxHeight20 = SizedBox(height: 20);
  static const Widget sizedBoxHeight24 = SizedBox(height: 24);
  static const Widget sizedBoxHeight70 = SizedBox(height: 70);
  
  static const Widget sizedBoxWidth4 = SizedBox(width: 4);
  static const Widget sizedBoxWidth8 = SizedBox(width: 8);
  static const Widget sizedBoxWidth12 = SizedBox(width: 12);
  
  static const Divider divider = Divider(height: 1, color: dividerColor);

}
