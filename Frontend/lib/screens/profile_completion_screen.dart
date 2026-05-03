import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import 'dart:convert' show base64Encode;
import '../services/api_service.dart';
import 'sign_in_screen.dart';
import 'store_information_screen.dart';
import '../widgets/custom_snackbar.dart';
import '../styles/profile_completion_styles.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final int userId;
  final String role; 

  const ProfileCompletionScreen({
    super.key,
    required this.userId,
    required this.role,
  });

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> 
    with SingleTickerProviderStateMixin {
  
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  
  final FocusNode _cnicFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _genderFocusNode = FocusNode();
  
  final GlobalKey _genderFieldKey = GlobalKey();
  
  String? _selectedGender;
  File? _profileImage;
  String? _webImage;
  XFile? _pickedFile;
  bool _isLoading = false;
  
  String? _phoneError;
  String? _addressError;
  String? _cnicError;
  String? _genderError;
  String? _imageError;

  final ImagePicker _picker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  bool get _isSeller => widget.role.toLowerCase() == 'seller';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: ProfileCompletionStyles.pageAnimationDuration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: ProfileCompletionStyles.animationCurve),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: ProfileCompletionStyles.animationCurve),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cnicController.dispose();
    _genderController.dispose();
    
    _cnicFocusNode.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    _genderFocusNode.dispose();
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (image != null) {
        setState(() {
          _pickedFile = image;
          if (kIsWeb) {
            _webImage = image.path;
          } else {
            _profileImage = File(image.path);
          }
          _imageError = null;
        });
      }
    } catch (e) {
      CustomSnackBar.show(context, 'Failed to pick image: $e', isError: true);
    }
  }

  bool _validate() {
    bool isValid = true;
    
    if (_isSeller) {
      if (_cnicController.text.trim().isEmpty) {
        _cnicError = 'CNIC is required';
        isValid = false;
      } else if (_cnicController.text.trim().length != 13) {
        _cnicError = 'CNIC must be 13 digits';
        isValid = false;
      } else {
        _cnicError = null;
      }
    }

    if (_phoneController.text.trim().isEmpty) {
      _phoneError = 'Phone number is required';
      isValid = false;
    } else if (_phoneController.text.trim().length != 11) {
      _phoneError = 'Phone number must be 11 digits';
      isValid = false;
    } else {
      _phoneError = null;
    }

    if (_addressController.text.trim().isEmpty) {
      _addressError = 'Address is required';
      isValid = false;
    } else if (_addressController.text.trim().length < 10) {
      _addressError = 'Address must be at least 10 characters';
      isValid = false;
    } else if (RegExp(r'^[0-9]+$').hasMatch(_addressController.text.trim())) {
      _addressError = 'Address cannot be all numbers';
      isValid = false;
    } else {
      _addressError = null;
    }

    if (_selectedGender == null) {
      _genderError = 'Gender is required';
      isValid = false;
    } else {
      _genderError = null;
    }

    if (_isSeller && _pickedFile == null) {
      _imageError = 'Profile picture is required';
      isValid = false;
    } else {
      _imageError = null;
    }

    setState(() {});
    return isValid;
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? profilePicData;
      if (_pickedFile != null) {
        final bytes = await _pickedFile!.readAsBytes();
        final extension = _pickedFile!.path.split('.').last.toLowerCase();
        final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
        profilePicData = 'data:$mimeType;base64,${base64Encode(bytes)}';
      }

      final result = await ApiService.updateProfile(
        userId: widget.userId,
        cnic: _isSeller ? _cnicController.text.trim() : null,
        contactNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        gender: _selectedGender,
        profilePicture: profilePicData,
      );

      if (result['success']) {
        if (mounted) {
          if (_isSeller) {
             Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StoreInformationScreen(
                  userId: widget.userId,
                  role: widget.role,
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SignInScreen()),
            );
          }
        }
      } else {
        if (mounted) {
          CustomSnackBar.show(context, result['message'] ?? 'Failed to update profile', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showGenderMenu() {
    final RenderBox renderBox = _genderFieldKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height + 5,
        position.dx + size.width,
        position.dy + size.height + 200,
      ),
      items: ['Male', 'Female']
          .map((label) => PopupMenuItem<String>(
                value: label,
                child: Container(
                  width: size.width,
                  alignment: Alignment.centerLeft,
                  child: Text(label, style: ProfileCompletionStyles.inputTextStyle),
                ),
              ))
          .toList(),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: ProfileCompletionStyles.whiteColor,
      constraints: BoxConstraints(
        minWidth: size.width,
        maxWidth: size.width,
      ),
    ).then((value) {
      if (value != null) {
        setState(() {
          _selectedGender = value;
          _genderController.text = value;
          _genderError = null;
        });
      }
    });
  }

  Widget _buildErrorTooltip(String errorMessage) {
    return Container(
      padding: ProfileCompletionStyles.tooltipPadding,
      decoration: ProfileCompletionStyles.errorTooltipDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ProfileCompletionStyles.tooltipIconContainerSize,
            height: ProfileCompletionStyles.tooltipIconContainerSize,
            decoration: ProfileCompletionStyles.errorIconDecoration,
            child: const Icon(
              Icons.error_outline,
              color: ProfileCompletionStyles.whiteColor,
              size: ProfileCompletionStyles.iconSizeSmall,
            ),
          ),
          ProfileCompletionStyles.hSpaceSmall,
          Flexible(
            child: Text(
              errorMessage,
              style: ProfileCompletionStyles.tooltipTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: ProfileCompletionStyles.whiteColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (isMobile) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: ProfileCompletionStyles.mobileScreenPadding,
                child: _buildMainContent(isMobile: true),
              );
            } else {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: ProfileCompletionStyles.webScreenPadding,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: ProfileCompletionStyles.webCardMaxWidth),
                        padding: ProfileCompletionStyles.webContainerPadding,
                        decoration: ProfileCompletionStyles.webCardDecoration,
                        child: _buildMainContent(isMobile: false),
                      ),
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildMainContent({required bool isMobile}) {
    final nextNodeForPhone = _isSeller ? _cnicFocusNode : null;
    final nextNodeForCnic = _phoneFocusNode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ProfileCompletionStyles.headerSpacer(isMobile),
        Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: const Text(
              'Complete Your Profile',
              style: ProfileCompletionStyles.headerStyle,
            ),
          ),
        ),
        ProfileCompletionStyles.spaceTiny,
        Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              _isSeller 
                  ? "Please provide your details to continue\nas a seller"
                  : "Don't worry, only you can see your personal\ndata. No one else will be able to see it",
              textAlign: TextAlign.center,
              style: ProfileCompletionStyles.subHeaderStyle,
            ),
          ),
        ),
        ProfileCompletionStyles.subHeaderSpacer(isMobile),
        
        Transform.translate(
           offset: Offset(0, _slideAnimation.value * 0.9),
           child: FadeTransition(
             opacity: _fadeAnimation,
             child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: isMobile ? ProfileCompletionStyles.profilePicSizeMobile : ProfileCompletionStyles.profilePicSizeWeb,
                        height: isMobile ? ProfileCompletionStyles.profilePicSizeMobile : ProfileCompletionStyles.profilePicSizeWeb,
                        decoration: ProfileCompletionStyles.profilePlaceholderDecoration(
                          isError: _imageError != null,
                          hasImage: kIsWeb ? _webImage != null : _profileImage != null,
                          image: (kIsWeb ? _webImage != null : _profileImage != null)
                              ? (kIsWeb 
                                  ? NetworkImage(_webImage!) as ImageProvider
                                  : FileImage(_profileImage!))
                              : null,
                        ),
                        child: (kIsWeb ? _webImage == null : _profileImage == null)
                            ? Icon(
                                Icons.person, 
                                size: isMobile ? ProfileCompletionStyles.profileIconSizeMobile : ProfileCompletionStyles.profileIconSizeWeb, 
                                color: ProfileCompletionStyles.placeholderIconColor
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: ProfileCompletionStyles.editIconDecoration,
                          child: const Icon(
                            Icons.edit,
                            color: ProfileCompletionStyles.whiteColor,
                            size: ProfileCompletionStyles.iconSizeMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_imageError != null)
                  Positioned(
                    right: -100,
                    top: 0,
                    child: _buildErrorTooltip(_imageError!),
                  ),
              ],
            ),
          ),
        ),
        
        if (_isSeller) ...[
          ProfileCompletionStyles.spaceLarge,
          Transform.translate(
             offset: Offset(0, _slideAnimation.value * 0.85),
             child: FadeTransition(
               opacity: _fadeAnimation,
               child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CNIC',
                    style: ProfileCompletionStyles.labelStyle,
                  ),
                  ProfileCompletionStyles.spaceSmall,
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Focus(
                        onKeyEvent: (node, event) => _handleKeyEvent(node, event, null, _phoneFocusNode),
                        child: TextField(
                          controller: _cnicController,
                          focusNode: _cnicFocusNode,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 13,
                          style: ProfileCompletionStyles.inputTextStyle,
                          decoration: ProfileCompletionStyles.inputDecoration(
                            hintText: '1234567890123',
                            counterText: "",
                            icon: Icons.credit_card,
                            errorText: _cnicError,
                          ),
                          onChanged: (_) {
                            if (_cnicError != null) {
                              setState(() {
                                _cnicError = null;
                              });
                            }
                          },
                        ),
                      ),
                      if (_cnicError != null)
                        Positioned(
                          right: 0,
                          top: -8,
                          child: _buildErrorTooltip(_cnicError!),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        
        ProfileCompletionStyles.spaceMedium,
        
        Transform.translate(
           offset: Offset(0, _slideAnimation.value * 0.8),
           child: FadeTransition(
             opacity: _fadeAnimation,
             child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phone Number',
                  style: ProfileCompletionStyles.labelStyle,
                ),
                ProfileCompletionStyles.spaceSmall,
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Focus(
                      onKeyEvent: (node, event) => _handleKeyEvent(node, event, _isSeller ? _cnicFocusNode : null, _addressFocusNode),
                      child: TextField(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 11,
                        style: ProfileCompletionStyles.inputTextStyle,
                        decoration: ProfileCompletionStyles.inputDecoration(
                          hintText: '03001234567',
                          counterText: "",
                          icon: Icons.phone_outlined,
                          errorText: _phoneError,
                        ),
                        onChanged: (_) {
                          if (_phoneError != null) {
                            setState(() {
                              _phoneError = null;
                            });
                          }
                        },
                      ),
                    ),
                    if (_phoneError != null)
                      Positioned(
                        right: 0,
                        top: -8,
                        child: _buildErrorTooltip(_phoneError!),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        ProfileCompletionStyles.spaceMedium,
        
        Transform.translate(
           offset: Offset(0, _slideAnimation.value * 0.7),
           child: FadeTransition(
             opacity: _fadeAnimation,
             child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Address',
                  style: ProfileCompletionStyles.labelStyle,
                ),
                ProfileCompletionStyles.spaceSmall,
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Focus(
                      onKeyEvent: (node, event) => _handleKeyEvent(node, event, _phoneFocusNode, _genderFocusNode),
                      child: TextField(
                        controller: _addressController,
                        focusNode: _addressFocusNode,
                        keyboardType: TextInputType.streetAddress,
                        style: ProfileCompletionStyles.inputTextStyle,
                        decoration: ProfileCompletionStyles.inputDecoration(
                          hintText: 'ABC Rd, Karachi, Pakistan',
                          icon: Icons.location_on_outlined,
                          errorText: _addressError,
                        ),
                        onChanged: (_) {
                          if (_addressError != null) {
                            setState(() {
                              _addressError = null;
                            });
                          }
                        },
                      ),
                    ),
                    if (_addressError != null)
                      Positioned(
                        right: 0,
                        top: -8,
                        child: _buildErrorTooltip(_addressError!),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        ProfileCompletionStyles.spaceMedium,
        
        Transform.translate(
           offset: Offset(0, _slideAnimation.value * 0.6),
           child: FadeTransition(
             opacity: _fadeAnimation,
             child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gender',
                  style: ProfileCompletionStyles.labelStyle,
                ),
                ProfileCompletionStyles.spaceSmall,

                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: _showGenderMenu,
                      child: AbsorbPointer(
                        child: Focus(
                          onKeyEvent: (node, event) => _handleKeyEvent(node, event, _addressFocusNode, null),
                          child: TextFormField(
                            key: _genderFieldKey,
                            controller: _genderController,
                            focusNode: _genderFocusNode,
                            readOnly: true,
                            style: ProfileCompletionStyles.inputTextStyle,
                            decoration: ProfileCompletionStyles.inputDecoration(
                              hintText: 'Select Gender',
                              icon: Icons.people_outline,
                              errorText: _genderError,
                              suffixIcon: Icon(
                                Icons.keyboard_arrow_down,
                                color: ProfileCompletionStyles.lightGrayColor.withOpacity(0.6),
                                size: ProfileCompletionStyles.iconSizeRegular,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_genderError != null)
                      Positioned(
                        right: 0,
                        top: -8,
                        child: _buildErrorTooltip(_genderError!),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        ProfileCompletionStyles.footerSpacer(isMobile),
        
        Transform.translate(
           offset: Offset(0, _slideAnimation.value * 0.2),
           child: FadeTransition(
             opacity: _fadeAnimation,
             child: SizedBox(
              width: double.infinity,
              height: ProfileCompletionStyles.submitButtonHeight,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ProfileCompletionStyles.submitButtonStyle,
                child: _isLoading
                    ? const CircularProgressIndicator(color: ProfileCompletionStyles.whiteColor)
                    : const Text(
                        'Complete Profile',
                        style: ProfileCompletionStyles.buttonTextStyle,
                      ),
              ),
            ),
          ),
        ),
        ProfileCompletionStyles.spaceLarge,
      ],
    );
  }
}
