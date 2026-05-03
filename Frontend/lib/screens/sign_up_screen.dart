import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../styles/app_colors.dart';
import '../styles/sign_up_styles.dart';
import 'sign_in_screen.dart';
import 'profile_completion_screen.dart';
import '../services/api_service.dart';
import '../widgets/custom_snackbar.dart';
import '../services/socket_service.dart';

class SignUpScreen extends StatefulWidget {
  final String? selectedRole; 
  
  const SignUpScreen({super.key, this.selectedRole});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();

  static void showRoleConfirmationDialog(BuildContext context, {Function(String?)? onRoleSelected}) {
    showDialog(
      context: context,
      barrierColor: SignUpStyles.dialogBarrierColor,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return RoleConfirmationDialog(onRoleSelected: onRoleSelected);
      },
    );
  }
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {

  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  bool _isButtonPressed = false;
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  
  String? _selectedRole;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _selectedRole = widget.selectedRole;
    
    _animationController = AnimationController(
      vsync: this,
      duration: SignUpStyles.animationDuration,
    );

    _fadeAnimation = Tween<double>(begin: SignUpStyles.fadeBegin, end: SignUpStyles.fadeEnd).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: SignUpStyles.animationCurve),
      ),
    );

    _slideAnimation = Tween<double>(begin: SignUpStyles.slideBegin, end: SignUpStyles.slideEnd).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: SignUpStyles.animationCurve),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocusNode.dispose();
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

  bool _validateName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _nameError = 'Name is required';
      return false;
    }
    if (name.length < 2) {
      _nameError = 'Name must be at least 2 characters';
      return false;
    }
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(name)) {
      _nameError = 'Name must contain letters only';
      return false;
    }
    _nameError = null;
    return true;
  }

  bool _validateEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _emailError = 'Email is required';
      return false;
    }
    
    if (email != email.toLowerCase()) {
      _emailError = 'Email must be in lowercase';
      return false;
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      _emailError = 'Email must be in format: xyz@abc.com';
      return false;
    }
    _emailError = null;
    return true;
  }

  bool _validatePassword() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      _passwordError = 'Password is required';
      return false;
    }
    if (password.length < 8) {
      _passwordError = 'Password must be at least 8 characters';
      return false;
    }
    if (!password.contains(RegExp(r'[a-zA-Z]')) || !password.contains(RegExp(r'[0-9]'))) {
      _passwordError = 'Password must contain 1 alphabet and 1 number';
      return false;
    }
    _passwordError = null;
    return true;
  }

    bool _validateAllFields() {
    
    bool hasEmpty = false;
    if (_nameController.text.trim().isEmpty) hasEmpty = true;
    if (_emailController.text.trim().isEmpty) hasEmpty = true;
    if (_passwordController.text.isEmpty) hasEmpty = true;

    if (hasEmpty) {
      _showErrorSnackBar('Please fill in all required fields');
      
      _validateName();
      _validateEmail();
      _validatePassword();
      return false;
    }

    bool isValid = true;
    isValid &= _validateName();
    isValid &= _validateEmail();
    isValid &= _validatePassword();

    if (!isValid) return false;

    if (!_agreeToTerms) {
      _showErrorSnackBar('Please agree to Terms & Conditions');
      return false;
    }
    
    return true;
  }

  void _showSnackBar(String message, Color backgroundColor) {
    bool isError = backgroundColor == AppColors.error;
    CustomSnackBar.show(context, message, isError: isError);
  }

  void _showErrorSnackBar(String message) {
    _showSnackBar(message, AppColors.error);
  }


  Widget _buildErrorTooltip(String errorMessage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: SignUpStyles.errorTooltipDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: SignUpStyles.errorIconDecoration,
            child: const Icon(
              Icons.error_outline,
              color: AppColors.white,
              size: 14,
            ),
          ),
          SignUpStyles.hSpaceSmall,
          Flexible(
            child: Text(
              errorMessage,
              style: SignUpStyles.errorTooltipStyle,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignUp() async {
    
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
    });

    if (!_validateAllFields()) {
      setState(() {});
      return;
    }

    setState(() {
      _isLoading = true;
      _isButtonPressed = true;
    });

    try {
      
      String role = _selectedRole ?? 'customer';
      
      final result = await ApiService.signUp(
        role: role,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result['success']) {
        setState(() {
          _isLoading = false;
          _isButtonPressed = false;
        });

        _showSignUpOtpDialog(role: role, email: _emailController.text.trim());
      } else {
        _showErrorSnackBar(result['message'] ?? 'Sign up failed. Please try again.');
        setState(() {
          _isLoading = false;
          _isButtonPressed = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred: ${e.toString()}');
      setState(() {
        _isLoading = false;
        _isButtonPressed = false;
      });
    }
  }

  void _showSignUpOtpDialog({required String role, required String email}) {
    showDialog(
      context: context,
      barrierColor: SignUpStyles.dialogBarrierColor,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return SignUpOtpDialog(
          role: role,
          email: email,
          onOtpVerified: (userId, message) {
            
            if (userId == null) return;

            Future.delayed(SignUpStyles.otpVerificationDelay, () {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileCompletionScreen(
                      userId: userId,
                      role: role,
                    ),
                  ),
                );
              }
            });
          },
        );
      },
    );
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
    final h = MediaQuery.of(context).size.height;
    final isSmallScreen = h < 700;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: SignUpStyles.mobileScreenPadding(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: SignUpStyles.stretchAlignment,
            children: [
              SizedBox(height: SignUpStyles.mobileTopPadding(context, isSmallScreen)),
              Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Create Account',
                    textAlign: SignUpStyles.centerAlignment,
                    style: SignUpStyles.headerStyle,
                  ),
                ),
              ),
              SignUpStyles.vSpaceSmall,
              Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    "Welcome! Let's get started",
                    textAlign: SignUpStyles.centerAlignment,
                    style: SignUpStyles.subHeaderStyle,
                  ),
                ),
              ),
              SizedBox(height: SignUpStyles.mobileMiddleSpacing(context, 0.07)),
              Transform.translate(
                offset: Offset(0, _slideAnimation.value * 0.9),
                child: FadeTransition(opacity: _fadeAnimation, child: _buildNameField()),
              ),
              SizedBox(height: SignUpStyles.mobileMiddleSpacing(context, 0.025)),
              Transform.translate(
                offset: Offset(0, _slideAnimation.value * 0.8),
                child: FadeTransition(opacity: _fadeAnimation, child: _buildEmailField()),
              ),

              SizedBox(height: SignUpStyles.mobileMiddleSpacing(context, 0.025)),
              Transform.translate(
                offset: Offset(0, _slideAnimation.value * 0.4),
                child: FadeTransition(opacity: _fadeAnimation, child: _buildPasswordField()),
              ),
              SignUpStyles.vSpaceMedium,
              Transform.translate(
                offset: Offset(0, _slideAnimation.value * 0.3),
                child: FadeTransition(opacity: _fadeAnimation, child: _buildTermsCheckbox()),
              ),
              SizedBox(height: SignUpStyles.mobileMiddleSpacing(context, 0.12)),
              Transform.translate(
                offset: Offset(0, _slideAnimation.value * 0.2),
                child: FadeTransition(opacity: _fadeAnimation, child: _buildSignUpButton()),
              ),
              SignUpStyles.vSpaceLarge,
              FadeTransition(opacity: _fadeAnimation, child: _buildSignInPrompt()),
              SizedBox(height: SignUpStyles.mobileBottomPadding(context, isSmallScreen)),
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
                padding: SignUpStyles.webScreenPadding,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: SignUpStyles.webCardMaxWidth,
                  ),
                  padding: const EdgeInsets.all(SignUpStyles.webContentPadding),
                  decoration: SignUpStyles.webCardDecoration,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: SignUpStyles.stretchAlignment,
                    children: [
                      SignUpStyles.vSpaceWebTop,
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: const Text(
                            'Create Account',
                            textAlign: SignUpStyles.centerAlignment,
                            style: SignUpStyles.headerStyle,
                          ),
                        ),
                      ),
                      SignUpStyles.vSpaceSmall,
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: const Text(
                            "Welcome! Let's get started",
                            textAlign: SignUpStyles.centerAlignment,
                            style: SignUpStyles.subHeaderStyle,
                          ),
                        ),
                      ),
                      SignUpStyles.vSpaceXXL,
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 0.9),
                        child: FadeTransition(opacity: _fadeAnimation, child: _buildNameField()),
                      ),
                      SignUpStyles.vSpaceLarge,
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 0.8),
                        child: FadeTransition(opacity: _fadeAnimation, child: _buildEmailField()),
                      ),
                      SignUpStyles.vSpaceLarge,
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 0.4),
                        child: FadeTransition(opacity: _fadeAnimation, child: _buildPasswordField()),
                      ),
                      SignUpStyles.vSpaceMedium,
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 0.3),
                        child: FadeTransition(opacity: _fadeAnimation, child: _buildTermsCheckbox()),
                      ),
                      SignUpStyles.vSpaceXXL,
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 0.2),
                        child: FadeTransition(opacity: _fadeAnimation, child: _buildSignUpButton()),
                      ),
                      SignUpStyles.vSpaceLarge,
                      FadeTransition(opacity: _fadeAnimation, child: _buildSignInPrompt()),
                      SignUpStyles.vSpaceWebTop,
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

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: SignUpStyles.startAlignment,
      children: [
        const Text(
          'Name',
          style: SignUpStyles.labelStyle,
        ),
        SignUpStyles.vSpaceSmall,
        Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: SignUpStyles.buttonTransitionDuration,
              curve: SignUpStyles.animationCurve,
              child: Focus(
                onKeyEvent: (node, event) => _handleKeyEvent(node, event, null, _emailFocusNode),
                child: TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  keyboardType: TextInputType.name,
                  style: SignUpStyles.fieldTextStyle,
                  onChanged: (_) {
                    if (_nameError != null) {
                      setState(() {
                        _nameError = null;
                      });
                    }
                  },
                decoration: SignUpStyles.inputDecoration(
                  context: context,
                  hint: 'Charlie Chaplin',
                  prefixIcon: Icons.person_outline,
                  errorText: _nameError,
                ),
              ),
              ),
            ),
            if (_nameError != null)
              Positioned(
                right: SignUpStyles.errorTooltipRight,
                top: SignUpStyles.errorTooltipTop,
                child: _buildErrorTooltip(_nameError!),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: SignUpStyles.startAlignment,
      children: [
        const Text(
          'Email',
          style: SignUpStyles.labelStyle,
        ),
        SignUpStyles.vSpaceSmall,
        Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: SignUpStyles.buttonTransitionDuration,
              curve: SignUpStyles.animationCurve,
              child: Focus(
                onKeyEvent: (node, event) => _handleKeyEvent(node, event, _nameFocusNode, _passwordFocusNode),
                child: TextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  style: SignUpStyles.fieldTextStyle,
                  onChanged: (_) {
                    if (_emailError != null) {
                      setState(() {
                        _emailError = null;
                      });
                    }
                  },
                decoration: SignUpStyles.inputDecoration(
                  context: context,
                  hint: 'example@gmail.com',
                  prefixIcon: Icons.email_outlined,
                  errorText: _emailError,
                  borderRadius: 25,
                ),
              ),
              ),
            ),
            if (_emailError != null)
              Positioned(
                right: SignUpStyles.errorTooltipRight,
                top: SignUpStyles.errorTooltipTop,
                child: _buildErrorTooltip(_emailError!),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: SignUpStyles.startAlignment,
      children: [
        const Text(
          'Password',
          style: SignUpStyles.labelStyle,
        ),
        SignUpStyles.vSpaceSmall,
        Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: SignUpStyles.buttonTransitionDuration,
              curve: SignUpStyles.animationCurve,
              child: Focus(
                onKeyEvent: (node, event) => _handleKeyEvent(node, event, _emailFocusNode, null),
                child: TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  style: SignUpStyles.fieldTextStyle,
                onChanged: (_) {
                  if (_passwordError != null) {
                    setState(() {
                      _passwordError = null;
                    });
                  }
                },
                decoration: SignUpStyles.inputDecoration(
                  context: context,
                  hint: '************',
                  prefixIcon: Icons.lock_outline,
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: AnimatedSwitcher(
                      duration: SignUpStyles.switcherDuration,
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        key: ValueKey<bool>(_obscurePassword),
                        color: AppColors.lightGray,
                        size: SignUpStyles.iconSizeSmall,
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
            ),
            if (_passwordError != null)
              Positioned(
                right: SignUpStyles.errorTooltipRight,
                top: SignUpStyles.errorTooltipTop,
                child: _buildErrorTooltip(_passwordError!),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _agreeToTerms = !_agreeToTerms;
            });
          },
          child: AnimatedContainer(
            duration: SignUpStyles.buttonTransitionDuration,
            width: SignUpStyles.checkboxSize,
            height: SignUpStyles.checkboxSize,
            decoration: SignUpStyles.checkboxDecoration(_agreeToTerms),
            child: _agreeToTerms
                ? const Icon(
                    Icons.check,
                    color: AppColors.white,
                    size: 14,
                  )
                : null,
          ),
        ),
        SignUpStyles.hSpaceSmall,
        Expanded(
          child: Row(
            children: [
              const Text(
                'Agree with ',
                style: SignUpStyles.termsTextStyle,
              ),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    barrierColor: SignUpStyles.dialogBarrierColor,
                    barrierDismissible: true,
                    builder: (BuildContext dialogContext) {
                      return const TermsAndConditionsDialog();
                    },
                  );
                },
                child: const Text(
                  'Terms & Condition',
                  style: SignUpStyles.linkStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignInPrompt() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        );
      },
      child: RichText(
        textAlign: SignUpStyles.centerAlignment,
        text: const TextSpan(
          style: SignUpStyles.promptStyle,
          children: [
            TextSpan(
              text: 'Already have an account? ',
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
            TextSpan(
              text: 'Sign In',
              style: SignUpStyles.linkStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return AnimatedContainer(
      duration: SignUpStyles.buttonTransitionDuration,
      curve: SignUpStyles.animationCurve,
      height: SignUpStyles.primaryButtonHeight,
      transform: Matrix4.identity()..scale(_isButtonPressed ? SignUpStyles.buttonScalePressed : SignUpStyles.buttonScaleNormal),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUp,
        style: SignUpStyles.primaryButtonStyle(),
        child: _isLoading
            ? const SizedBox(
                height: SignUpStyles.loadingIndicatorSize,
                width: SignUpStyles.loadingIndicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: SignUpStyles.loadingIndicatorStrokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : const Text(
                'Sign Up',
                style: SignUpStyles.buttonTextStyle,
              ),
      ),
    );
  }

}

class SignUpOtpDialog extends StatefulWidget {
  final String role;
  final String email;
  final Function(int?, String?) onOtpVerified;

  const SignUpOtpDialog({
    super.key,
    required this.role,
    required this.email,
    required this.onOtpVerified,
  });

  @override
  State<SignUpOtpDialog> createState() => _SignUpOtpDialogState();
}

class _SignUpOtpDialogState extends State<SignUpOtpDialog>
    with SingleTickerProviderStateMixin {

  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _otpError;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: SignUpStyles.dialogAnimationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: SignUpStyles.fadeBegin, end: SignUpStyles.fadeEnd).animate(
      CurvedAnimation(parent: _animationController, curve: SignUpStyles.dialogScaleCurve),
    );

    _fadeAnimation = Tween<double>(begin: SignUpStyles.fadeBegin, end: SignUpStyles.fadeEnd).animate(
      CurvedAnimation(parent: _animationController, curve: SignUpStyles.dialogFadeCurve),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _otpController.dispose();
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
              insetPadding: SignUpStyles.dialogInsetPadding(context, isMobile, screenWidth),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: SignUpStyles.dialogMaxWidth(isMobile),
                ),
                decoration: SignUpStyles.dialogDecoration,
                child: Padding(
                  padding: const EdgeInsets.all(SignUpStyles.dialogPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Verify Email',
                        style: SignUpStyles.dialogTitleStyle,
                      ),
                      SignUpStyles.vSpaceSmall,
                      Text(
                        'Enter the OTP sent to ${widget.email}',
                        textAlign: SignUpStyles.centerAlignment,
                        style: SignUpStyles.subHeaderStyle,
                      ),
                      SignUpStyles.vSpaceXXL,
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        decoration: SignUpStyles.inputDecoration(
                          context: context,
                          hint: 'Enter OTP',
                          prefixIcon: Icons.lock_outline,
                          errorText: _otpError,
                          borderRadius: SignUpStyles.dialogStepBorderRadius,
                        ),
                      ),
                      SignUpStyles.vSpaceXXL,
                      SizedBox(
                        width: double.infinity,
                        height: SignUpStyles.secondaryButtonHeight,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleOtpSubmit,
                          style: SignUpStyles.primaryButtonStyle(radius: SignUpStyles.secondaryButtonRadius),
                          child: _isLoading
                              ? const SizedBox(
                                  height: SignUpStyles.loadingIndicatorSize,
                                  width: SignUpStyles.loadingIndicatorSize,
                                  child: CircularProgressIndicator(strokeWidth: SignUpStyles.loadingIndicatorStrokeWidth, color: AppColors.white),
                                )
                              : const Text(
                                  'Verify OTP',
                                  style: SignUpStyles.dialogButtonTextStyle,
                                ),
                        ),
                      ),
                      SignUpStyles.vSpaceMedium,
                      SignUpStyles.vSpaceSmall,
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel', style: SignUpStyles.secondaryButtonTextStyle),
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
  }

  void _showDialogSnackBar(BuildContext context, String message, Color backgroundColor) {
    bool isError = backgroundColor == AppColors.error;
    CustomSnackBar.show(context, message, isError: isError);
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

    final result = await ApiService.verifySignUpOtp(widget.email, otp);
    
    if (result['success']) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        
        int? userId = result['user_id'];
        String? message = result['message'];
        Navigator.of(context).pop();
        widget.onOtpVerified(userId, message);
      }
    } else {
      setState(() {
        _isLoading = false;
        _otpError = result['message'] ?? 'Invalid OTP';
      });
    }
  }

}

