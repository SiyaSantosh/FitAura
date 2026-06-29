import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'sign_in_screen.dart';

import 'help_center_screen.dart';
import 'customer_profile_detail_screen.dart';
import 'customer_settings_screen.dart';
import 'my_orders_screen.dart';
import '../styles/profile_styles.dart';
import 'complaints_screen.dart';
import 'wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  late AnimationController _logoutDialogAnimationController;
  late Animation<double> _logoutDialogScaleAnimation;
  late Animation<double> _logoutDialogFadeAnimation;

  @override
  void initState() {
    super.initState();
    _logoutDialogAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _logoutDialogScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoutDialogAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _logoutDialogFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoutDialogAnimationController,
        curve: Curves.easeIn,
      ),
    );

    _fetchUserData();
  }

  @override
  void dispose() {
    _logoutDialogAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    if (widget.userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await ApiService.getUserById(widget.userId!);
      if (result['success'] && result['data'] != null) {
        if (mounted) {
          setState(() {
            _userData = result['data'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {

      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLogout() {
    _logoutDialogAnimationController.forward();
    showDialog(
      context: context,
      barrierColor: ProfileStyles.barrierColor,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 768;
        
        return AnimatedBuilder(
          animation: _logoutDialogAnimationController,
          builder: (context, child) {
            return Opacity(
              opacity: _logoutDialogFadeAnimation.value,
              child: Transform.scale(
                scale: _logoutDialogScaleAnimation.value,
                child: Dialog(
                  backgroundColor: ProfileStyles.transparentColor,
                  elevation: 0,
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : MediaQuery.of(context).size.width * 0.1,
                  ),
                  child: Container(
                    constraints: isMobile 
                         ? const BoxConstraints(maxWidth: double.infinity)
                         : ProfileStyles.dialogConstraintsDesktop,
                    decoration: ProfileStyles.logoutDialogDecoration,
                    child: Padding(
                      padding: isMobile ? ProfileStyles.paddingDialogMobile : ProfileStyles.paddingDialogDesktop,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          
                          const Text(
                            'Logout',
                            style: ProfileStyles.logoutTitleStyle,
                          ),
                          ProfileStyles.sizedBoxHeight8,
                          
                          const Text(
                            'Are you sure you want to logout?',
                            textAlign: TextAlign.center,
                            style: ProfileStyles.logoutSubtitleStyle,
                          ),
                          ProfileStyles.sizedBoxHeight20,
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    _logoutDialogAnimationController.reverse();
                                    Navigator.of(context).pop();
                                  },
                                  style: ProfileStyles.cancelButtonStyleFrom,
                                  child: const Text(
                                    'Cancel',
                                    style: ProfileStyles.cancelButtonStyle,
                                  ),
                                ),
                              ),
                              ProfileStyles.sizedBoxWidth12,
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _logoutDialogAnimationController.reverse();
                                    Navigator.of(context).pop();
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (context) => const SignInScreen()),
                                      (route) => false,
                                    );
                                  },
                                  style: ProfileStyles.logoutButtonStyleFrom,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.logout, color: ProfileStyles.whiteColor, size: 18),
                                      ProfileStyles.sizedBoxWidth8,
                                      Text(
                                        'Logout',
                                        style: ProfileStyles.logoutButtonTextStyle,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _logoutDialogAnimationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: ProfileStyles.primaryColor)),
      );
    }

    final String name = _userData?['name'] ?? _userData?['full_name'] ?? 'User';
    final String? profilePicture = _userData?['profile_picture'];

    return Scaffold(
      backgroundColor: ProfileStyles.whiteColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ProfileStyles.paddingHorizontal24,
          child: Column(
            children: [
              ProfileStyles.sizedBoxHeight10,
            
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: ProfileStyles.profileImageDecoration,
                child: ClipOval(
                  child: _buildProfileImage(profilePicture),
                ),
              ),
            ),
            ProfileStyles.sizedBoxHeight16,
            Text(
              name,
              style: ProfileStyles.userNameStyle,
            ),
            ProfileStyles.sizedBoxHeight32,
            
            _buildMenuItem(Icons.person_outline, 'Your profile'),
            _buildMenuItem(Icons.account_balance_wallet_outlined, 'Wallet'),
            _buildMenuItem(Icons.feedback_outlined, 'Complaints'),
            _buildMenuItem(Icons.assignment_outlined, 'My Orders'),
            _buildMenuItem(Icons.settings_outlined, 'Settings'),
            _buildMenuItem(Icons.help_outline, 'Help Center'),
            _buildMenuItem(Icons.logout, 'Log out', isDestructive: true),
            ProfileStyles.sizedBoxHeight50,
          ],
        ),
      ),
    ),
  );
}

  Widget _buildProfileImage(String? imageSource) {
    if (imageSource == null || imageSource.isEmpty) {
      return Container(
        color: ProfileStyles.beigeBackgroundColor,
        child: const Icon(Icons.person, color: ProfileStyles.primaryColor, size: 50),
      );
    }

    if (imageSource.startsWith('assets/')) {
      return Image.asset(imageSource, fit: BoxFit.cover);
    }

    if (imageSource.startsWith('http')) {
      return Image.network(
        imageSource,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: ProfileStyles.beigeBackgroundColor,
          child: const Icon(Icons.person, color: ProfileStyles.primaryColor, size: 50),
        ),
      );
    }

    try {
      final String cleanBase64 = imageSource.contains(',') ? imageSource.split(',').last : imageSource;
      return Image.memory(
        base64Decode(cleanBase64),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: ProfileStyles.beigeBackgroundColor,
          child: const Icon(Icons.person, color: ProfileStyles.primaryColor, size: 50),
        ),
      );
    } catch (e) {
      return Container(
        color: ProfileStyles.beigeBackgroundColor,
        child: const Icon(Icons.person, color: ProfileStyles.primaryColor, size: 50),
      );
    }
  }

  Widget _buildMenuItem(IconData icon, String title, {bool isDestructive = false}) {
    return InkWell(
      onTap: () async {
        if (isDestructive && title == 'Log out') {
          _handleLogout();
        } else if (title == 'Your profile') {
          if (_userData != null) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerProfileDetailScreen(userData: _userData!),
              ),
            );
            _fetchUserData();
          }
        } else if (title == 'Wallet') {
          if (_userData != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WalletScreen(userId: _userData!['user_id'] as int),
              ),
            );
          }
        } else if (title == 'Complaints') {
          if (_userData != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ComplaintsScreen(userId: _userData!['user_id'] as int),
              ),
            );
          }
        } else if (title == 'My Orders') {
          if (_userData != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyOrdersScreen(userId: _userData!['user_id']),
              ),
            );
          }
        } else if (title == 'Help Center') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
          );
        } else if (title == 'Settings') {
          if (_userData != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CustomerSettingsScreen(userId: _userData!['user_id'] as int)),
            );
          }
        }
      },
      splashColor: ProfileStyles.transparentColor,
      highlightColor: ProfileStyles.transparentColor,
      hoverColor: ProfileStyles.transparentColor,
      focusColor: ProfileStyles.transparentColor,
      child: Container(
        padding: ProfileStyles.paddingVertical16,
        decoration: ProfileStyles.menuItemDecoration,
        child: Row(
          children: [
            Icon(icon, color: ProfileStyles.primaryColor, size: 24),
            ProfileStyles.sizedBoxWidth16,
            Text(
              title,
              style: ProfileStyles.menuItemStyle,
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: ProfileStyles.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }
}
