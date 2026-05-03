import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../styles/app_colors.dart';
import '../styles/sign_in_styles.dart';
import 'sign_up_screen.dart';
import 'admin_dashboard_screen.dart';
import 'seller_dashboard_screen.dart';
import '../services/api_service.dart';
import '../widgets/custom_snackbar.dart';
import 'customer_home_screen.dart';
import 'profile_completion_screen.dart';
import 'store_information_screen.dart';
import '../services/socket_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
    
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isButtonPressed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: SignInStyles.animationDuration,
    );

    _fadeAnimation = Tween<double>(begin: SignInStyles.fadeBegin, end: SignInStyles.fadeEnd).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: SignInStyles.animationCurve),
      ),
    );

    _slideAnimation = Tween<double>(begin: SignInStyles.slideBegin, end: SignInStyles.slideEnd).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: SignInStyles.animationCurve),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event, FocusNode? previousNode, FocusNode? nextNode) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown && nextNode != null) {
        nextNode.requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp && previousNode != null) {
        previousNode.requestFocus();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            if (isMobile) {
              return _buildMobileLayout(context);
            } else {
              return _buildWebLayout(context);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: SignInStyles.mobileScreenPadding(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: SignInStyles.stretchAlignment,
            children: [
              SizedBox(height: SignInStyles.mobileTopPadding(context, isSmallScreen)),
              Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Sign In',
                    textAlign: SignInStyles.centerAlignment,
                    style: SignInStyles.headerStyle,
                  ),
                ),
              ),
              SignInStyles.vSpaceSmall,
              Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    "Hi! Welcome back, you've been missed",
                    textAlign: SignInStyles.centerAlignment,
                    style: SignInStyles.subHeaderStyle,
                  ),
                ),
              ),
              SizedBox(height: SignInStyles.mobileMiddleSpacing(context)),
              Transform.translate(
                offset: Offset(0, _slideAnimation.value * 0.6),
                child: FadeTransition(opacity: _fadeAnimation, child: _buildEmailField()),
              ),
              SignInStyles.vSpaceLarge,
              Transform.translate(
                offset: Offset(0, _slideAnimation.value * 0.4),
                child: FadeTransition(opacity: _fadeAnimation, child: _buildPasswordField()),
              ),
              SignInStyles.vSpaceLarge,
              Transform.translate(
                offset: Offset(0, _slideAnimation.value * 0.2),
                child: FadeTransition(opacity: _fadeAnimation, child: _buildForgotPasswordLink()),
              ),
              SizedBox(height: SignInStyles.mobileSignInButtonSpacing(context)),
              Transform.translate(
                offset: Offset(0, _slideAnimation.value * 0.2),
                child: FadeTransition(opacity: _fadeAnimation, child: _buildSignInButton()),
              ),
              SignInStyles.vSpaceLarge,
              FadeTransition(opacity: _fadeAnimation, child: _buildSignUpPrompt()),
              SizedBox(height: SignInStyles.mobileSignUpBottomSpacing(context, isSmallScreen)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: SignInStyles.webScreenPadding,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: SignInStyles.webCardMaxWidth,
                  ),
                  padding: const EdgeInsets.all(SignInStyles.webContentPadding),
                  decoration: SignInStyles.webCardDecoration,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: SignInStyles.stretchAlignment,
                    children: [
                      SignInStyles.vSpaceWebTop,
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: const Text(
                            'Sign In',
                            textAlign: SignInStyles.centerAlignment,
                            style: SignInStyles.headerStyle,
                          ),
                        ),
                      ),
                      SignInStyles.vSpaceTiny,
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: const Text(
                            "Hi! Welcome back, you've been missed",
                            textAlign: SignInStyles.centerAlignment,
                            style: SignInStyles.subHeaderStyle,
                          ),
                        ),
                      ),
                      SignInStyles.vSpaceLarge,
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 0.6),
                        child: FadeTransition(opacity: _fadeAnimation, child: _buildEmailField()),
                      ),
                      SignInStyles.vSpaceMedium,
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 0.4),
                        child: FadeTransition(opacity: _fadeAnimation, child: _buildPasswordField()),
                      ),
                      SignInStyles.vSpaceSmall,
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 0.2),
                        child: FadeTransition(opacity: _fadeAnimation, child: _buildForgotPasswordLink()),
                      ),
                      SignInStyles.vSpaceLarge,
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 0.2),
                        child: FadeTransition(opacity: _fadeAnimation, child: _buildSignInButton()),
                      ),
                      SignInStyles.vSpaceMedium,
                      FadeTransition(opacity: _fadeAnimation, child: _buildSignUpPrompt()),
                      SignInStyles.vSpaceWebTop,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: SignInStyles.startAlignment,
      children: [
        const Text(
          'Email',
          style: SignInStyles.labelStyle,
        ),
        SignInStyles.vSpaceTiny,
        Focus(
          onKeyEvent: (node, event) => _handleKeyEvent(node, event, null, _passwordFocusNode),
          child: TextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            style: SignInStyles.fieldTextStyle,
            decoration: SignInStyles.inputDecoration(
              hint: 'example@gmail.com',
              prefixIcon: Icons.email_outlined,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: SignInStyles.startAlignment,
      children: [
        const Text(
          'Password',
          style: SignInStyles.labelStyle,
        ),
        SignInStyles.vSpaceTiny,
        Focus(
          onKeyEvent: (node, event) => _handleKeyEvent(node, event, _emailFocusNode, null),
          child: TextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            style: SignInStyles.fieldTextStyle,
            decoration: SignInStyles.inputDecoration(
              hint: '************',
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: AnimatedSwitcher(
                  duration: SignInStyles.switcherDuration,
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    key: ValueKey<bool>(_obscurePassword),
                    color: AppColors.lightGray,
                    size: SignInStyles.iconSizeSmall,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: SignInStyles.rightAlignment,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            barrierColor: SignInStyles.dialogBarrierColor,
            barrierDismissible: true,
            builder: (BuildContext dialogContext) {
              return const ForgotPasswordDialog();
            },
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: SignInStyles.forgotPasswordLinkPadding,
          child: Text(
            'Forgot Password?',
            style: SignInStyles.linkStyle,
          ),
        ),
      ),
    );
  }

  void _handleSignIn() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your email');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showErrorSnackBar('Please enter your password');
      return;
    }

    setState(() {
      _isLoading = true;
      _isButtonPressed = true;
    });

    try {
      final result = await ApiService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result['success']) {
        final message = result['message'] ?? 'Sign in successful!';
        if (message.toString().toLowerCase().contains('complete your profile') || 
            message.toString().toLowerCase().contains('complete your store')) {
          _showErrorSnackBar(message);
        }

        final role = result['role']?.toString().toLowerCase() ?? 'customer';
        final userId = result['user_id'];
        final userName = result['name'] ?? 'User';
        final bool profileCompleted = result['profile_completed'] ?? true;
        final bool storeCompleted = result['store_completed'] ?? true;
        
        if (role == 'admin' || role == 'seller') {
          SocketService().connect(userId);
        }
        
        Future.delayed(SignInStyles.navigationDelay, () {
          if (!mounted) return;

          if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminDashboardScreen(
                  adminName: userName,
                  userId: userId,
                ),
              ),
            );
          } else if (role == 'seller') {
            if (!profileCompleted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileCompletionScreen(
                    userId: userId,
                    role: role,
                  ),
                ),
              );
            } else if (!storeCompleted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => StoreInformationScreen(
                    userId: userId,
                    role: role,
                  ),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SellerDashboardScreen(
                    sellerName: userName,
                    userId: userId,
                  ),
                ),
              );
            }
          } else if (role == 'customer') {
            if (!profileCompleted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileCompletionScreen(
                    userId: userId,
                    role: role,
                  ),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerHomeScreen(userId: userId),
                ),
              );
            }
          } else {
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerHomeScreen(userId: userId),
              ),
            );
          }
        });
      } else {
        _showErrorSnackBar(result['message'] ?? 'Sign in failed. Please check your credentials.');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isButtonPressed = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    bool isError = backgroundColor == AppColors.error;
    CustomSnackBar.show(context, message, isError: isError);
  }

  void _showErrorSnackBar(String message) {
    _showSnackBar(message, AppColors.error);
  }

  Widget _buildSignInButton() {
    return AnimatedContainer(
      duration: SignInStyles.buttonTransitionDuration,
      curve: SignInStyles.animationCurve,
      height: SignInStyles.primaryButtonHeight,
      transform: Matrix4.identity()..scale(_isButtonPressed ? SignInStyles.buttonScalePressed : SignInStyles.buttonScaleNormal),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignIn,
        style: SignInStyles.primaryButtonStyle(),
        child: _isLoading
            ? const SizedBox(
                height: SignInStyles.loadingIndicatorSize,
                width: SignInStyles.loadingIndicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: SignInStyles.loadingIndicatorStrokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : const Text(
                'Sign In',
                style: SignInStyles.buttonTextStyle,
              ),
      ),
    );
  }

  Widget _buildSignUpPrompt() {
    return GestureDetector(
      onTap: () {
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
      child: RichText(
        textAlign: SignInStyles.centerAlignment,
        text: const TextSpan(
          style: SignInStyles.promptStyle,
          children: [
            TextSpan(
              text: "Don't have an account? ",
              style: SignInStyles.normalWeightStyle,
            ),
            TextSpan(
              text: 'Sign Up',
              style: SignInStyles.linkStyle,
            ),
          ],
        ),
      ),
    );
  }

}

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog>
    with SingleTickerProviderStateMixin {

  int _currentStep = 1; 
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _emailError;
  String? _otpError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _canResendOtp = true;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: SignInStyles.dialogAnimationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: SignInStyles.fadeBegin, end: SignInStyles.fadeEnd).animate(
      CurvedAnimation(parent: _animationController, curve: SignInStyles.dialogScaleCurve),
    );

    _fadeAnimation = Tween<double>(begin: SignInStyles.fadeBegin, end: SignInStyles.fadeEnd).animate(
      CurvedAnimation(parent: _animationController, curve: SignInStyles.dialogFadeCurve),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: SignInStyles.dialogInsetPadding(context, isMobile, screenWidth),
              child: Container(
                constraints: BoxConstraints(maxWidth: SignInStyles.dialogMaxWidth(isMobile)),
                decoration: SignInStyles.dialogDecoration,
                child: Padding(
                  padding: const EdgeInsets.all(SignInStyles.dialogPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getTitle(),
                        style: SignInStyles.dialogTitleStyle,
                      ),
                      SignInStyles.vSpaceTiny,
                      Text(
                        _getSubtitle(),
                        textAlign: SignInStyles.centerAlignment,
                        style: SignInStyles.subHeaderStyle,
                      ),
                      SignInStyles.vSpaceLarge,
                      if (_currentStep == 1) _buildEmailStep(),
                      if (_currentStep == 2) _buildOtpStep(),
                      if (_currentStep == 3) _buildPasswordStep(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getTitle() {
    switch (_currentStep) {
      case 1:
        return 'Forgot Password';
      case 2:
        return 'Enter OTP';
      case 3:
        return 'Reset Password';
      default:
        return 'Forgot Password';
    }
  }

  String _getSubtitle() {
    switch (_currentStep) {
      case 1:
        return 'Enter your email address';
      case 2:
        return 'Enter the OTP sent to ${_emailController.text.trim()}';
      case 3:
        return 'Enter your new password';
      default:
        return '';
    }
  }

  void _showDialogSnackBar(BuildContext context, String message, Color backgroundColor) {
    bool isError = backgroundColor == AppColors.error;
    CustomSnackBar.show(context, message, isError: isError);
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: SignInStyles.inputDecoration(
            hint: 'Email',
            prefixIcon: Icons.email_outlined,
            errorText: _emailError,
            borderRadius: SignInStyles.dialogStepBorderRadius,
          ),
        ),
        SignInStyles.vSpaceLarge,
        SizedBox(
          width: double.infinity,
          height: SignInStyles.secondaryButtonHeight,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailSubmit,
            style: SignInStyles.primaryButtonStyle(radius: SignInStyles.secondaryButtonRadius),
            child: _isLoading
                ? const SizedBox(
                    height: SignInStyles.loadingIndicatorSizeSmall,
                    width: SignInStyles.loadingIndicatorSizeSmall,
                    child: CircularProgressIndicator(strokeWidth: SignInStyles.loadingIndicatorStrokeWidth, color: AppColors.white),
                  )
                : const Text(
                    'Send OTP',
                    style: SignInStyles.dialogButtonTextStyle,
                  ),
          ),
        ),
        SignInStyles.vSpaceSmall,
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: SignInStyles.buttonSecondaryTextStyle),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: SignInStyles.inputDecoration(
            hint: 'Enter OTP',
            prefixIcon: Icons.lock_outline,
            errorText: _otpError,
            borderRadius: SignInStyles.dialogStepBorderRadius,
          ),
        ),
        SignInStyles.vSpaceLarge,
        SizedBox(
          width: double.infinity,
          height: SignInStyles.secondaryButtonHeight,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleOtpSubmit,
            style: SignInStyles.primaryButtonStyle(radius: SignInStyles.secondaryButtonRadius),
            child: _isLoading
                ? const SizedBox(
                    height: SignInStyles.loadingIndicatorSizeSmall,
                    width: SignInStyles.loadingIndicatorSizeSmall,
                    child: CircularProgressIndicator(strokeWidth: SignInStyles.loadingIndicatorStrokeWidth, color: AppColors.white),
                  )
                : const Text(
                    'Verify OTP',
                    style: SignInStyles.dialogButtonTextStyle,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: SignInStyles.buttonSecondaryTextStyle),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          decoration: SignInStyles.inputDecoration(
            hint: 'New Password',
            prefixIcon: Icons.lock_outline,
            errorText: _passwordError,
            borderRadius: SignInStyles.dialogStepBorderRadius,
            suffixIcon: IconButton(
              icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility, color: AppColors.lightGray, size: 20),
              onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),
          ),
        ),
        SignInStyles.vSpaceMedium,
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: SignInStyles.inputDecoration(
            hint: 'Confirm Password',
            prefixIcon: Icons.lock_outline,
            errorText: _confirmPasswordError,
            borderRadius: SignInStyles.dialogStepBorderRadius,
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: AppColors.lightGray, size: 20),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ),
        SignInStyles.vSpaceLarge,
        SizedBox(
          width: double.infinity,
          height: SignInStyles.secondaryButtonHeight,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handlePasswordSubmit,
            style: SignInStyles.primaryButtonStyle(radius: SignInStyles.secondaryButtonRadius),
            child: _isLoading
                ? const SizedBox(
                    height: SignInStyles.loadingIndicatorSizeSmall,
                    width: SignInStyles.loadingIndicatorSizeSmall,
                    child: CircularProgressIndicator(strokeWidth: SignInStyles.loadingIndicatorStrokeWidth, color: AppColors.white),
                  )
                : const Text(
                    'Reset Password',
                    style: SignInStyles.dialogButtonTextStyle,
                  ),
          ),
        ),
        SignInStyles.vSpaceSmall,
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: SignInStyles.buttonSecondaryTextStyle),
        ),
      ],
    );
  }

  void _handleEmailSubmit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return;
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Email must be in format: xyz@abc.com');
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = null;
    });

    final result = await ApiService.forgotPassword(email);
    
    if (result['success']) {
      setState(() {
        _currentStep = 2;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _emailError = result['message'] ?? 'Failed to send OTP';
      });
    }
  }

  void _handleOtpSubmit() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => _otpError = 'OTP is required');
      return;
    }

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    final result = await ApiService.verifyOtp(_emailController.text.trim(), otp);
    
    if (result['success']) {
      setState(() {
        _currentStep = 3;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _otpError = result['message'] ?? 'Invalid OTP';
      });
    }
  }

  void _handlePasswordSubmit() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _passwordError = null;
      _confirmPasswordError = null;
    });

    if (newPassword.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      return;
    }
    if (newPassword.length < 8) {
      setState(() => _passwordError = 'Password must be at least 8 characters');
      return;
    }
    if (!newPassword.contains(RegExp(r'[a-zA-Z]')) || !newPassword.contains(RegExp(r'[0-9]'))) {
      setState(() => _passwordError = 'Password must contain 1 alphabet and 1 number');
      return;
    }
    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Please confirm your password');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.resetPassword(_emailController.text.trim(), newPassword);
    
    if (result['success']) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      setState(() {
        _isLoading = false;
        _passwordError = result['message'] ?? 'Failed to reset password';
      });
    }
  }
}
