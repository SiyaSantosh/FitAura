import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../styles/welcome_screen_styles.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isDesktop = screenWidth >= 1024;
    
    if (screenWidth >= 768) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: WelcomeStyles.webContainerConstraints,
              padding: WelcomeStyles.webPaddingAll,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: WelcomeStyles.webImageFlex,
                      child: _buildWebImageSection(),
                    ),
                    WelcomeStyles.hSpaceWeb,
                    Expanded(
                      flex: WelcomeStyles.webTextFlex,
                      child: _buildWebTextSection(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: _buildMobileContent(context, screenWidth, isMobile),
      ),
    );
  }

  Widget _buildWebImageSection() {
    return Container(
      height: WelcomeStyles.webImageSectionHeight,
      child: Padding(
        padding: WelcomeStyles.webImagePadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: WelcomeStyles.webImageGridMainFlex,
              child: Padding(
                padding: WelcomeStyles.webLeftImageTopPadding,
                child: WelcomeStyles.styledImage('assets/images/ws_image1.png'),
              ),
            ),
            WelcomeStyles.hSpaceSmall,
            Expanded(
              flex: WelcomeStyles.webImageGridSideFlex,
              child: Column(
                children: [
                  WelcomeStyles.vSpaceWebTop,
                  Expanded(
                    flex: WelcomeStyles.webImageGridSubFlex,
                    child: WelcomeStyles.styledImage('assets/images/ws_image2.png'),
                  ),
                  WelcomeStyles.vSpaceSmall,
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      width: double.infinity,
                      decoration: WelcomeStyles.circleBeigeContainer,
                      child: WelcomeStyles.circleImage('assets/images/ws_image3.png'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebTextSection(BuildContext context) {
    return Column(
      mainAxisAlignment: WelcomeStyles.centerMainAlignment,
      crossAxisAlignment: WelcomeStyles.startAlignment,
      children: [
        RichText(
          text: const TextSpan(
            style: WelcomeStyles.webHeaderStyle,
            children: [
              TextSpan(text: 'The '),
              TextSpan(text: 'Fashion App', style: WelcomeStyles.headerHighlightStyle),
              TextSpan(text: ' That Makes You Look Your Best'),
            ],
          ),
        ),
        WelcomeStyles.vSpaceMedium,
        const Text(
          'Try on styles virtually, shop confidently. Your perfect look, anytime, anywhere.',
          style: WelcomeStyles.webSubHeaderStyle,
        ),
        WelcomeStyles.vSpaceLarge,
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () {
              SignUpScreen.showRoleConfirmationDialog(
                context,
                onRoleSelected: (selectedRole) {
                  if (selectedRole != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignUpScreen(selectedRole: selectedRole),
                      ),
                    );
                  }
                },
              );
            },
            style: WelcomeStyles.primaryButtonStyle,
            child: const Text(
              "Let's Get Started",
              style: WelcomeStyles.buttonTextStyle,
            ),
          ),
        ),
        WelcomeStyles.vSpaceMedium,
        Center(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignInScreen()),
              );
            },
            child: RichText(
              textAlign: WelcomeStyles.centerAlignment,
              text: TextSpan(
                style: WelcomeStyles.signinPromptStyle,
                children: [
                  const TextSpan(
                    text: 'Already have an account? ',
                    style: WelcomeStyles.normalWeightStyle,
                  ),
                  TextSpan(
                    text: 'Sign In',
                    style: WelcomeStyles.signinLinkStyle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileContent(
    BuildContext context,
    double screenWidth,
    bool isMobile,
  ) {
    return Column(
      children: [
        
        Expanded(
          flex: WelcomeStyles.mobileImageFlex(isMobile),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                decoration: WelcomeStyles.desktopBackground,
              ),
              if (isMobile) ...[
                Positioned(
                  top: -70,
                  left: -50,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: WelcomeStyles.borderCircle,
                  ),
                ),
                Positioned(
                  top: 170,
                  left: 300,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: WelcomeStyles.borderCircle,
                  ),
                ),
              ],
              Padding(
                padding: WelcomeStyles.mobileContentPadding(context, screenWidth, isMobile),
                child: Row(
                  crossAxisAlignment: WelcomeStyles.stretchAlignment,
                  children: [
                    
                    Expanded(
                      flex: WelcomeStyles.webImageGridMainFlex,
                      child: Padding(
                        padding: WelcomeStyles.leftImagePadding(context, isMobile),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            SizedBox(
                              height: double.infinity,
                              child: WelcomeStyles.styledImage('assets/images/ws_image1.png'),
                            ),
                            if (isMobile)
                              const Positioned(
                                bottom: -23,
                                left: 7,
                                child: Text(
                                  '*',
                                  style: WelcomeStyles.mobileStarStyle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    WelcomeStyles.hSpaceTiny,
                    
                    Expanded(
                      flex: WelcomeStyles.webImageGridSideFlex,
                      child: Column(
                        children: [
                          WelcomeStyles.vSpaceWebTop,
                          Expanded(
                            flex: WelcomeStyles.webImageGridSideFlex,
                            child: WelcomeStyles.styledImage('assets/images/ws_image2.png'),
                          ),
                          WelcomeStyles.vSpaceSmall,
                          
                          Expanded(
                            flex: 2,
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                decoration: WelcomeStyles.circleBeigeContainer,
                                child: WelcomeStyles.circleImage(
                                  'assets/images/ws_image3.png',
                                  scale: isMobile ? 1.6 : 1.3,
                                  offset: Offset(0, isMobile ? 40 : 20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          flex: WelcomeStyles.mobileTextFlex(isMobile),
          child: Container(
            width: double.infinity,
            color: AppColors.white,
            padding: WelcomeStyles.textSectionPadding(context, screenWidth, isMobile),
            child: Column(
              mainAxisAlignment: WelcomeStyles.centerMainAlignment,
              children: [
                RichText(
                  textAlign: WelcomeStyles.centerAlignment,
                  text: TextSpan(
                    style: WelcomeStyles.mobileHeaderStyle(screenWidth),
                    children: const [
                      const TextSpan(text: 'The '),
                      TextSpan(
                        text: 'Fashion App',
                        style: WelcomeStyles.headerHighlightStyle,
                      ),
                      const TextSpan(text: ' That Makes You Look Your Best'),
                    ],
                  ),
                ),
                WelcomeStyles.vSpaceSmall,
                Text(
                  'Try on styles virtually, shop confidently\nYour perfect look, anytime, anywhere',
                  textAlign: WelcomeStyles.centerAlignment,
                  style: WelcomeStyles.mobileSubHeaderStyle(screenWidth),
                ),
                WelcomeStyles.vSpaceMedium,
                
                ConstrainedBox(
                  constraints: WelcomeStyles.buttonMaxWidth,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        SignUpScreen.showRoleConfirmationDialog(
                          context,
                          onRoleSelected: (selectedRole) {
                            if (selectedRole != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignUpScreen(selectedRole: selectedRole),
                                ),
                              );
                            }
                          },
                        );
                      },
                      style: WelcomeStyles.mobilePrimaryButtonStyle,
                      child: const Text(
                        "Let's Get Started",
                        style: WelcomeStyles.buttonTextStyle,
                      ),
                    ),
                  ),
                ),
                WelcomeStyles.vSpaceSmall,
                
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignInScreen(),
                      ),
                    );
                  },
                  child: RichText(
                    textAlign: WelcomeStyles.centerAlignment,
                    text: TextSpan(
                      style: WelcomeStyles.mobilePromptStyle(screenWidth, isMobile),
                      children: const [
                        TextSpan(text: 'Already have an account? ', style: WelcomeStyles.normalWeightStyle),
                        TextSpan(
                          text: 'Sign In',
                          style: WelcomeStyles.signinLinkStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
