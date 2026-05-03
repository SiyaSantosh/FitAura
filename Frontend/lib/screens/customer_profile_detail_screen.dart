import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'sign_in_screen.dart';
import '../services/api_service.dart';
import '../styles/profile_styles.dart';

class CustomerProfileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CustomerProfileDetailScreen({super.key, required this.userData});

  @override
  State<CustomerProfileDetailScreen> createState() => _CustomerProfileDetailScreenState();
}

class _CustomerProfileDetailScreenState extends State<CustomerProfileDetailScreen> {
  late Map<String, dynamic> _userData;
  bool _isLoading = false;
  int _cartCount = 0;
  int _orderCount = 0;
  int _wishlistCount = 0;
  final ImagePicker _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? _nameError;
  String? _phoneError;
  String? _addressError;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _userData = Map.from(widget.userData);
    _loadStats();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final result = await ApiService.getUserById(_userData['user_id']);
      if (result['success'] && result['data'] != null) {
        if (mounted) {
          setState(() {
            _userData = result['data'];
            _nameController.text = _userData['name'] ?? '';
            _phoneController.text = _userData['contact_number'] ?? '';
            _addressController.text = _userData['address'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  bool _validateName(String value) {
    if (value.trim().isEmpty) {
      _nameError = 'Name is required';
      return false;
    }
    _nameError = null;
    return true;
  }

  bool _validatePhone(String value) {
    if (value.trim().isEmpty) {
      _phoneError = 'Phone number is required';
      return false;
    }
    if (value.trim().length < 10) {
      _phoneError = 'Invalid phone number';
      return false;
    }
    _phoneError = null;
    return true;
  }

  bool _validateAddress(String value) {
    if (value.trim().isEmpty) {
      _addressError = 'Address is required';
      return false;
    }
    _addressError = null;
    return true;
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final cartRes = await ApiService.getCartItems(_userData['user_id']);
      if (cartRes['success']) {
        final List items = cartRes['data'] ?? [];
        if (mounted) setState(() => _cartCount = items.length);
      }
      
      final orderRes = await ApiService.getCustomerOrders(_userData['user_id']);
      if (orderRes['success']) {
        final List orders = orderRes['data'] ?? [];
        if (mounted) setState(() => _orderCount = orders.length);
      }
      
      if (mounted) {
        setState(() {
          _wishlistCount = 0; 
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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
        setState(() => _isLoading = true);
        
        final bytes = await image.readAsBytes();
        final extension = image.path.split('.').last.toLowerCase();
        final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
        final profilePicData = 'data:$mimeType;base64,${base64Encode(bytes)}';

        final result = await ApiService.updateProfile(
          userId: _userData['user_id'],
          profilePicture: profilePicData,
        );

        if (result['success']) {
          await _loadUserData();
        } else {
          _showSnackBar(result['message'] ?? 'Failed to update profile picture', Colors.red);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showSnackBar('Failed to pick image', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: ProfileStyles.whiteColor,
      appBar: AppBar(
        backgroundColor: ProfileStyles.whiteColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ProfileStyles.darkTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile Details',
          style: TextStyle(color: ProfileStyles.darkTextColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(isMobile),
                const SizedBox(height: 24),
                _buildStats(isMobile),
                const SizedBox(height: 24),
                _buildInfoSection(isMobile),
                const SizedBox(height: 24),
                _buildDangerZone(isMobile),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(bool isMobile) {
    final String name = _userData['name'] ?? _userData['full_name'] ?? 'User';
    final String? profilePicture = _userData['profile_picture'];

    return Container(
      height: isMobile ? 180 : 240,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ProfileStyles.primaryColor,
            ProfileStyles.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: isMobile ? 80 : 120,
                      height: isMobile ? 80 : 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                      ),
                      child: ClipOval(
                        child: _buildProfileImage(profilePicture),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _pickImage,
                        child: Container(
                          height: 32,
                          width: 32,
                          decoration: ProfileStyles.editIconDecoration,
                          child: _isLoading 
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.edit_outlined, color: ProfileStyles.whiteColor, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: isMobile ? 22 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'CUSTOMER',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
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
    );
  }

  Widget _buildStats(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: ProfileStyles.whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProfileStyles.borderColor),
      ),
      child: Row(
        children: [
          _buildStatItem('Orders', _orderCount.toString(), Icons.shopping_basket_outlined),
          _buildDivider(),
          _buildStatItem('Cart', _cartCount.toString(), Icons.shopping_cart_outlined),
          _buildDivider(),
          _buildStatItem('Saved', _wishlistCount.toString(), Icons.favorite_border),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: ProfileStyles.primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ProfileStyles.darkTextColor),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: ProfileStyles.lightGrayColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: ProfileStyles.borderColor);
  }

  Widget _buildInfoSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ProfileStyles.whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProfileStyles.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin_outlined, color: ProfileStyles.primaryColor, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ProfileStyles.darkTextColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: _showChangePasswordDialog,
                icon: const Icon(Icons.vpn_key_outlined, size: 20, color: ProfileStyles.primaryColor),
                tooltip: 'Change Password',
              ),
              IconButton(
                onPressed: _showEditDialog,
                icon: const Icon(Icons.edit_outlined, size: 20, color: ProfileStyles.primaryColor),
                tooltip: 'Edit Profile',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoTile('Full Name', _userData['name'] ?? 'Not set', Icons.badge_outlined),
          _buildInfoTile('Email Address', _userData['email'] ?? 'Not set', Icons.email_outlined),
          _buildInfoTile('Phone Number', _userData['contact_number'] ?? 'Not set', Icons.phone_outlined),
          _buildInfoTile('Address', _userData['address'] ?? 'Not set', Icons.location_on_outlined),
          _buildInfoTile('Gender', _userData['gender'] ?? 'Not set', Icons.person_outline),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: ProfileStyles.lightGrayColor, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: ProfileStyles.lightGrayColor)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ProfileStyles.darkTextColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 22),
              const SizedBox(width: 8),
              Text(
                'Danger Zone',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade400),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Deactivate account permanently',
                  style: TextStyle(fontSize: 14, color: ProfileStyles.darkTextColor),
                ),
              ),
              TextButton(
                onPressed: _showDeactivateDialog,
                child: Text('Deactivate', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    bool isPasswordVerified = false;
    bool isLoading = false;
    
    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: ProfileStyles.whiteColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Center(child: Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isPasswordVerified) ...[
                  _buildEditTextField(
                    _currentPasswordController, 
                    'Current Password', 
                    Icons.lock_outline,
                    errorText: _currentPasswordError,
                    obscureText: true,
                  ),
                ] else ...[
                  _buildEditTextField(
                    _newPasswordController, 
                    'New Password', 
                    Icons.lock_reset_outlined,
                    errorText: _newPasswordError,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  _buildEditTextField(
                    _confirmPasswordController, 
                    'Confirm New Password', 
                    Icons.lock_clock_outlined,
                    errorText: _confirmPasswordError,
                    obscureText: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: ProfileStyles.lightGrayColor)),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (!isPasswordVerified) {
                  
                  if (_currentPasswordController.text.isEmpty) {
                    setDialogState(() => _currentPasswordError = 'Current password is required');
                    return;
                  }
                  
                  setDialogState(() {
                    _currentPasswordError = null;
                    isLoading = true;
                  });

                  final result = await ApiService.verifyPassword(
                    userId: _userData['user_id'],
                    currentPassword: _currentPasswordController.text,
                  );

                  setDialogState(() { isLoading = false; });

                  if (result['success']) {
                    setDialogState(() => isPasswordVerified = true);
                  } else {
                    setDialogState(() => _currentPasswordError = result['message'] ?? 'Incorrect password');
                  }
                } else {
                  
                  bool isValid = true;
                  if (_newPasswordController.text.isEmpty) {
                    _newPasswordError = 'New password is required';
                    isValid = false;
                  } else if (_newPasswordController.text.length < 8) {
                    _newPasswordError = 'Min 8 characters';
                    isValid = false;
                  } else if (!_newPasswordController.text.contains(RegExp(r'[a-zA-Z]')) || !_newPasswordController.text.contains(RegExp(r'[0-9]'))) {
                    _newPasswordError = 'Must contain 1 alphabet and 1 number';
                    isValid = false;
                  } else {
                    _newPasswordError = null;
                  }
                  
                  if (_confirmPasswordController.text != _newPasswordController.text) {
                    _confirmPasswordError = 'Passwords do not match';
                    isValid = false;
                  } else {
                    _confirmPasswordError = null;
                  }

                  setDialogState(() {});
                  if (!isValid) return;

                  setDialogState(() => isLoading = true);

                  final result = await ApiService.changePassword(
                    userId: _userData['user_id'],
                    currentPassword: _currentPasswordController.text,
                    newPassword: _newPasswordController.text,
                  );

                  setDialogState(() => isLoading = false);

                  if (result['success']) {
                    if (mounted) Navigator.pop(context);
                  } else {
                    _showSnackBar(result['message'] ?? 'Failed to change password', Colors.red);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ProfileStyles.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isPasswordVerified ? 'Save Changes' : 'Next', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    setState(() {
      _nameError = null;
      _phoneError = null;
      _addressError = null;
      _nameController.text = _userData['name'] ?? '';
      _phoneController.text = _userData['contact_number'] ?? '';
      _addressController.text = _userData['address'] ?? '';
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: ProfileStyles.whiteColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Center(child: Text('Edit Personal Details', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditTextField(
                  _nameController, 
                  'Full Name', 
                  Icons.person,
                  errorText: _nameError,
                  onChanged: (v) => setDialogState(() => _validateName(v)),
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  _phoneController, 
                  'Contact Number', 
                  Icons.phone,
                  errorText: _phoneError,
                  onChanged: (v) => setDialogState(() => _validatePhone(v)),
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  _addressController, 
                  'Home Address', 
                  Icons.home_work, 
                  maxLines: 2,
                  errorText: _addressError,
                  onChanged: (v) => setDialogState(() => _validateAddress(v)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: ProfileStyles.lightGrayColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                final isValid = _validateName(_nameController.text) &
                                _validatePhone(_phoneController.text) &
                                _validateAddress(_addressController.text);
                
                if (!isValid) {
                  setDialogState(() {});
                  return;
                }

                final result = await ApiService.updateProfile(
                  userId: _userData['user_id'],
                  name: _nameController.text.trim(),
                  contactNumber: _phoneController.text.trim(),
                  address: _addressController.text.trim(),
                  gender: _userData['gender'],
                  profilePicture: _userData['profile_picture'],
                );

                if (result['success']) {
                  if (mounted) Navigator.pop(context);
                  await _loadUserData();
                } else {
                  _showSnackBar('Failed to update profile', Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ProfileStyles.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeactivateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ProfileStyles.whiteColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(child: Text('Deactivate Account', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        content: const Text('Are you sure you want to deactivate your account? Any pending orders will be cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: ProfileStyles.lightGrayColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showSnackBar('Deactivating account...', Colors.orange);
              final result = await ApiService.deactivateCustomerProfile(_userData['user_id']);
              if (result['success']) {
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const SignInScreen()),
                    (route) => false,
                  );
                }
              } else {
                _showSnackBar(result['message'] ?? 'Failed to deactivate account', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Deactivate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, String? errorText, Function(String)? onChanged, bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          obscureText: obscureText,
          style: const TextStyle(fontSize: 15),
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: ProfileStyles.darkTextColor.withOpacity(0.7)),
            prefixIcon: Icon(icon, color: ProfileStyles.primaryColor, size: 20),
            filled: true,
            fillColor: ProfileStyles.beigeBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: errorText != null ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: errorText != null ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: errorText != null ? const BorderSide(color: Colors.red, width: 2.0) : const BorderSide(color: ProfileStyles.primaryColor, width: 2.0),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildProfileImage(String? imageSource) {
    if (imageSource == null || imageSource.isEmpty) {
      return Container(
        color: ProfileStyles.whiteColor,
        child: const Icon(Icons.person, color: ProfileStyles.primaryColor, size: 40),
      );
    }
    try {
      final String cleanBase64 = imageSource.contains(',') ? imageSource.split(',').last : imageSource;
      return Image.memory(base64Decode(cleanBase64), fit: BoxFit.cover);
    } catch (e) {
      return const Icon(Icons.person, color: ProfileStyles.primaryColor, size: 40);
    }
  }
}
