import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io' show Directory, File;
import 'sign_in_screen.dart';
import '../services/api_service.dart';
import '../widgets/custom_snackbar.dart';
import '../styles/store_information_styles.dart';

class StoreInformationScreen extends StatefulWidget {
  final int userId;
  final String role;

  const StoreInformationScreen({
    super.key,
    required this.userId,
    required this.role,
  });

  @override
  State<StoreInformationScreen> createState() => _StoreInformationScreenState();
}

class _StoreInformationScreenState extends State<StoreInformationScreen>
    with SingleTickerProviderStateMixin {
  
  bool _isButtonPressed = false;
  bool _isLoading = false;
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  
  final FocusNode _storeNameFocusNode = FocusNode();
  final FocusNode _bioFocusNode = FocusNode();
  final FocusNode _websiteFocusNode = FocusNode();
  final FocusNode _instagramFocusNode = FocusNode();
  
  String? _logoPath; 
  Uint8List? _webImageBytes; 
  final ImagePicker _imagePicker = ImagePicker();

  String? _storeNameError;
  String? _bioError;
  String? _websiteError;
  String? _instagramError;
  String? _logoError;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: StoreInformationStyles.pageAnimationDuration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _storeNameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    
    _storeNameFocusNode.dispose();
    _bioFocusNode.dispose();
    _websiteFocusNode.dispose();
    _instagramFocusNode.dispose();
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

  Future<void> _pickLogoImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          
          final String base64Image = base64Encode(bytes);
          final String mimeType = image.mimeType ?? 'image/jpeg';
          final String base64DataUrl = 'data:$mimeType;base64,$base64Image';
          
          setState(() {
            _webImageBytes = bytes;
            _logoPath = base64DataUrl;
          });
        } else {
          final Directory appDocDir = await getApplicationDocumentsDirectory();
          final String logosDir = path.join(appDocDir.path, 'logos');
          
          final Directory logosDirectory = Directory(logosDir);
          if (!await logosDirectory.exists()) {
            await logosDirectory.create(recursive: true);
          }

          final String fileName = 'logo_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
          final String savedPath = path.join(logosDir, fileName);

          await File(image.path).copy(savedPath);

          setState(() {
            _logoPath = savedPath;
            _logoError = null;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  bool _validateStoreName() {
    if (_storeNameController.text.trim().isEmpty) {
      _storeNameError = 'Store name is required';
      return false;
    }
    if (_storeNameController.text.trim().length < 2) {
      _storeNameError = 'Store name must be at least 2 characters';
      return false;
    }
    _storeNameError = null;
    return true;
  }

  bool _validateBio() {
    if (_bioController.text.trim().isEmpty) {
      _bioError = 'Bio is required';
      return false;
    }
    if (_bioController.text.trim().length < 10) {
      _bioError = 'Bio must be at least 10 characters';
      return false;
    }
    _bioError = null;
    return true;
  }

  bool _validateWebsite() {
    final website = _websiteController.text.trim();
    if (website.isNotEmpty) {
      final urlRegex = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');
      if (!urlRegex.hasMatch(website)) {
        _websiteError = 'Please enter a valid URL (e.g., https://example.com)';
        return false;
      }
    }
    _websiteError = null;
    return true;
  }

  bool _validateInstagram() {
    final instagram = _instagramController.text.trim();
    if (instagram.isNotEmpty) {
      if (!instagram.startsWith('@')) {
        _instagramError = 'Instagram handle must start with @';
        return false;
      }
      if (instagram.length < 2) {
        _instagramError = 'Please enter a valid Instagram handle';
        return false;
      }
    }
    _instagramError = null;
    return true;
  }

  bool _validateAllFields() {
    bool isValid = true;
    isValid &= _validateStoreName();
    isValid &= _validateBio();
    isValid &= _validateWebsite();
    isValid &= _validateInstagram();
    
    if (_logoPath == null && _webImageBytes == null) {
      _logoError = 'Store logo is required';
      isValid = false;
    } else {
      _logoError = null;
    }
    return isValid;
  }

  void _showErrorSnackBar(String message) {
    CustomSnackBar.show(context, message, isError: true);
  }

  Widget _buildErrorTooltip(String errorMessage) {
    return Container(
      padding: StoreInformationStyles.tooltipPadding,
      decoration: StoreInformationStyles.errorTooltipDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: StoreInformationStyles.tooltipIconContainerSize,
            height: StoreInformationStyles.tooltipIconContainerSize,
            decoration: StoreInformationStyles.errorIconDecoration,
            child: const Icon(
              Icons.error_outline,
              color: StoreInformationStyles.whiteColor,
              size: StoreInformationStyles.iconSizeSmall,
            ),
          ),
          StoreInformationStyles.hSpaceMedium,
          Flexible(
            child: Text(
              errorMessage,
              style: StoreInformationStyles.tooltipTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _storeNameError = null;
      _bioError = null;
      _websiteError = null;
      _instagramError = null;
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
      final result = await ApiService.saveStoreInfo(
        userId: widget.userId,
        role: widget.role,
        storeName: _storeNameController.text.trim(),
        bio: _bioController.text.trim(),
        logo: _logoPath,
        website: _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
        instagram: _instagramController.text.trim().isNotEmpty ? _instagramController.text.trim() : null,
      );

      if (result['success']) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SignInScreen(),
            ),
          );
        }
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to save store information. Please try again.');
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: StoreInformationStyles.whiteColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (isMobile) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: StoreInformationStyles.mobileScreenPadding,
                child: _buildMainContent(isMobile: true),
              );
            } else {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: StoreInformationStyles.webScreenPadding,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 450),
                        padding: StoreInformationStyles.webContainerPadding,
                        decoration: StoreInformationStyles.webContainerDecoration,
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
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StoreInformationStyles.headerSpacer(isMobile),
            Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Store Information',
                  textAlign: TextAlign.center,
                  style: StoreInformationStyles.titleStyle,
                ),
              ),
            ),
            StoreInformationStyles.spaceTiny,
            Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  "Let's set up your store",
                  textAlign: TextAlign.center,
                  style: StoreInformationStyles.subtitleStyle,
                ),
              ),
            ),
            StoreInformationStyles.sectionSpacer(isMobile),
            
            Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(child: _buildLogoImagePicker()),
              ),
            ),
            SizedBox(height: isMobile ? 24 : 18),

            Transform.translate(
              offset: Offset(0, _slideAnimation.value * 0.9),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Store Name',
                      style: StoreInformationStyles.labelStyle,
                    ),
                    StoreInformationStyles.spaceSmall,
                    _buildStoreNameField(),
                  ],
                ),
              ),
            ),
            StoreInformationStyles.fieldSpacer(isMobile),

            Transform.translate(
              offset: Offset(0, _slideAnimation.value * 0.7),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bio',
                      style: StoreInformationStyles.labelStyle,
                    ),
                    StoreInformationStyles.spaceSmall,
                    _buildBioField(),
                  ],
                ),
              ),
            ),
            StoreInformationStyles.fieldSpacer(isMobile),

            Transform.translate(
              offset: Offset(0, _slideAnimation.value * 0.6),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Website',
                      style: StoreInformationStyles.labelStyle,
                    ),
                    StoreInformationStyles.spaceSmall,
                    _buildWebsiteField(),
                  ],
                ),
              ),
            ),
            SizedBox(height: isMobile ? 12 : 10),

            Transform.translate(
              offset: Offset(0, _slideAnimation.value * 0.5),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instagram Handle',
                      style: StoreInformationStyles.labelStyle,
                    ),
                    const SizedBox(height: 6),
                    _buildInstagramField(),
                  ],
                ),
              ),
            ),
            StoreInformationStyles.footerSpacer(isMobile),

            Transform.translate(
              offset: Offset(0, _slideAnimation.value * 0.2),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildSubmitButton(),
              ),
            ),
            StoreInformationStyles.spaceStandard,
          ],
        );
      },
    );
  }

  Widget _buildStoreNameField() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Focus(
            onKeyEvent: (node, event) => _handleKeyEvent(node, event, null, _bioFocusNode),
            child: TextField(
              controller: _storeNameController,
              focusNode: _storeNameFocusNode,
              keyboardType: TextInputType.text,
              style: const TextStyle(fontSize: 14),
              onChanged: (_) {
                if (_storeNameError != null) {
                  setState(() {
                    _storeNameError = null;
                  });
                }
              },
              decoration: StoreInformationStyles.inputDecoration(
                hintText: 'FitAura Store',
                icon: Icons.store_outlined,
                isError: _storeNameError != null,
              ),
            ),
          ),
        ),
        if (_storeNameError != null)
          Positioned(
            right: 0,
            top: -8,
            child: _buildErrorTooltip(_storeNameError!),
          ),
      ],
    );
  }

  Widget _buildLogoImagePicker() {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: _pickLogoImage,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: StoreInformationStyles.logoPlaceholderDecoration(_logoError != null),
                  child: _logoPath == null && _webImageBytes == null
                      ? Icon(Icons.store, size: 60, color: StoreInformationStyles.placeholderIconColor)
                      : ClipOval(
                          child: kIsWeb
                              ? (_webImageBytes != null
                                  ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                                  : Icon(Icons.store, size: 60, color: StoreInformationStyles.placeholderIconColor))
                              : (_logoPath != null
                                  ? Image.file(File(_logoPath!), fit: BoxFit.cover)
                                  : Icon(Icons.store, size: 60, color: StoreInformationStyles.placeholderIconColor)),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: StoreInformationStyles.editIconDecoration,
                    child: const Icon(
                      Icons.edit,
                      color: StoreInformationStyles.whiteColor,
                      size: StoreInformationStyles.iconSizeMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_logoError != null)
            Positioned(
              right: -100,
              top: 0,
              child: _buildErrorTooltip(_logoError!),
            ),
        ],
      ),
    );
  }

  Widget _buildBioField() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: StoreInformationStyles.fieldAnimationDuration,
          curve: StoreInformationStyles.animationCurve,
          child: Focus(
            onKeyEvent: (node, event) => _handleKeyEvent(node, event, _storeNameFocusNode, _websiteFocusNode),
            child: TextField(
              controller: _bioController,
              focusNode: _bioFocusNode,
              keyboardType: TextInputType.multiline,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              onChanged: (_) {
                if (_bioError != null) {
                  setState(() {
                    _bioError = null;
                  });
                }
              },
              decoration: StoreInformationStyles.inputDecoration(
                hintText: 'We sell premium clothes...',
                icon: Icons.description_outlined,
                isError: _bioError != null,
              ),
            ),
          ),
        ),
        if (_bioError != null)
          Positioned(
            right: 0,
            top: -8,
            child: _buildErrorTooltip(_bioError!),
          ),
      ],
    );
  }

  Widget _buildWebsiteField() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Focus(
            onKeyEvent: (node, event) => _handleKeyEvent(node, event, _bioFocusNode, _instagramFocusNode),
            child: TextField(
              controller: _websiteController,
              focusNode: _websiteFocusNode,
              keyboardType: TextInputType.url,
              style: const TextStyle(fontSize: 14),
              onChanged: (_) {
                if (_websiteError != null) {
                  setState(() {
                    _websiteError = null;
                  });
                }
              },
              decoration: StoreInformationStyles.inputDecoration(
                hintText: 'https://example.com',
                icon: Icons.language_outlined,
                isError: _websiteError != null,
              ),
            ),
          ),
        ),
        if (_websiteError != null)
          Positioned(
            right: 0,
            top: -8,
            child: _buildErrorTooltip(_websiteError!),
          ),
      ],
    );
  }

  Widget _buildInstagramField() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Focus(
            onKeyEvent: (node, event) => _handleKeyEvent(node, event, _websiteFocusNode, null),
            child: TextField(
              controller: _instagramController,
              focusNode: _instagramFocusNode,
              keyboardType: TextInputType.text,
              style: const TextStyle(fontSize: 14),
              onChanged: (_) {
                if (_instagramError != null) {
                  setState(() {
                    _instagramError = null;
                  });
                }
              },
              decoration: StoreInformationStyles.inputDecoration(
                hintText: '@storename',
                icon: Icons.camera_alt_outlined,
                isError: _instagramError != null,
              ),
            ),
          ),
        ),
        if (_instagramError != null)
          Positioned(
            right: 0,
            top: -8,
            child: _buildErrorTooltip(_instagramError!),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: StoreInformationStyles.fieldAnimationDuration,
      curve: StoreInformationStyles.animationCurve,
      height: StoreInformationStyles.submitButtonHeight,
      transform: Matrix4.identity()..scale(_isButtonPressed ? StoreInformationStyles.buttonScalePressed : StoreInformationStyles.buttonScaleNormal),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: StoreInformationStyles.submitButtonStyle(_isButtonPressed, _isLoading),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(StoreInformationStyles.whiteColor),
                ),
              )
            : const Text(
                'Submit',
                style: StoreInformationStyles.buttonTextStyle,
              ),
      ),
    );
  }
}
