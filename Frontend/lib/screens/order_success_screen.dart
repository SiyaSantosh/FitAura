import 'package:flutter/material.dart';
import 'customer_home_screen.dart';
import '../styles/order_success_styles.dart';

class OrderSuccessScreen extends StatelessWidget {
  final int userId;

  const OrderSuccessScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrderSuccessStyles.whiteColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: OrderSuccessStyles.successIconSize,
              height: OrderSuccessStyles.successIconSize,
              decoration: OrderSuccessStyles.successIconDecoration,
              child: const Icon(
                Icons.check,
                color: OrderSuccessStyles.whiteColor,
                size: OrderSuccessStyles.successIconInsideSize,
              ),
            ),
            OrderSuccessStyles.sizedBoxHeight32,
            
            const Text(
              "Order Successful!",
              style: OrderSuccessStyles.successTitleStyle,
            ),
            OrderSuccessStyles.sizedBoxHeight12,
            const Text(
              "Thank you for your purchase",
              style: OrderSuccessStyles.successSubtitleStyle,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: OrderSuccessStyles.paddingAll24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: OrderSuccessStyles.buttonHeight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => CustomerHomeScreen(userId: userId),
                    ),
                    (route) => false,
                  );
                },
                style: OrderSuccessStyles.primaryButtonStyle,
                child: const Text(
                  "Back to Home",
                  style: OrderSuccessStyles.buttonTextStyle,
                ),
              ),
            ),
            OrderSuccessStyles.sizedBoxHeight24,
          ],
        ),
      ),
    );
  }
}