class RoleConfirmationDialog extends StatefulWidget {
  final Function(String?)? onRoleSelected;
  
  const RoleConfirmationDialog({super.key, this.onRoleSelected});

  @override
  State<RoleConfirmationDialog> createState() => _RoleConfirmationDialogState();
}

class _RoleConfirmationDialogState extends State<RoleConfirmationDialog>
    with SingleTickerProviderStateMixin {

  String? _selectedRole;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: SignUpStyles.dialogAnimationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: SignUpStyles.fadeBegin,
      end: SignUpStyles.fadeEnd,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: SignUpStyles.dialogScaleCurve,
    ));

    _fadeAnimation = Tween<double>(
      begin: SignUpStyles.fadeBegin,
      end: SignUpStyles.fadeEnd,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: SignUpStyles.dialogFadeCurve,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
              insetPadding: SignUpStyles.dialogInsetPadding(context, isMobile, screenWidth),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: SignUpStyles.dialogMaxWidth(isMobile),
                ),
                decoration: SignUpStyles.dialogDecoration,
                child: Padding(
                  padding: const EdgeInsets.all(SignUpStyles.dialogPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      
                      const Text(
                        'Select Your Role',
                        style: SignUpStyles.dialogTitleStyle,
                      ),
                      SignUpStyles.vSpaceSmall,
                      
                      const Text(
                        'Choose how you want to use the app',
                        textAlign: SignUpStyles.centerAlignment,
                        style: SignUpStyles.subHeaderStyle,
                      ),
                      SignUpStyles.vSpaceXXL,
                      _buildRoleCard(
                        context: context,
                        role: 'Customer',
                        icon: Icons.shopping_bag_outlined,
                        description: 'Shop and browse products',
                        isSelected: _selectedRole == 'Customer',
                        onTap: () {
                          setState(() {
                            _selectedRole = 'Customer';
                          });
                        },
                      ),
                      SignUpStyles.vSpaceMedium,
                      _buildRoleCard(
                        context: context,
                        role: 'Seller',
                        icon: Icons.store_outlined,
                        description: 'Sell your products',
                        isSelected: _selectedRole == 'Seller',
                        onTap: () {
                          setState(() {
                            _selectedRole = 'Seller';
                          });
                        },
                      ),
                      SignUpStyles.vSpaceXXL,
                      
                      SizedBox(
                        width: double.infinity,
                        height: SignUpStyles.secondaryButtonHeight,
                        child: ElevatedButton(
                          onPressed: _selectedRole == null
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                  if (widget.onRoleSelected != null) {
                                    widget.onRoleSelected!(_selectedRole);
                                  }
                                },
                          style: SignUpStyles.primaryButtonStyle(radius: SignUpStyles.secondaryButtonRadius),
                          child: const Text(
                            'Confirm',
                            style: SignUpStyles.dialogButtonTextStyle,
                          ),
                        ),
                      ),
                      SignUpStyles.vSpaceMedium,
                      
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Cancel',
                          style: SignUpStyles.secondaryButtonTextStyle,
                        ),
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
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String role,
    required IconData icon,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: SignUpStyles.buttonTransitionDuration,
      curve: SignUpStyles.roleCardCurve,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: SignUpStyles.roleCardDecoration(isSelected),
          child: Row(
            children: [
              
              AnimatedContainer(
                duration: SignUpStyles.buttonTransitionDuration,
                width: SignUpStyles.iconSizeLarge,
                height: SignUpStyles.iconSizeLarge,
                decoration: SignUpStyles.roleIconDecoration(isSelected),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.white : AppColors.brown,
                  size: SignUpStyles.iconSizeMedium,
                ),
              ),
              SignUpStyles.hSpaceLarge,
              
              Expanded(
                child: Column(
                  crossAxisAlignment: SignUpStyles.startAlignment,
                  children: [
                    Text(
                      role,
                      style: SignUpStyles.roleCardTitleStyle.copyWith(
                        color: isSelected ? AppColors.brown : AppColors.darkText,
                      ),
                    ),
                    SignUpStyles.vSpaceTiny,
                    Text(
                      description,
                      style: SignUpStyles.roleCardDescStyle,
                    ),
                  ],
                ),
              ),
              
              AnimatedContainer(
                duration: SignUpStyles.buttonTransitionDuration,
                width: 24,
                height: 24,
                decoration: SignUpStyles.selectionIndicatorDecoration(isSelected),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: AppColors.white,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TermsAndConditionsDialog extends StatefulWidget {
  const TermsAndConditionsDialog({super.key});

  @override
  State<TermsAndConditionsDialog> createState() => _TermsAndConditionsDialogState();
}

class _TermsAndConditionsDialogState extends State<TermsAndConditionsDialog>
    with SingleTickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: SignUpStyles.dialogAnimationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: SignUpStyles.fadeBegin, end: SignUpStyles.fadeEnd).animate(
      CurvedAnimation(parent: _animationController, curve: SignUpStyles.dialogScaleCurve),
    );

    _fadeAnimation = Tween<double>(begin: SignUpStyles.fadeBegin, end: SignUpStyles.fadeEnd).animate(
      CurvedAnimation(parent: _animationController, curve: SignUpStyles.dialogFadeCurve),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
              insetPadding: SignUpStyles.dialogInsetPadding(context, isMobile, screenWidth),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: SignUpStyles.dialogMaxWidth(isMobile, customWidth: 600),
                ),
                decoration: SignUpStyles.dialogDecoration,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Terms & Conditions',
                        style: SignUpStyles.dialogTitleStyle,
                      ),
                      SignUpStyles.vSpaceSmall,
                      const Text(
                        'Please read and understand our terms',
                        textAlign: SignUpStyles.centerAlignment,
                        style: SignUpStyles.subHeaderStyle,
                      ),
                      SignUpStyles.vSpaceXXL,
                      _buildTermsContent(),
                      SignUpStyles.vSpaceXXL,
                      SizedBox(
                        width: double.infinity,
                        height: SignUpStyles.secondaryButtonHeight,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: SignUpStyles.primaryButtonStyle(radius: SignUpStyles.secondaryButtonRadius),
                          child: const Text(
                            'I Understand',
                            style: SignUpStyles.dialogButtonTextStyle,
                          ),
                        ),
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
  }

  Widget _buildTermsContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTermItem(
            number: '1',
            title: 'User Account Responsibility',
            content:
                'Keep your login details secure. You are responsible for all activity on your account. Report any unauthorized access immediately.',
          ),
          SignUpStyles.vSpaceXXL,
          _buildTermItem(
            number: '2',
            title: 'Product Information and Pricing',
            content:
                'We try to keep product details and prices accurate, but errors may occur. Prices and availability can change anytime.',
          ),
          SignUpStyles.vSpaceXXL,
          _buildTermItem(
            number: '3',
            title: 'Privacy and Data Protection',
            content:
                'Your data is handled according to our Privacy Policy. We protect your information and don’t share it without your consent.',
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem({
    required String number,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: SignUpStyles.termNumberDecoration,
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SignUpStyles.hSpaceMedium,
            Expanded(
              child: Text(
                title,
                style: SignUpStyles.termItemTitleStyle,
              ),
            ),
          ],
        ),
        SignUpStyles.vSpaceSmall,
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Text(
            content,
            style: SignUpStyles.termItemContentStyle,
          ),
        ),
      ],
    );
  }
}
