import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api_service.dart';
import 'sign_in_screen.dart';
import '../widgets/custom_snackbar.dart';
import '../styles/admin_dashboard_styles.dart';
import '../services/socket_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String adminName;
  final int? userId;

  const AdminDashboardScreen({super.key, required this.adminName, this.userId});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with TickerProviderStateMixin {

  int _selectedTab = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _allProducts = []; 
  List<Map<String, dynamic>> _notifications = [];
  Map<String, dynamic>? _userData;
  final ImagePicker _picker = ImagePicker();

  bool _isSidebarHovered = true;
  bool _isAccountsExpanded = false;
  bool _isProductsExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _userRoleFilter = 'all'; 
  
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editContactController = TextEditingController();
  String? _editNameError;
  String? _editContactError;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  static const int _notificationsTabIndex = 8;
  static const int _profileTabIndex = 9;

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard, 'label': 'Dashboard', 'index': 0, 'isParent': false},
    {
      'icon': Icons.account_circle_outlined, 
      'activeIcon': Icons.account_circle, 
      'label': 'Accounts', 
      'index': -1, 
      'isParent': true,
      'subItems': [
        {'icon': Icons.pending_actions_outlined, 'activeIcon': Icons.pending_actions, 'label': 'Account Requests', 'index': 1},
        {'icon': Icons.verified_user_outlined, 'activeIcon': Icons.verified_user, 'label': 'Verified Users', 'index': 2},
        {'icon': Icons.cancel_outlined, 'activeIcon': Icons.cancel, 'label': 'Rejected Users', 'index': 3},
        {'icon': Icons.block_outlined, 'activeIcon': Icons.block, 'label': 'Blocked Users', 'index': 4},
        {'icon': Icons.no_accounts_outlined, 'activeIcon': Icons.no_accounts, 'label': 'Deactivated Accounts', 'index': 10},
      ]
    },
    {
      'icon': Icons.shopping_bag_outlined, 
      'activeIcon': Icons.shopping_bag, 
      'label': 'Products', 
      'index': -2, 
      'isParent': true,
      'subItems': [
        {'icon': Icons.pending_actions_outlined, 'activeIcon': Icons.pending_actions, 'label': 'Product Requests', 'index': 5},
        {'icon': Icons.check_circle_outline, 'activeIcon': Icons.check_circle, 'label': 'Approved Products', 'index': 6},
        {'icon': Icons.cancel_outlined, 'activeIcon': Icons.cancel, 'label': 'Rejected Products', 'index': 7},
      ]
    },
  ];

  final List<Map<String, dynamic>> _bottomNavItems = [
    {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard, 'label': 'Home', 'index': 0},
    {'icon': Icons.account_circle_outlined, 'activeIcon': Icons.account_circle, 'label': 'Accounts', 'index': 1},
    {'icon': Icons.shopping_bag_outlined, 'activeIcon': Icons.shopping_bag, 'label': 'Products', 'index': 5},
    {'icon': Icons.notifications_outlined, 'activeIcon': Icons.notifications, 'label': 'Alerts', 'index': 8},
  ];

  late AnimationController _logoutDialogAnimationController;
  late Animation<double> _logoutDialogScaleAnimation;
  late Animation<double> _logoutDialogFadeAnimation;
  
  late AnimationController _detailsDialogAnimationController;
  late Animation<double> _detailsDialogScaleAnimation;
  late Animation<double> _detailsDialogFadeAnimation;

  @override
  void initState() {
    super.initState();
    _logoutDialogAnimationController = AnimationController(
      duration: AdminDashboardStyles.defaultAnimationDuration,
      vsync: this,
    );

    _logoutDialogScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoutDialogAnimationController,
        curve: AdminDashboardStyles.dialogScaleCurve,
      ),
    );

    _logoutDialogFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoutDialogAnimationController,
        curve: AdminDashboardStyles.defaultAnimationCurve,
      ),
    );

    _detailsDialogAnimationController = AnimationController(
      duration: AdminDashboardStyles.defaultAnimationDuration,
      vsync: this,
    );

    _detailsDialogScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _detailsDialogAnimationController,
        curve: AdminDashboardStyles.dialogScaleCurve,
      ),
    );

    _detailsDialogFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _detailsDialogAnimationController,
        curve: AdminDashboardStyles.defaultAnimationCurve,
      ),
    );

    _loadData();
    _setupSocketListener();
  }

  void _setupSocketListener() {
    
  }

  @override
  void dispose() {
    _logoutDialogAnimationController.dispose();
    _detailsDialogAnimationController.dispose();
    _searchController.dispose();
    _editNameController.dispose();
    _editContactController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    await _loadUserData();
    
    final usersResult = await ApiService.getAllUsers();
    if (usersResult['success']) {
      final responseData = usersResult['data'];
      List<Map<String, dynamic>> allUsers = [];
      
      if (responseData is List) {
        allUsers = responseData.map((user) {
          if (user is Map<String, dynamic>) {
            return user;
          } else if (user is Map) {
            return Map<String, dynamic>.from(user);
          }
          return <String, dynamic>{};
        }).where((user) => user.isNotEmpty).toList();
      }
      
      setState(() {
        _allUsers = allUsers;
      });
    } else {
      
      final errorMessage = usersResult['message'] ?? 'Failed to load users';
      if (mounted) {
        _showSnackBar(errorMessage, AdminDashboardStyles.errorColor);
      }
    }

    final productsResult = await ApiService.getAllProducts(isAdmin: true);
    if (productsResult['success']) {
      final responseData = productsResult['data'];
      List<Map<String, dynamic>> allProducts = [];
      
      if (responseData is List) {
        allProducts = responseData.map((product) {
          if (product is Map<String, dynamic>) {
            return product;
          } else if (product is Map) {
            return Map<String, dynamic>.from(product);
          }
          return <String, dynamic>{};
        }).where((product) => product.isNotEmpty).toList();
      }
      
      setState(() {
        _allProducts = allProducts;
      });
    } else {
      
      final errorMessage = productsResult['message'] ?? 'Failed to load products';
      if (mounted) {
        _showSnackBar(errorMessage, AdminDashboardStyles.errorColor);
      }
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    final result = await ApiService.getAdminNotifications();
    if (result['success']) {
      final responseData = result['data'];
      List<Map<String, dynamic>> notifications = [];

      if (responseData is List) {
        notifications = responseData.map((notification) {
          if (notification is Map<String, dynamic>) {
            return notification;
          } else if (notification is Map) {
            return Map<String, dynamic>.from(notification);
          }
          return <String, dynamic>{};
        }).where((notification) => notification.isNotEmpty).toList();
      }

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } else {
      final errorMessage = result['message'] ?? 'Failed to load notifications';
      if (mounted) {
        _showSnackBar(errorMessage, AdminDashboardStyles.errorColor);
      }
      setState(() => _isLoading = false);
    }
  }

  bool _validateName(String value) {
    if (value.trim().isEmpty) {
      _editNameError = 'Name is required';
      return false;
    }
    if (value.trim().length < 2) {
      _editNameError = 'Min 2 characters';
      return false;
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      _editNameError = 'Letters only';
      return false;
    }
    _editNameError = null;
    return true;
  }

  bool _validatePhone(String value) {
    if (value.trim().isEmpty) {
      _editContactError = 'Phone is required';
      return false;
    }
    if (value.trim().length != 11 || !RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
      _editContactError = 'Must be 11 digits';
      return false;
    }
    _editContactError = null;
    return true;
  }

  void _showProfileEditDialog({
    required String title,
    required Widget Function(BuildContext, StateSetter) contentBuilder,
    required Future<void> Function(StateSetter) onSave,
  }) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AdminDashboardStyles.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Center(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          content: SingleChildScrollView(child: contentBuilder(context, setDialogState)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AdminDashboardStyles.secondaryTextColor)),
            ),
            ElevatedButton(
              onPressed: () => onSave(setDialogState),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminDashboardStyles.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
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
            labelStyle: TextStyle(color: AdminDashboardStyles.textColor.withOpacity(0.7)),
            prefixIcon: Icon(icon, color: AdminDashboardStyles.primaryColor, size: 20),
            filled: true,
            fillColor: AdminDashboardStyles.backgroundColor,
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
              borderSide: errorText != null ? const BorderSide(color: Colors.red, width: 2.0) : const BorderSide(color: AdminDashboardStyles.primaryColor, width: 2.0),
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

  void _showEditAdminDialog() {
    if (_userData == null) {
      _showSnackBar('Admin information not loaded', AdminDashboardStyles.warningColor);
      return;
    }

    _editNameController.text = _userData?['name']?.toString() ?? '';
    _editContactController.text = _userData?['contact_number']?.toString() ?? '';

    setState(() {
      _editNameError = null;
      _editContactError = null;
    });

    _showProfileEditDialog(
      title: 'Edit Admin Details',
      contentBuilder: (context, setDialogState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEditTextField(
            _editNameController, 
            'Full Name', 
            Icons.person,
            errorText: _editNameError,
            onChanged: (v) => setDialogState(() => _validateName(v)),
          ),
          const SizedBox(height: 16),
          _buildEditTextField(
            _editContactController, 
            'Contact Number', 
            Icons.phone,
            errorText: _editContactError,
            onChanged: (v) => setDialogState(() => _validatePhone(v)),
          ),
        ],
      ),
      onSave: (setDialogState) async {
        if (widget.userId == null) return;

        final isValid = _validateName(_editNameController.text) &
                        _validatePhone(_editContactController.text);
        
        if (!isValid) {
          setDialogState(() {});
          return;
        }

        final result = await ApiService.updateProfile(
          userId: widget.userId!,
          name: _editNameController.text.trim(),
          contactNumber: _editContactController.text.trim(),
        );

        if (result['success']) {
          if (mounted) Navigator.pop(context);
          await _loadUserData();
        } else {
          _showSnackBar(result['message'] ?? 'Failed to update profile information', Colors.red);
        }
      },
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
          backgroundColor: AdminDashboardStyles.surfaceColor,
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
              child: const Text('Cancel', style: TextStyle(color: AdminDashboardStyles.secondaryTextColor)),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (widget.userId == null) return;
                
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
                    userId: widget.userId!,
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
                    userId: widget.userId!,
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
                backgroundColor: AdminDashboardStyles.primaryColor,
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

  void _onTabChanged(int index) {
    
    _searchController.clear();
    
    if (index == _notificationsTabIndex) {
      setState(() {
        _selectedTab = index;
      });
      _loadNotifications();
      return;
    }

    if (index == _profileTabIndex) {
      setState(() {
        _selectedTab = index;
      });
      _loadUserData();
      return;
    }
    
    setState(() {
      _selectedTab = index;
      _userRoleFilter = 'all';
    });
    _loadData();
  }

  Future<void> _loadUserData() async {
    if (widget.userId == null) return;
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getUserById(widget.userId!);
      if (result['success'] && result['data'] != null) {
        setState(() {
          _userData = result['data'] as Map<String, dynamic>;
        });
      }
    } catch (e) {
      debugPrint('Error loading admin profile data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    if (widget.userId == null) return;
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
          userId: widget.userId!,
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

  Widget _buildProfileImage(String? imageSource, double size, bool isMobile) {
    if (imageSource == null || imageSource.isEmpty) {
      return Center(
        child: Text(
          (_userData?['name'] ?? widget.adminName).isNotEmpty ? (_userData?['name'] ?? widget.adminName)[0].toUpperCase() : 'A',
          style: TextStyle(
            fontSize: isMobile ? 32 : 48,
            fontWeight: FontWeight.w900,
            color: AdminDashboardStyles.primaryColor,
          ),
        ),
      );
    }

    if (imageSource.startsWith('assets/')) {
      return Image.asset(imageSource, fit: BoxFit.cover);
    }

    if (imageSource.startsWith('http')) {
      return Image.network(
        imageSource,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(
            (_userData?['name'] ?? widget.adminName).isNotEmpty ? (_userData?['name'] ?? widget.adminName)[0].toUpperCase() : 'A',
            style: TextStyle(
              fontSize: isMobile ? 32 : 48,
              fontWeight: FontWeight.w900,
              color: AdminDashboardStyles.primaryColor,
            ),
          ),
        ),
      );
    }

    try {
      final String cleanBase64 = imageSource.contains(',') ? imageSource.split(',').last : imageSource;
      return Image.memory(
        base64Decode(cleanBase64),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(
            (_userData?['name'] ?? widget.adminName).isNotEmpty ? (_userData?['name'] ?? widget.adminName)[0].toUpperCase() : 'A',
            style: TextStyle(
              fontSize: isMobile ? 32 : 48,
              fontWeight: FontWeight.w900,
              color: AdminDashboardStyles.primaryColor,
            ),
          ),
        ),
      );
    } catch (e) {
      return Center(
        child: Text(
          (_userData?['name'] ?? widget.adminName).isNotEmpty ? (_userData?['name'] ?? widget.adminName)[0].toUpperCase() : 'A',
          style: TextStyle(
            fontSize: isMobile ? 32 : 48,
            fontWeight: FontWeight.w900,
            color: AdminDashboardStyles.primaryColor,
          ),
        ),
      );
    }
  }

  Future<void> _handleApprove(Map<String, dynamic> user) async {
    final userId = user['user_id'] ?? user['id'] ?? user['userId'];
    if (userId == null) {
      _showSnackBar('User ID not found', AdminDashboardStyles.errorColor);
      return;
    }

    final userIdInt = userId is int ? userId : int.tryParse(userId.toString());
    if (userIdInt == null) {
      _showSnackBar('Invalid user ID', AdminDashboardStyles.errorColor);
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.updateUserAccess(
      userId: userIdInt,
      hasAccess: 1,
    );

    setState(() => _isLoading = false);

    if (result['success']) {

      _loadData(); 
    } else {
      final errorMessage = result['message'] ?? 'Failed to approve user';
      _showSnackBar(errorMessage, AdminDashboardStyles.errorColor);
    }
  }

  Future<void> _handleReject(Map<String, dynamic> user) async {
    final userId = user['user_id'] ?? user['id'] ?? user['userId'];
    if (userId == null) {
      _showSnackBar('User ID not found', AdminDashboardStyles.errorColor);
      return;
    }

    final userIdInt = userId is int ? userId : int.tryParse(userId.toString());
    if (userIdInt == null) {
      _showSnackBar('Invalid user ID', AdminDashboardStyles.errorColor);
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.updateUserAccess(
      userId: userIdInt,
      hasAccess: -1,
    );

    setState(() => _isLoading = false);

    if (result['success']) {

      _loadData(); 
    } else {
      final errorMessage = result['message'] ?? 'Failed to reject user';
      _showSnackBar(errorMessage, AdminDashboardStyles.errorColor);
    }
  }

  Future<void> _handleBlock(Map<String, dynamic> user) async {
    final userId = user['user_id'] ?? user['id'] ?? user['userId'];
    if (userId == null) {
      _showSnackBar('User ID not found', AdminDashboardStyles.errorColor);
      return;
    }

    final userIdInt = userId is int ? userId : int.tryParse(userId.toString());
    if (userIdInt == null) {
      _showSnackBar('Invalid user ID', AdminDashboardStyles.errorColor);
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.updateUserAccess(
      userId: userIdInt,
      hasAccess: -2,
    );

    setState(() => _isLoading = false);

    if (result['success']) {

      _loadData(); 
    } else {
      final errorMessage = result['message'] ?? 'Failed to block user';
      _showSnackBar(errorMessage, AdminDashboardStyles.errorColor);
    }
  }

  Future<void> _handleUnblock(Map<String, dynamic> user) async {
    final userId = user['user_id'] ?? user['id'] ?? user['userId'];
    if (userId == null) {
      _showSnackBar('User ID not found', AdminDashboardStyles.errorColor);
      return;
    }

    final userIdInt = userId is int ? userId : int.tryParse(userId.toString());
    if (userIdInt == null) {
      _showSnackBar('Invalid user ID', AdminDashboardStyles.errorColor);
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.updateUserAccess(
      userId: userIdInt,
      hasAccess: 1,
    );

    setState(() => _isLoading = false);

    if (result['success']) {

      _loadData(); 
    } else {
      final errorMessage = result['message'] ?? 'Failed to unblock user';
      _showSnackBar(errorMessage, AdminDashboardStyles.errorColor);
    }
  }

  List<Map<String, dynamic>> _getFilteredUsers() {
    List<Map<String, dynamic>> filteredList;
    switch (_selectedTab) {
      case 0: 
        filteredList = _allUsers;
        break;
      case 1: 
        filteredList = _allUsers.where((user) {
          final hasAccess = user['has_access'];
          final isDeactivated = user['deactivated'] == 1 || user['deactivated'] == '1' || user['deactivated'] == true;
          if (isDeactivated) return false;
          if (hasAccess is int) {
            return hasAccess == 0;
          } else if (hasAccess is String) {
            return int.tryParse(hasAccess) == 0;
          }
          return false;
        }).toList();
        break;
      case 2: 
        filteredList = _allUsers.where((user) {
          final hasAccess = user['has_access'];
          final isDeactivated = user['deactivated'] == 1 || user['deactivated'] == '1' || user['deactivated'] == true;
          if (isDeactivated) return false;
          if (hasAccess is int) {
            return hasAccess == 1;
          } else if (hasAccess is String) {
            return int.tryParse(hasAccess) == 1;
          }
          return false;
        }).toList();
        break;
      case 3: 
        filteredList = _allUsers.where((user) {
          final hasAccess = user['has_access'];
          final isDeactivated = user['deactivated'] == 1 || user['deactivated'] == '1' || user['deactivated'] == true;
          if (isDeactivated) return false;
          if (hasAccess is int) {
            return hasAccess == -1;
          } else if (hasAccess is String) {
            return int.tryParse(hasAccess) == -1;
          }
          return false;
        }).toList();
        break;
      case 4: 
        filteredList = _allUsers.where((user) {
          final hasAccess = user['has_access'];
          final isDeactivated = user['deactivated'] == 1 || user['deactivated'] == '1' || user['deactivated'] == true;
          if (isDeactivated) return false;
          if (hasAccess is int) {
            return hasAccess == -2;
          } else if (hasAccess is String) {
            return int.tryParse(hasAccess) == -2;
          }
          return false;
        }).toList();
        break;
      case 10: 
        filteredList = _allUsers.where((user) {
          return user['deactivated'] == 1 || user['deactivated'] == '1' || user['deactivated'] == true;
        }).toList();
        break;
      default:
        filteredList = _allUsers;
      }

    if (_userRoleFilter != 'all') {
      filteredList = filteredList.where((user) {
        final role = (user['role'] ?? '').toString().toLowerCase();
        return role == _userRoleFilter;
      }).toList();
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filteredList = filteredList.where((user) {
        final name = (user['full_name'] ?? user['name'] ?? '').toString().toLowerCase();
        return name.contains(query);
      }).toList();
    }
    
    return filteredList;
  }

  Widget _buildRoleFilter() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildFilterChip('All', 'all'),
          AdminDashboardStyles.hSpaceSmall,
          _buildFilterChip('Sellers', 'seller'),
          AdminDashboardStyles.hSpaceSmall,
          _buildFilterChip('Customers', 'customer'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _userRoleFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _userRoleFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: AdminDashboardStyles.fastAnimationDuration,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: AdminDashboardStyles.filterChipDecoration(isSelected),
        child: Text(
          label,
          style: AdminDashboardStyles.filterChipTextStyle(isSelected),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredProducts() {
    List<Map<String, dynamic>> filteredList;
    switch (_selectedTab) {
      case 5: 
        filteredList = _allProducts.where((product) {
          final status = product['is_verified'];
          if (status == null) return true; 
          if (status is int) return status == 0;
          if (status is String) return status == 'pending' || status == '0';
          return false;
        }).toList();
        break;
      case 6: 
        filteredList = _allProducts.where((product) {
          final status = product['is_verified'];
          if (status is int) return status == 1;
          if (status is String) return status == '1' || status == 'verified';
          return false;
        }).toList();
        break;
      case 7: 
        filteredList = _allProducts.where((product) {
          final status = product['is_verified'];
          if (status is int) return status == -1;
          if (status is String) return status == '-1';
          return false;
        }).toList();
        break;
      default:
        filteredList = _allProducts;
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filteredList = filteredList.where((product) {
        final name = (product['product_name'] ?? product['name'] ?? '').toString().toLowerCase();
        return name.contains(query);
      }).toList();
    }
    
    return filteredList;
  }

  void _handleLogout() {
    _logoutDialogAnimationController.forward();
    showDialog(
      context: context,
      barrierColor: AdminDashboardStyles.dialogBarrierColor,
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
                  backgroundColor: AdminDashboardStyles.transparentColor,
                  elevation: 0,
                  insetPadding: AdminDashboardStyles.dialogInsetPadding(isMobile, MediaQuery.of(context).size.width),
                  child: Container(
                    constraints: AdminDashboardStyles.dialogConstraints(isMobile, MediaQuery.of(context).size.height),
                    decoration: AdminDashboardStyles.dialogDecoration,
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          
                          Text(
                            'Logout',
                            style: AdminDashboardStyles.dialogTitleStyle.copyWith(
                              fontSize: isMobile ? 24 : 28,
                            ),
                          ),
                          SizedBox(height: isMobile ? 8 : 12),
                          
                          Text(
                            'Are you sure you want to logout?',
                            textAlign: TextAlign.center,
                            style: AdminDashboardStyles.dialogSubtitleStyle.copyWith(
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                          SizedBox(height: isMobile ? 20 : 28),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    _logoutDialogAnimationController.reverse();
                                    Navigator.of(context).pop();
                                  },
                                  style: AdminDashboardStyles.outlinedButtonStyle(
                                      radius: 26, color: AdminDashboardStyles.secondaryTextColor.withOpacity(0.5)),
                                  child: Text(
                                    'Cancel',
                                    style: AdminDashboardStyles.buttonTextStyle.copyWith(
                                      color: AdminDashboardStyles.textColor,
                                      fontSize: isMobile ? 15 : 16,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: isMobile ? 12 : 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _logoutDialogAnimationController.reverse();
                                    Navigator.of(context).pop();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SignInScreen(),
                                      ),
                                    );
                                  },
                                  style: AdminDashboardStyles.primaryButtonStyle(radius: 26),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.logout, color: AdminDashboardStyles.surfaceColor, size: 18),
                                      AdminDashboardStyles.hSpaceSmall,
                                      Text(
                                        'Logout',
                                        style: AdminDashboardStyles.buttonTextStyle.copyWith(
                                          color: AdminDashboardStyles.surfaceColor,
                                          fontSize: isMobile ? 15 : 16,
                                          fontWeight: FontWeight.w700,
                                        ),
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

  void _showUserDetails(
    Map<String, dynamic> user, {
    String? buttonType,
    VoidCallback? onApprove,
    VoidCallback? onReject,
    VoidCallback? onBlock,
    VoidCallback? onUnblock,
  }) {
    _detailsDialogAnimationController.forward();
    showDialog(
      context: context,
      barrierColor: AdminDashboardStyles.dialogBarrierColor,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 768;
        
        return AnimatedBuilder(
          animation: _detailsDialogAnimationController,
          builder: (context, child) {
            return Opacity(
              opacity: _detailsDialogFadeAnimation.value,
              child: Transform.scale(
                scale: _detailsDialogScaleAnimation.value,
                child: Dialog(
                  backgroundColor: AdminDashboardStyles.transparentColor,
                  elevation: 0,
                  insetPadding: AdminDashboardStyles.dialogInsetPadding(isMobile, MediaQuery.of(context).size.width),
                  child: Container(
                    constraints: AdminDashboardStyles.dialogConstraints(isMobile, MediaQuery.of(context).size.height),
                    decoration: AdminDashboardStyles.detailDialogDecoration,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: AdminDashboardStyles.detailHeaderDecoration,
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: AdminDashboardStyles.detailImageContainerDecoration,
                              child: ClipOval(
                                child: _buildImageWidget(
                                  (user['profile_picture'] ?? 
                                   user['profile_pic'] ?? 
                                   user['image'] ?? 
                                   user['logo'] ?? 
                                   user['logo_url'] ?? 
                                   user['logo_path'] ?? '').toString(),
                                  errorWidget: Icon(
                                    user['role']?.toString().toLowerCase() == 'seller'
                                        ? Icons.store
                                        : Icons.person,
                                    color: AdminDashboardStyles.surfaceColor,
                                    size: 28,
                                  ),
                                ),
                              ),
                              ),
                              AdminDashboardStyles.hSpaceLarge,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['name']?.toString() ?? 'Unknown User',
                                      style: AdminDashboardStyles.detailNameStyle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    AdminDashboardStyles.vSpaceTiny,
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: AdminDashboardStyles.detailRoleTagBackground,
                                      child: Text(
                                        (user['role']?.toString().toUpperCase() ?? 'USER'),
                                        style: AdminDashboardStyles.detailRoleTagStyle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                
                                _buildSectionTitle('Personal Information', Icons.person_outline),
                                AdminDashboardStyles.vSpaceMedium,
                                Flex(
                                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                                  crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: isMobile ? 0 : 1,
                                      child: _buildDetailRow(
                                        Icons.email_outlined,
                                        'Email',
                                        user['email']?.toString() ?? 'Not provided',
                                      ),
                                    ),
                                    if (!isMobile) AdminDashboardStyles.hSpaceMedium,
                                    if (isMobile) AdminDashboardStyles.vSpaceMedium,
                                    Expanded(
                                      flex: isMobile ? 0 : 1,
                                      child: _buildDetailRow(
                                        Icons.phone_outlined,
                                        'Contact Number',
                                        user['contact_number']?.toString() ??
                                            user['contactNumber']?.toString() ??
                                            'Not provided',
                                      ),
                                    ),
                                  ],
                                ),
                                AdminDashboardStyles.vSpaceMedium,
                                Flex(
                                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                                  crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: isMobile ? 0 : 1,
                                      child: _buildDetailRow(
                                        Icons.badge_outlined,
                                        'CNIC',
                                        user['cnic']?.toString() ?? 'Not provided',
                                      ),
                                    ),
                                    if (!isMobile) AdminDashboardStyles.hSpaceMedium,
                                    if (isMobile) AdminDashboardStyles.vSpaceMedium,
                                    Expanded(
                                      flex: isMobile ? 0 : 1,
                                      child: _buildDetailRow(
                                        Icons.people_outline,
                                        'Gender',
                                        user['gender']?.toString() ?? 'Not provided',
                                      ),
                                    ),
                                  ],
                                ),
                                AdminDashboardStyles.vSpaceMedium,
                                _buildDetailRow(
                                  Icons.location_on_outlined,
                                  'Address',
                                  user['address']?.toString() ?? 'Not provided',
                                ),
                                AdminDashboardStyles.vSpaceMedium,
                                _buildDetailRow(
                                  Icons.tag_outlined,
                                  'User ID',
                                  user['id']?.toString() ??
                                      user['user_id']?.toString() ??
                                      user['userId']?.toString() ??
                                      'Not available',
                                ),
                                
                                if (user['role']?.toString().toLowerCase() == 'seller') ...[
                                  const SizedBox(height: 24),
                                  _buildSectionTitle('Store Information', Icons.store_outlined),
                                  AdminDashboardStyles.vSpaceMedium,
                                  FutureBuilder<Map<String, dynamic>>(
                                    future: _loadStoreInfo(user),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(
                                          child: Padding(
                                            padding: AdminDashboardStyles.screenPadding,
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      
                                      final storeInfo = snapshot.data;
                                      if (storeInfo == null || storeInfo.isEmpty) {
                                        return _buildDetailRow(
                                          Icons.info_outline,
                                          'Store Info',
                                          'No store information available',
                                        );
                                      }
                                      
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (storeInfo['logo'] != null || 
                                              storeInfo['logo_url'] != null || 
                                              storeInfo['logo_path'] != null) ...[
                                            _buildImageDetailRow(
                                              Icons.image_outlined,
                                              'Store Logo',
                                              storeInfo['logo']?.toString() ?? 
                                              storeInfo['logo_url']?.toString() ?? 
                                              storeInfo['logo_path']?.toString() ?? '',
                                            ),
                                            AdminDashboardStyles.vSpaceMedium,
                                          ],
                                          if (storeInfo['store_name'] != null)
                                            _buildDetailRow(
                                              Icons.store_outlined,
                                              'Store Name',
                                              storeInfo['store_name'].toString(),
                                            ),
                                          if (storeInfo['store_name'] != null)
                                            AdminDashboardStyles.vSpaceMedium,
                                          Flex(
                                            direction: isMobile ? Axis.vertical : Axis.horizontal,
                                            crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
                                            children: [
                                              if (storeInfo['bio'] != null)
                                                Expanded(
                                                  flex: isMobile ? 0 : 1,
                                                  child: _buildDetailRow(
                                                    Icons.description_outlined,
                                                    'Bio',
                                                    storeInfo['bio'].toString(),
                                                    isMultiline: true,
                                                  ),
                                                ),
                                              if (storeInfo['bio'] != null && !isMobile && storeInfo['website'] != null) AdminDashboardStyles.hSpaceMedium,
                                              if (storeInfo['bio'] != null && isMobile && storeInfo['website'] != null) AdminDashboardStyles.vSpaceMedium,
                                              if (storeInfo['website'] != null)
                                                Expanded(
                                                  flex: isMobile ? 0 : 1,
                                                  child: _buildDetailRow(
                                                    Icons.language_outlined,
                                                    'Website',
                                                    storeInfo['website'].toString(),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if (storeInfo['bio'] != null || storeInfo['website'] != null)
                                            AdminDashboardStyles.vSpaceMedium,
                                          if (storeInfo['instagram'] != null)
                                            _buildDetailRow(
                                              Icons.camera_alt_outlined,
                                              'Instagram',
                                              storeInfo['instagram'].toString(),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                                
                                const SizedBox(height: 24),
                                _buildSectionTitle('Account Status', Icons.info_outline),
                                AdminDashboardStyles.vSpaceMedium,
                                Flex(
                                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                                  crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: isMobile ? 0 : 1,
                                      child: _buildStatusChip(
                                        'Status',
                                        _getStatusFromHasAccess(user['has_access']),
                                      ),
                                    ),
                                    if (!isMobile) AdminDashboardStyles.hSpaceMedium,
                                    if (isMobile) AdminDashboardStyles.vSpaceMedium,
                                    Expanded(
                                      flex: isMobile ? 0 : 1,
                                      child: _buildDetailRow(
                                        Icons.calendar_today_outlined,
                                        'Created At',
                                        user['created_at_formatted']?.toString() ?? 
                                            _formatDate(user['created_at']),
                                      ),
                                    ),
                                  ],
                                ),
                                AdminDashboardStyles.vSpaceMedium,
                                _buildDetailRow(
                                  Icons.update_outlined,
                                  'Updated At',
                                  user['updated_at_formatted']?.toString() ?? 
                                      _formatDate(user['updated_at']),
                                ),
                                
                                if (buttonType != null) ...[
                                  const SizedBox(height: 32),
                                  Divider(color: AdminDashboardStyles.secondaryTextColor.withOpacity(0.2)),
                                  const SizedBox(height: 24),
                                  _buildSectionTitle('Actions', Icons.settings_outlined),
                                  AdminDashboardStyles.vSpaceLarge,
                                  if (buttonType == 'requests') ...[
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            _detailsDialogAnimationController.reverse();
                                            Navigator.of(context).pop();
                                            if (onApprove != null) onApprove();
                                          },
                                          icon: Icon(Icons.check, size: 20, color: AdminDashboardStyles.surfaceColor),
                                          label: Text(
                                            'Approve',
                                            style: TextStyle(color: AdminDashboardStyles.surfaceColor, fontSize: 16, fontWeight: FontWeight.w600),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AdminDashboardStyles.successColor,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isMobile ? 16 : 24, 
                                              vertical: isMobile ? 12 : 18,
                                            ),
                                            minimumSize: Size(0, isMobile ? 48 : 56),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                        AdminDashboardStyles.hSpaceMedium,
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            _detailsDialogAnimationController.reverse();
                                            Navigator.of(context).pop();
                                            if (onReject != null) onReject();
                                          },
                                          icon: Icon(Icons.close, size: 20, color: AdminDashboardStyles.errorColor),
                                          label: Text(
                                            'Reject',
                                            style: TextStyle(color: AdminDashboardStyles.errorColor, fontSize: 16, fontWeight: FontWeight.w600),
                                          ),
                                            style: OutlinedButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isMobile ? 16 : 24, 
                                                vertical: isMobile ? 12 : 18,
                                              ),
                                              minimumSize: Size(0, isMobile ? 48 : 56),
                                              side: BorderSide(color: AdminDashboardStyles.errorColor, width: 1.5),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                        ),
                                      ],
                                    ),
                                  ] else if (buttonType == 'rejected') ...[
                                    
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _detailsDialogAnimationController.reverse();
                                          Navigator.of(context).pop();
                                          if (onApprove != null) onApprove();
                                        },
                                        icon: Icon(Icons.check, size: 20, color: AdminDashboardStyles.surfaceColor),
                                        label: Text(
                                          'Approve',
                                          style: TextStyle(color: AdminDashboardStyles.surfaceColor, fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AdminDashboardStyles.successColor,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isMobile ? 16 : 24, 
                                            vertical: isMobile ? 12 : 18,
                                          ),
                                          minimumSize: Size(0, isMobile ? 48 : 56),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else if (buttonType == 'blocked') ...[
                                    
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _detailsDialogAnimationController.reverse();
                                          Navigator.of(context).pop();
                                          if (onUnblock != null) onUnblock();
                                        },
                                        icon: Icon(Icons.lock_open, size: 20, color: AdminDashboardStyles.surfaceColor),
                                        label: Text(
                                          'Unblock',
                                          style: TextStyle(color: AdminDashboardStyles.surfaceColor, fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AdminDashboardStyles.successColor,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isMobile ? 16 : 24, 
                                            vertical: isMobile ? 12 : 18,
                                          ),
                                          minimumSize: Size(0, isMobile ? 48 : 56),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else if (buttonType == 'verified') ...[
                                    
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _detailsDialogAnimationController.reverse();
                                          Navigator.of(context).pop();
                                          if (onBlock != null) onBlock();
                                        },
                                        icon: Icon(Icons.block, size: 20, color: AdminDashboardStyles.surfaceColor),
                                        label: Text(
                                          'Block',
                                          style: TextStyle(color: AdminDashboardStyles.surfaceColor, fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AdminDashboardStyles.errorColor,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isMobile ? 16 : 24, 
                                            vertical: isMobile ? 12 : 18,
                                          ),
                                          minimumSize: Size(0, isMobile ? 48 : 56),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _detailsDialogAnimationController.reverse();
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminDashboardStyles.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                              ),
                              child: Text(
                                'Close',
                                style: TextStyle(
                                  color: AdminDashboardStyles.surfaceColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _detailsDialogAnimationController.reset();
    });
  }

  Future<Map<String, dynamic>> _loadStoreInfo(Map<String, dynamic> user) async {
    try {
      final userId = user['id'] ?? user['user_id'] ?? user['userId'];
      if (userId == null) return {};
      
      final result = await ApiService.getStoreInfo(int.tryParse(userId.toString()) ?? 0);
      if (result['success'] && result['data'] != null) {
        return Map<String, dynamic>.from(result['data']);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AdminDashboardStyles.primaryColor, size: 20),
        AdminDashboardStyles.hSpaceSmall,
        Text(
          title,
          style: AdminDashboardStyles.sectionTitleStyle,
        ),
      ],
    );
  }

  Widget _buildImageWidget(String imagePath, {BoxFit fit = BoxFit.cover, Widget? errorWidget}) {
    if (imagePath.isEmpty) return errorWidget ?? const Icon(Icons.image);
    
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://') || imagePath.startsWith('blob:')) {
      return Image.network(
        imagePath,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? Icon(Icons.image, color: AdminDashboardStyles.secondaryTextColor);
        },
      );
    } else if (imagePath.startsWith('data:image')) {
      
      try {
        final base64String = imagePath.split(',').length > 1 
            ? imagePath.split(',')[1] 
            : imagePath;
        return Image.memory(
          base64Decode(base64String),
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? Icon(Icons.image, color: AdminDashboardStyles.secondaryTextColor);
          },
        );
      } catch (e) {
        return errorWidget ?? Icon(Icons.image, color: AdminDashboardStyles.secondaryTextColor);
      }
    } else if (kIsWeb) {
      
      return errorWidget ?? Icon(Icons.image, color: AdminDashboardStyles.secondaryTextColor);
    } else {
      
      final file = File(imagePath);
      return Image.file(
        file,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? Icon(Icons.image, color: AdminDashboardStyles.secondaryTextColor);
        },
      );
    }
    return errorWidget ?? Icon(Icons.image, color: AdminDashboardStyles.secondaryTextColor);
  }

  Widget _buildImageDetailRow(IconData icon, String label, String imagePath) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AdminDashboardStyles.detailCardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AdminDashboardStyles.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AdminDashboardStyles.primaryColor, size: 20),
          ),
          AdminDashboardStyles.hSpaceMedium,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AdminDashboardStyles.labelTextStyle,
                ),
                AdminDashboardStyles.vSpaceSmall,
                GestureDetector(
                  onTap: () => _showImagePopup(imagePath),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AdminDashboardStyles.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImageWidget(
                        imagePath,
                        fit: BoxFit.cover,
                        errorWidget: Icon(Icons.store, size: 30, color: AdminDashboardStyles.secondaryTextColor.withOpacity(0.4)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePopup(String imagePath) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      barrierDismissible: true,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Dialog(
            backgroundColor: AdminDashboardStyles.transparentColor,
            elevation: 0,
            insetPadding: const EdgeInsets.all(20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildImageWidget(
                      imagePath,
                      fit: BoxFit.contain,
                      errorWidget: const Icon(Icons.error_outline, color: Colors.white, size: 50),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    backgroundColor: AdminDashboardStyles.dialogBarrierColor,
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isMultiline = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AdminDashboardStyles.detailCardDecoration,
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AdminDashboardStyles.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AdminDashboardStyles.primaryColor, size: 20),
          ),
          AdminDashboardStyles.hSpaceMedium,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AdminDashboardStyles.labelTextStyle,
                ),
                AdminDashboardStyles.vSpaceTiny,
                Text(
                  value,
                  style: AdminDashboardStyles.detailValueStyle.copyWith(
                    height: isMultiline ? 1.4 : 1.2,
                  ),
                  maxLines: isMultiline ? null : 2,
                  overflow: isMultiline ? null : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusFromHasAccess(dynamic hasAccess) {
    if (hasAccess == null) return 'Pending';
    
    final accessValue = hasAccess is int 
        ? hasAccess 
        : (hasAccess is String ? int.tryParse(hasAccess) : null);
    
    if (accessValue == null) return 'Pending';
    
    switch (accessValue) {
      case 1:
        return 'Verified';
      case -1:
        return 'Rejected';
      case -2:
        return 'Blocked';
      case 0:
      default:
        return 'Pending';
    }
  }

  Widget _buildStatusChip(String label, String status) {
    
    final isVerified = status.toLowerCase() == 'approved' || status.toLowerCase() == 'verified';
    final isRejected = status.toLowerCase() == 'rejected';
    final isBlocked = status.toLowerCase() == 'blocked';
    
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    
    if (isVerified) {
      statusColor = AdminDashboardStyles.successColor;
      statusBgColor = AdminDashboardStyles.successColor.withOpacity(0.1);
      statusIcon = Icons.check_circle_outline;
    } else if (isBlocked || isRejected) {
      statusColor = AdminDashboardStyles.errorColor;
      statusBgColor = AdminDashboardStyles.errorColor.withOpacity(0.1);
      statusIcon = isBlocked ? Icons.block : Icons.cancel_outlined;
    } else {
      
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.withOpacity(0.1);
      statusIcon = Icons.pending_outlined;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AdminDashboardStyles.secondaryTextColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AdminDashboardStyles.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              statusIcon,
              color: AdminDashboardStyles.primaryColor,
              size: 20,
            ),
          ),
          AdminDashboardStyles.hSpaceMedium,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AdminDashboardStyles.infoItemLabelStyle,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 13,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null || dateValue.toString().isEmpty) {
      return 'Not available';
    }
    try {
      if (dateValue is String) {
        final date = DateTime.tryParse(dateValue);
        if (date != null) {
          return '${date.day}/${date.month}/${date.year}';
        }
      }
      return dateValue.toString();
    } catch (e) {
      return 'Not available';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AdminDashboardStyles.backgroundColor,
      drawer: isMobile ? _buildDrawer() : null,
      appBar: isMobile ? _buildAppBar() : null,
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      bottomNavigationBar: null, 
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        
        _buildSidebar(),
        
        Expanded(
          child: Column(
            children: [
              
              _buildHeader(),
              
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return _buildLayout();
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
        duration: AdminDashboardStyles.defaultAnimationDuration,
        curve: AdminDashboardStyles.defaultAnimationCurve,
        width: _isSidebarHovered ? AdminDashboardStyles.sidebarExpandedWidth : AdminDashboardStyles.sidebarCollapsedWidth,
      decoration: AdminDashboardStyles.sidebarDecoration,
      child: Column(
        children: [
            
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _isSidebarHovered ? AdminDashboardStyles.spacingExtraLarge : 20,
                vertical: _isSidebarHovered ? AdminDashboardStyles.spacingLarge : AdminDashboardStyles.spacingMedium,
              ),
              child: Row(
                mainAxisAlignment: _isSidebarHovered ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
          Container(
                    width: 40,
                    height: 40,
            decoration: AdminDashboardStyles.logoContainerDecoration,
                    child: Center(
                      child: Text(
                        'f',
                  style: AdminDashboardStyles.sidebarLogoStyle,
                      ),
                    ),
                  ),
                  if (_isSidebarHovered) ...[
                AdminDashboardStyles.hSpaceMedium,
                Expanded(
                      child: RichText(
                        text: TextSpan(
                    children: [
                            TextSpan(
                                text: 'fitaura',
                        style: AdminDashboardStyles.sidebarBrandStyle,
                      ),
                            TextSpan(
                                text: '.',
                        style: AdminDashboardStyles.sidebarBrandStyle.copyWith(
                          color: AdminDashboardStyles.primaryColor,
                        ),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ),
                  ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
          
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: _navItems.expand((item) {
                  final isParent = item['isParent'] as bool? ?? false;
                  if (isParent) {
                    final subItems = item['subItems'] as List<Map<String, dynamic>>? ?? [];
                    final isAccounts = item['index'] == -1;
                    final isProducts = item['index'] == -2;
                    final isExpanded = (isAccounts && _isAccountsExpanded) || (isProducts && _isProductsExpanded);
                    
                    return [
          _buildSidebarNavItem(
                        icon: item['icon'] as IconData,
                        activeIcon: item['activeIcon'] as IconData,
                        title: item['label'] as String,
                        index: item['index'] as int,
                        isParent: true,
                        subItems: subItems,
                        isAccounts: isAccounts,
                        isProducts: isProducts,
                      ),
                      if (isExpanded && _isSidebarHovered)
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            children: subItems.map((subItem) => _buildSidebarSubItem(
                              icon: subItem['icon'] as IconData,
                              activeIcon: subItem['activeIcon'] as IconData,
                              title: subItem['label'] as String,
                              index: subItem['index'] as int,
                            )).toList(),
                          ),
                        ),
                    ];
                  } else {
                    return [
          _buildSidebarNavItem(
                        icon: item['icon'] as IconData,
                        activeIcon: item['activeIcon'] as IconData,
                        title: item['label'] as String,
                        index: item['index'] as int,
                        isParent: false,
                      ),
                    ];
                  }
                }).toList(),
              ),
            ),
            
          Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildSidebarBottomItem(
                    icon: Icons.notifications_outlined,
                    activeIcon: Icons.notifications,
                    title: 'Notification',
                    onTap: () => _onTabChanged(_notificationsTabIndex),
                    isSelected: _selectedTab == _notificationsTabIndex,
                  ),
                  AdminDashboardStyles.vSpaceLarge,
                  _buildSidebarBottomItem(
                    icon: Icons.logout_outlined,
                    activeIcon: Icons.logout,
                    title: 'Logout',
                    onTap: _handleLogout,
                    isLogout: true,
                  ),
                ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required int index,
    bool isParent = false,
    List<Map<String, dynamic>>? subItems,
    bool isAccounts = false,
    bool isProducts = false,
  }) {
    final isSelected = _selectedTab == index;
    final hasSelectedSubItem = isParent && subItems != null && subItems.any((sub) => sub['index'] == _selectedTab);
    final isExpanded = (isAccounts && _isAccountsExpanded) || (isProducts && _isProductsExpanded);
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {
          if (isParent) {
            setState(() {
              if (isAccounts) {
                _isAccountsExpanded = !_isAccountsExpanded;
              } else if (isProducts) {
                _isProductsExpanded = !_isProductsExpanded;
              }
            });
          } else {
            _onTabChanged(index);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: AdminDashboardStyles.sidebarNavItemMargin,
          padding: AdminDashboardStyles.sidebarNavItemPadding(_isSidebarHovered),
          decoration: AdminDashboardStyles.sidebarNavItemDecoration(isSelected, hasSelectedSubItem),
          child: _isSidebarHovered
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      isSelected || hasSelectedSubItem ? activeIcon : icon,
                      color: (isSelected || hasSelectedSubItem) ? AdminDashboardStyles.primaryColor : AdminDashboardStyles.secondaryTextColor,
                      size: 22,
                    ),
                    AdminDashboardStyles.hSpaceMedium,
                    Expanded(
                      child: Text(
                        title,
                        style: AdminDashboardStyles.sidebarNavItemTextStyle(isSelected, hasSelectedSubItem),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isParent && _isSidebarHovered)
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: (isSelected || hasSelectedSubItem) ? AdminDashboardStyles.primaryColor : AdminDashboardStyles.secondaryTextColor,
                        size: 20,
                      ),
                  ],
                )
              : Center(
                  child: Icon(
                    isSelected || hasSelectedSubItem ? activeIcon : icon,
                    color: (isSelected || hasSelectedSubItem) ? AdminDashboardStyles.primaryColor : AdminDashboardStyles.secondaryTextColor,
                    size: 22,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSidebarSubItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedTab == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
      onTap: () => _onTabChanged(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: AdminDashboardStyles.fastAnimationDuration,
          margin: AdminDashboardStyles.sidebarSubItemMargin,
          padding: AdminDashboardStyles.sidebarSubItemPadding,
          decoration: AdminDashboardStyles.navItemDecoration(isSelected),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
                isSelected ? activeIcon : icon,
              color: isSelected ? AdminDashboardStyles.primaryColor : AdminDashboardStyles.secondaryTextColor,
                size: 20,
            ),
            AdminDashboardStyles.hSpaceMedium,
              Expanded(
                child: Text(
              title,
              style: AdminDashboardStyles.subNavItemStyle.copyWith(
                color: isSelected ? AdminDashboardStyles.primaryColor : AdminDashboardStyles.textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarBottomItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
    bool isSelected = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: AdminDashboardStyles.fastAnimationDuration,
          padding: AdminDashboardStyles.sidebarNavItemPadding(_isSidebarHovered),
          decoration: AdminDashboardStyles.navItemDecoration(isSelected),
          child: _isSidebarHovered
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      isSelected ? activeIcon : icon,
                      color: isSelected 
                          ? AdminDashboardStyles.primaryColor 
                          : (isLogout ? AdminDashboardStyles.errorColor : AdminDashboardStyles.secondaryTextColor),
              size: 22,
            ),
            AdminDashboardStyles.hSpaceMedium,
                    Expanded(
                      child: Text(
              title,
              style: AdminDashboardStyles.sidebarNavItemTextStyle(isSelected, false).copyWith(
                color: isSelected 
                    ? AdminDashboardStyles.primaryColor 
                    : (isLogout ? AdminDashboardStyles.errorColor : AdminDashboardStyles.textColor),
              ),
                        overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
                )
              : Center(
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected 
                        ? AdminDashboardStyles.primaryColor 
                        : (isLogout ? AdminDashboardStyles.errorColor : AdminDashboardStyles.secondaryTextColor),
                    size: 22,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
      decoration: AdminDashboardStyles.headerDecoration,
      child: Row(
        children: [
          
          Expanded(
            flex: isMobile ? 1 : 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
              _getHeaderTitle(),
              style: AdminDashboardStyles.headerTitleStyle.copyWith(
                fontSize: isMobile ? 20 : 24,
              ),
            ),
                SizedBox(height: isMobile ? 2 : 3),
                Text(
                  'Manage your app from here',
                  style: AdminDashboardStyles.headerSubtitleStyle.copyWith(
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            flex: isMobile ? 2 : 3,
            child: _selectedTab >= 1 && _selectedTab <= 7 
              ? Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : 500,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: AdminDashboardStyles.searchInputDecoration(isMobile),
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: AdminDashboardStyles.textColor,
                    ),
                  ),
                ),
              )
              : const SizedBox.shrink(),
          ),
          
          Expanded(
            flex: isMobile ? 1 : 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildAdminProfile(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminProfile() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return GestureDetector(
      onTap: () => _onTabChanged(_profileTabIndex),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : AdminDashboardStyles.spacingMedium,
            vertical: isMobile ? 6 : AdminDashboardStyles.spacingSmall,
          ),
          decoration: AdminDashboardStyles.adminProfileDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isMobile ? 36 : 40,
                height: isMobile ? 36 : 40,
                decoration: AdminDashboardStyles.adminAvatarDecoration,
                child: ClipOval(
                  child: _buildProfileImage(_userData?['profile_picture'], isMobile ? 36 : 40, isMobile),
                ),
              ),
              if (!isMobile) ...[
                AdminDashboardStyles.hSpaceMedium,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _userData?['name'] ?? widget.adminName,
                      style: AdminDashboardStyles.adminNameStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AdminDashboardStyles.vSpaceTiny,
                    Text(
                      'Admin',
                      style: AdminDashboardStyles.labelTextStyle,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayout() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AdminDashboardStyles.primaryColor,
      child: Column(
        children: [
          
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AdminDashboardStyles.surfaceColor,
      surfaceTintColor: AdminDashboardStyles.surfaceColor,
      scrolledUnderElevation: 0,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: AdminDashboardStyles.textColor),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: (_selectedTab >= 1 && _selectedTab <= 7) 
        ? Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: AdminDashboardStyles.searchInputDecoration(true),
              style: AdminDashboardStyles.subNavItemStyle.copyWith(
                color: AdminDashboardStyles.textColor,
              ),
            ),
          )
        : null,
      actions: [

        GestureDetector(
          onTap: () => _onTabChanged(_profileTabIndex),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AdminDashboardStyles.primaryColor,
              child: Text(
                (_userData?['name'] ?? widget.adminName).isNotEmpty
                    ? (_userData?['name'] ?? widget.adminName)[0].toUpperCase()
                    : 'A',
          style: TextStyle(
            color: AdminDashboardStyles.surfaceColor,
                  fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
            ),
          ),
        ),
      ],
      centerTitle: false,
      toolbarHeight: 64,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AdminDashboardStyles.surfaceColor,
      child: Column(
        children: [
          
          Container(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
            decoration: AdminDashboardStyles.drawerHeaderDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: AdminDashboardStyles.logoContainerDecoration,
                      child: Center(
                        child: Text(
                          'f',
                          style: AdminDashboardStyles.sidebarLogoStyle,
                        ),
                      ),
                    ),
                    AdminDashboardStyles.hSpaceMedium,
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                                text: 'fitaura',
                                style: AdminDashboardStyles.sidebarBrandStyle,
                              ),
                              TextSpan(
                                text: '.',
                                style: AdminDashboardStyles.sidebarBrandStyle.copyWith(
                                  color: AdminDashboardStyles.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerNavItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  index: 0,
                ),
                ExpansionTile(
                  leading: Icon(
                    Icons.account_circle_outlined,
                    color: _navItems.any((item) => item['subItems'] != null && 
                        (item['subItems'] as List).any((sub) => sub['index'] == _selectedTab))
                        ? AdminDashboardStyles.primaryColor : AdminDashboardStyles.secondaryTextColor,
                    size: 24,
                  ),
                  title: Text(
                    'Accounts',
                    style: TextStyle(
                      fontSize: 16,
                      color: AdminDashboardStyles.textColor,
                      fontWeight: _navItems.any((item) => item['subItems'] != null && 
                          (item['subItems'] as List).any((sub) => sub['index'] == _selectedTab))
                          ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  initiallyExpanded: _isAccountsExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _isAccountsExpanded = expanded;
                    });
                  },
                  children: [
                    _buildDrawerNavItem(
                      icon: Icons.pending_actions_outlined,
                      title: 'Account Requests',
                      index: 1,
                      isSubItem: true,
                    ),
                    _buildDrawerNavItem(
                      icon: Icons.verified_user_outlined,
                      title: 'Verified Users',
                      index: 2,
                      isSubItem: true,
                    ),
                    _buildDrawerNavItem(
                      icon: Icons.cancel_outlined,
                      title: 'Rejected Users',
                      index: 3,
                      isSubItem: true,
                    ),
                    _buildDrawerNavItem(
                      icon: Icons.block_outlined,
                      title: 'Blocked Users',
                      index: 4,
                      isSubItem: true,
                    ),
                  ],
                ),
                ExpansionTile(
                  leading: Icon(
                    Icons.shopping_bag_outlined,
                    color: _selectedTab >= 5 && _selectedTab <= 7
                        ? AdminDashboardStyles.primaryColor : AdminDashboardStyles.secondaryTextColor,
                    size: 24,
                  ),
                  title: Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 16,
                      color: AdminDashboardStyles.textColor,
                      fontWeight: _selectedTab >= 5 && _selectedTab <= 7
                          ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  initiallyExpanded: _isProductsExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _isProductsExpanded = expanded;
                    });
                  },
                  children: [
                    _buildDrawerNavItem(
                      icon: Icons.pending_actions_outlined,
                      title: 'Product Requests',
                      index: 5,
                      isSubItem: true,
                    ),
                    _buildDrawerNavItem(
                      icon: Icons.check_circle_outline,
                      title: 'Approved Products',
                      index: 6,
                      isSubItem: true,
                    ),
                    _buildDrawerNavItem(
                      icon: Icons.cancel_outlined,
                      title: 'Rejected Products',
                      index: 7,
                      isSubItem: true,
                    ),
                  ],
                ),
                _buildDrawerNavItem(
                  icon: Icons.notifications_none_outlined,
                  title: 'Notification',
                  index: _notificationsTabIndex,
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleLogout();
                },
                icon: const Icon(Icons.logout, color: AdminDashboardStyles.primaryColor, size: 20),
                label: Text(
                  'Logout',
                  style: TextStyle(color: AdminDashboardStyles.textColor, fontWeight: FontWeight.w600),
                ),
                style: AdminDashboardStyles.outlinedButtonStyle(radius: 8, color: AdminDashboardStyles.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerNavItem({
    required IconData icon,
    required String title,
    required int index,
    bool isSubItem = false,
  }) {
    final isSelected = _selectedTab == index;
    return ListTile(
      contentPadding: EdgeInsets.only(
        left: isSubItem ? 56 : 16,
        right: 16,
      ),
      leading: Icon(
        icon,
        color: isSelected ? AdminDashboardStyles.primaryColor : AdminDashboardStyles.secondaryTextColor,
        size: isSubItem ? 20 : 24,
      ),
      title: Text(
        title,
        style: AdminDashboardStyles.drawerItemTextStyle(isSelected, isSubItem),
      ),
      selected: isSelected,
      selectedTileColor: AdminDashboardStyles.primaryColor.withOpacity(0.1),
      onTap: () {
        Navigator.of(context).pop();
        _onTabChanged(index);
      },
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 12, right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Container(
        height: 64,
        decoration: AdminDashboardStyles.bottomNavDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_bottomNavItems.length, (idx) {
            final item = _bottomNavItems[idx];
            final targetIndex = item['index'] as int;
            final isSelected = _selectedTab == targetIndex;
            
            return Expanded(
              child: GestureDetector(
                onTap: () => _onTabChanged(targetIndex),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 50,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        width: 44,
                        height: 44,
                        decoration: AdminDashboardStyles.bottomNavItemDecoration(isSelected),
                        child: Icon(
                          isSelected 
                              ? (item['activeIcon'] ?? item['icon']) as IconData
                              : item['icon'] as IconData,
                          color: isSelected ? AdminDashboardStyles.primaryColor : AdminDashboardStyles.surfaceColor.withOpacity(0.7),
                          size: 24,
                        ),
                      ),
                      if (!isSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item['label'],
                            style: AdminDashboardStyles.bottomNavItemTextStyle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  String _getHeaderTitle() {
    switch (_selectedTab) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Account Requests';
      case 2:
        return 'Verified Users';
      case 3:
        return 'Rejected Users';
      case 4:
        return 'Blocked Users';
      case 5:
        return 'Product Requests';
      case 6:
        return 'Approved Products';
      case 7:
        return 'Rejected Products';
      case _notificationsTabIndex:
        return 'Notifications';
      case _profileTabIndex:
        return 'Admin Profile';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AdminDashboardStyles.primaryColor),
        ),
      );
    }

    switch (_selectedTab) {
      case 0:
        return _buildDashboardView();
      case 1:
        return _buildAccountRequestsView();
      case 2:
        return _buildVerifiedUsersView();
      case 3:
        return _buildRejectedUsersView();
      case 4:
        return _buildBlockedUsersView();
      case 5:
        return _buildProductRequestsView();
      case 6:
        return _buildApprovedProductsView();
      case 7:
        return _buildRejectedProductsView();
      case _notificationsTabIndex:
        return _buildNotificationsView();
      case _profileTabIndex:
        return _buildAdminProfileView();
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildDashboardView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    final query = _searchController.text.toLowerCase();

    final allUsers = query.isEmpty ? _allUsers : _allUsers.where((user) {
      final name = (user['full_name'] ?? user['name'] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();

    final accountRequests = allUsers.where((user) {
      final hasAccess = user['has_access'];
      if (hasAccess is int) return hasAccess == 0;
      if (hasAccess is String) return int.tryParse(hasAccess) == 0;
      return false;
    }).length;
    
    final verifiedUsers = allUsers.where((user) {
      final hasAccess = user['has_access'];
      if (hasAccess is int) return hasAccess == 1;
      if (hasAccess is String) return int.tryParse(hasAccess) == 1;
      return false;
    }).length;
    
    final rejectedUsers = allUsers.where((user) {
      final hasAccess = user['has_access'];
      if (hasAccess is int) return hasAccess == -1 || hasAccess == -2;
      if (hasAccess is String) {
        final val = int.tryParse(hasAccess);
        return val == -1 || val == -2;
      }
      return false;
    }).length;

    final allProducts = query.isEmpty ? _allProducts : _allProducts.where((product) {
      final name = (product['product_name'] ?? product['name'] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();

    final productRequests = allProducts.where((product) {
      final status = product['is_verified'];
      if (status is int) return status == 0;
      if (status is String) return status == 'pending' || status == '0';
      return false;
    }).length;
    
    final approvedProducts = allProducts.where((product) {
      final status = product['is_verified'];
      if (status is int) return status == 1;
      if (status is String) return status == 'accepted' || status == 'approved' || status == '1';
      return false;
    }).length;
    
    final rejectedProducts = allProducts.where((product) {
      final status = product['is_verified'];
      if (status is int) return status == -1;
      if (status is String) return status == 'rejected' || status == '-1';
      return false;
    }).length;

    return SingleChildScrollView(
      child: Container(
        padding: AdminDashboardStyles.screenPadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                _buildStatsGrid(
                  accountRequests: accountRequests,
                  verifiedUsers: verifiedUsers,
                  rejectedUsers: rejectedUsers,
                  productRequests: productRequests,
                  approvedProducts: approvedProducts,
                  rejectedProducts: rejectedProducts,
                ),
                AdminDashboardStyles.vSpaceXXL,
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Account Requests',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AdminDashboardStyles.textColor,
                      ),
                    ),
                    AdminDashboardStyles.vSpaceLarge,
                    _buildRecentUsersList(allUsers, isMobile),
                    const SizedBox(height: 16),
                    Text(
                      'Recent Product Requests',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AdminDashboardStyles.textColor,
                      ),
                    ),
                    AdminDashboardStyles.vSpaceLarge,
                    _buildRecentProductsList(allProducts, isMobile),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    }

  Widget _buildStatsGrid({
    required int accountRequests,
    required int verifiedUsers,
    required int rejectedUsers,
    required int productRequests,
    required int approvedProducts,
    required int rejectedProducts,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        
        int crossAxisCount;
        double childAspectRatio;
        
        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
          childAspectRatio = 1.25;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 3;
          childAspectRatio = 1.3;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 1.5;
        }
        
        return GridView.count(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              'Total Users',
              _allUsers.length.toString(),
              Icons.people_outline,
              Colors.blue,
            ),
            _buildStatCard(
              'Account Requests',
              accountRequests.toString(),
              Icons.pending_actions_outlined,
              Colors.orange,
            ),
            _buildStatCard(
              'Verified Users',
              verifiedUsers.toString(),
              Icons.verified_user_outlined,
              AdminDashboardStyles.successColor,
            ),
            _buildStatCard(
              'Rejected/Blocked',
              rejectedUsers.toString(),
              Icons.block_outlined,
              AdminDashboardStyles.errorColor,
            ),
            _buildStatCard(
              'Total Products',
              _allProducts.length.toString(),
              Icons.inventory_2_outlined,
              Colors.purple,
            ),
            _buildStatCard(
              'Product Requests',
              productRequests.toString(),
              Icons.pending_outlined,
              Colors.orange,
            ),
            _buildStatCard(
              'Approved Products',
              approvedProducts.toString(),
              Icons.check_circle_outline,
              AdminDashboardStyles.successColor,
            ),
            _buildStatCard(
              'Rejected Products',
              rejectedProducts.toString(),
              Icons.cancel_outlined,
              AdminDashboardStyles.errorColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentUsersList(List<Map<String, dynamic>> allUsers, bool isMobile) {
    final recentRequests = allUsers
        .where((user) {
          final hasAccess = user['has_access'];
          if (hasAccess is int) return hasAccess == 0;
          if (hasAccess is String) return int.tryParse(hasAccess) == 0;
          return false;
        })
        .take(5)
        .toList();

    if (recentRequests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No pending account requests',
            style: TextStyle(
              fontSize: 16,
              color: AdminDashboardStyles.secondaryTextColor,
            ),
          ),
        ),
      );
    }

    return Column(
      children: recentRequests
          .map((user) => _buildUserCard(
                user: user,
                showActions: true,
                buttonType: 'requests',
                onApprove: () => _handleApprove(user),
                onReject: () => _handleReject(user),
                onDetails: () => _showUserDetails(
                  user,
                  buttonType: 'requests',
                  onApprove: () => _handleApprove(user),
                  onReject: () => _handleReject(user),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildRecentProductsList(List<Map<String, dynamic>> allProducts, bool isMobile) {
    final recentRequests = allProducts
        .where((product) {
          final status = product['is_verified'];
          if (status is int) return status == 0;
          if (status is String) return status == 'pending' || status == '0';
          return false;
        })
        .take(5)
        .toList();

    if (recentRequests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No pending product requests',
            style: TextStyle(
              fontSize: 16,
              color: AdminDashboardStyles.secondaryTextColor,
            ),
          ),
        ),
      );
    }

    return Column(
      children: recentRequests
          .map((product) => _buildProductCard(
                product: product,
                showActions: true,
                buttonType: 'requests',
                onApprove: () => _handleProductApprove(product),
                onReject: () => _handleProductReject(product),
                onDetails: () => _showProductDetails(product, mode: 'requests'),
              ))
          .toList(),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: AdminDashboardStyles.statCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: AdminDashboardStyles.statCardIconDecoration(color),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AdminDashboardStyles.statCardValueStyle(isMobile),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AdminDashboardStyles.statCardLabelStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildRejectedUsersView() {
    final filteredUsers = _getFilteredUsers();

    return Container(
      padding: AdminDashboardStyles.screenPadding,
      child: Column(
        children: [
          _buildRoleFilter(),
          Expanded(child: _buildUserList(filteredUsers, 'rejected')),
        ],
      ),
    );
  }

  Widget _buildAccountRequestsView() {
    final filteredUsers = _getFilteredUsers();
    
    return Container(
      padding: AdminDashboardStyles.screenPadding,
      child: Column(
        children: [
          _buildRoleFilter(),
          Expanded(child: _buildUserList(filteredUsers, 'requests')),
        ],
      ),
    );
  }

  Widget _buildBlockedUsersView() {
    final filteredUsers = _getFilteredUsers();
    
    return Container(
      padding: AdminDashboardStyles.screenPadding,
      child: Column(
        children: [
          _buildRoleFilter(),
          Expanded(child: _buildUserList(filteredUsers, 'blocked')),
        ],
      ),
    );
  }

  Widget _buildVerifiedUsersView() {
    final filteredUsers = _getFilteredUsers();
    
    return Container(
      padding: AdminDashboardStyles.screenPadding,
      child: Column(
        children: [
          _buildRoleFilter(),
          Expanded(child: _buildUserList(filteredUsers, 'verified')),
        ],
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users, String buttonType) {
    if (users.isEmpty) {
      String message;
      IconData icon;
      switch (buttonType) {
        case 'requests':
          message = 'No account requests pending';
          icon = Icons.pending_actions;
          break;
        case 'rejected':
          message = 'No rejected users';
          icon = Icons.cancel;
          break;
        case 'blocked':
          message = 'No blocked users';
          icon = Icons.block;
          break;
        case 'verified':
          message = 'No verified users';
          icon = Icons.verified_user;
          break;
        default:
          message = 'No users found';
          icon = Icons.people_outline;
      }
      return _buildEmptyState(icon: icon, message: message);
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(
          user: user,
          showActions: true,
          buttonType: buttonType,
          onApprove: () => _handleApprove(user),
          onReject: () => _handleReject(user),
          onUnblock: () => _handleUnblock(user),
          onBlock: () => _handleBlock(user),
          onDetails: () => _showUserDetails(
            user,
            buttonType: buttonType,
            onApprove: () => _handleApprove(user),
            onReject: () => _handleReject(user),
            onUnblock: () => _handleUnblock(user),
            onBlock: () => _handleBlock(user),
          ),
        );
      },
    );
  }

  Widget _buildUserCard({
    required Map<String, dynamic> user,
    required bool showActions,
    required String buttonType, 
    VoidCallback? onApprove,
    VoidCallback? onReject,
    VoidCallback? onUnblock,
    VoidCallback? onBlock,
    VoidCallback? onDetails,
  }) {
    final name = user['name']?.toString() ?? 'Unknown';
    final email = user['email']?.toString() ?? 'No email';
    final role = user['role']?.toString() ?? 'user';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                    decoration: AdminDashboardStyles.imageBackgroundDecoration,
                  child: ClipOval(
                  child: _buildImageWidget(
                    (user['profile_picture'] ?? 
                     user['profile_pic'] ?? 
                     user['image'] ?? 
                     user['logo'] ?? 
                     user['logo_url'] ?? 
                     user['logo_path'] ?? '').toString(),
                    errorWidget: Icon(
                      role == 'seller' ? Icons.store : Icons.person,
                      color: AdminDashboardStyles.primaryColor,
                      size: 28,
                    ),
                  ),
                ),
                ),
                AdminDashboardStyles.hSpaceLarge,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: AdminDashboardStyles.cardNameStyle,
                            ),
                            AdminDashboardStyles.hSpaceSmall,
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: AdminDashboardStyles.roleTagDecoration(
                              role == 'seller' ? AdminDashboardStyles.sellerColor : AdminDashboardStyles.customerColor
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: AdminDashboardStyles.roleTagTextStyle(
                                role == 'seller' ? AdminDashboardStyles.sellerColor : AdminDashboardStyles.customerColor
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: AdminDashboardStyles.emailStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showActions) ...[
              AdminDashboardStyles.vSpaceLarge,
              Divider(color: AdminDashboardStyles.secondaryTextColor.withOpacity(0.2)),
              AdminDashboardStyles.vSpaceMedium,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  
                  OutlinedButton.icon(
                    onPressed: onDetails,
                    icon: Icon(Icons.info_outline, size: 16, color: AdminDashboardStyles.primaryColor),
                    label: Text('Review', style: TextStyle(color: AdminDashboardStyles.primaryColor, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                      minimumSize: const Size(0, 56),
                      side: BorderSide(color: AdminDashboardStyles.primaryColor, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required Map<String, dynamic> product,
    required bool showActions,
    required String buttonType, 
    VoidCallback? onApprove,
    VoidCallback? onReject,
    VoidCallback? onDetails,
  }) {
    final productName = product['product_name'] ?? product['name'] ?? 'Unknown Product';
    final brand = product['brand']?.toString() ?? 'No brand';
    final category = product['category']?.toString() ?? 'No category';
    final price = product['price'] ?? product['minimum_selling_price'] ?? 'N/A';

    final storeName = product['store_name']?.toString() ?? 'Unknown Store';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AdminDashboardStyles.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                    decoration: AdminDashboardStyles.imageBackgroundDecoration.copyWith(
                      image: (product['product_images'] != null && 
                             (product['product_images'] as List).isNotEmpty)
                          ? DecorationImage(
                              image: (product['product_images'] as List)[0].toString().startsWith('http')
                                  ? NetworkImage((product['product_images'] as List)[0]) as ImageProvider
                                  : MemoryImage(base64Decode((product['product_images'] as List)[0].toString().split(',').last)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  child: (product['product_images'] == null || 
                         (product['product_images'] as List).isEmpty)
                      ? Icon(
                          Icons.shopping_bag,
                          color: AdminDashboardStyles.primaryColor,
                          size: 28,
                        )
                      : null,
                ),
                AdminDashboardStyles.hSpaceLarge,
                    Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: AdminDashboardStyles.cardNameStyle.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.store, size: 14, color: AdminDashboardStyles.secondaryTextColor),
                          AdminDashboardStyles.hSpaceTiny,
                          Text(
                            storeName, 
                            style: AdminDashboardStyles.headerSubtitleStyle.copyWith(
                              color: AdminDashboardStyles.secondaryTextColor,
                            ),
                          ),
                          if (category.isNotEmpty && category != 'No category') ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 14,
                                color: AdminDashboardStyles.secondaryTextColor,
                              ),
                            ),
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 14,
                                color: AdminDashboardStyles.secondaryTextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Price: Rs $price',
                        style: AdminDashboardStyles.detailValueStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showActions) ...[
              AdminDashboardStyles.vSpaceLarge,
              Divider(color: AdminDashboardStyles.secondaryTextColor.withOpacity(0.2)),
              AdminDashboardStyles.vSpaceMedium,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  
                  OutlinedButton.icon(
                    onPressed: onDetails,
                    icon: Icon(Icons.info_outline, size: 16, color: AdminDashboardStyles.primaryColor),
                    label: Text('Review', style: TextStyle(color: AdminDashboardStyles.primaryColor, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                      minimumSize: const Size(0, 56),
                      side: BorderSide(color: AdminDashboardStyles.primaryColor, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AdminDashboardStyles.secondaryTextColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AdminDashboardStyles.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AdminDashboardStyles.infoItemValueStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductRequestsView() {
    return Container(
      padding: AdminDashboardStyles.screenPadding,
      child: _buildProductList(_getFilteredProducts(), 'requests'),
    );
  }

  Widget _buildApprovedProductsView() {
    return Container(
      padding: AdminDashboardStyles.screenPadding,
      child: _buildProductList(_getFilteredProducts(), 'approved'),
    );
  }

  Widget _buildRejectedProductsView() {
    return Container(
      padding: AdminDashboardStyles.screenPadding,
      child: _buildProductList(_getFilteredProducts(), 'rejected'),
    );
  }

  Widget _buildNotificationsView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    final query = _searchController.text.toLowerCase();
    final filteredNotifications = query.isEmpty
        ? _notifications
        : _notifications.where((n) {
            final message = (n['message'] ?? '').toString().toLowerCase();
            final title = (n['title'] ?? '').toString().toLowerCase();
            return message.contains(query) || title.contains(query);
          }).toList();

    if (filteredNotifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.notifications_none,
        message: 'No notifications',
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView.builder(
            itemCount: filteredNotifications.length,
            itemBuilder: (context, index) {
              final notification = filteredNotifications[index];
              return _buildNotificationCard(notification);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    
    final message = notification['message']?.toString() ?? '';
    final title = notification['title']?.toString() ?? 'Notification';
    final isRead = (notification['is_read'] == 1 || notification['is_read'] == '1');
    final notificationId = notification['notification_id'];

    String userName = '';
    if (message.isNotEmpty) {
      final parts = message.split(' has ');
      if (parts.length >= 2) {
        userName = parts[0].trim();
      }
    }

    final createdAt = notification['created_at'];
    String timeAgo = _formatTimeAgo(createdAt);

    final colors = [
      const Color(0xFF4CAF50), 
      const Color(0xFFE91E63), 
      const Color(0xFF9E9E9E), 
      const Color(0xFF2196F3), 
      const Color(0xFF9C27B0), 
    ];
    final borderColor = colors[userName.hashCode % colors.length];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          
          if (!isRead && notificationId != null) {
            final result = await ApiService.markAdminNotificationRead(notificationId is int ? notificationId : int.parse(notificationId.toString()));
            if (result['success']) {
              _loadNotifications();
            }
          }

          final lowerTitle = title.toLowerCase();
          final lowerMessage = message.toLowerCase();

          int? targetIndex;

          if (lowerTitle.contains('product') || lowerMessage.contains('product request')) {
            targetIndex = 5; 
          } else if (lowerTitle.contains('account') || lowerMessage.contains('account request') || 
              lowerTitle.contains('profile') || lowerMessage.contains('re-verification')) {
            targetIndex = 1; 
          }

          if (targetIndex != null) {
            _onTabChanged(targetIndex);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: AdminDashboardStyles.notificationCardDecoration(isRead),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: borderColor,
                        width: 2,
                      ),
                      color: borderColor.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: borderColor,
                        size: 24,
                      ),
                    ),
                  ),
                  if (!isRead)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: AdminDashboardStyles.unreadIndicatorDecoration,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AdminDashboardStyles.notificationTitleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: AdminDashboardStyles.notificationMessageStyle(isRead),
                    ),
                  ],
                ),
              ),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeAgo,
                    style: AdminDashboardStyles.notificationTimeStyle,
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 22,
                      color: Colors.red.withOpacity(0.7),
                    ),
                    onPressed: () async {
                      if (notificationId != null) {
                        try {
                          final result = await ApiService.deleteAdminNotification(notificationId is int ? notificationId : int.parse(notificationId.toString()));
                          if (result['success']) {
                            _loadNotifications();
                            _showSnackBar('Notification deleted', Colors.black87);
                          } else {
                            _showSnackBar(result['message'] ?? 'Failed to delete', AdminDashboardStyles.errorColor);
                          }
                        } catch (e) {
                          _showSnackBar('An error occurred', AdminDashboardStyles.errorColor);
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime dateTime;
    if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return '';
    }

    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  Widget _buildProductList(List<Map<String, dynamic>> products, String mode) {
    if (products.isEmpty) {
      String message;
      IconData icon;
      switch (mode) {
        case 'requests':
          message = 'No product requests pending';
          icon = Icons.pending_actions;
          break;
        case 'approved':
          message = 'No approved products';
          icon = Icons.check_circle;
          break;
        case 'rejected':
          message = 'No rejected products';
          icon = Icons.cancel;
          break;
        default:
          message = 'No products found';
          icon = Icons.shopping_bag;
      }
      return _buildEmptyState(icon: icon, message: message);
    }

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(
          product: product,
          showActions: true,
          buttonType: mode,
          onApprove: () => _handleProductApprove(product),
          onReject: () => _handleProductReject(product),
          onDetails: () => _showProductDetails(product, mode: mode),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AdminDashboardStyles.secondaryTextColor.withOpacity(0.5),
            ),
            AdminDashboardStyles.vSpaceLarge,
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                color: AdminDashboardStyles.secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    bool isError = color == AdminDashboardStyles.errorColor || 
                  color == AdminDashboardStyles.errorColorAccent || 
                  color == const Color(0xFFE53935);
    CustomSnackBar.show(context, message, isError: isError);
  }

  Widget _buildAdminProfileView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      color: AdminDashboardStyles.backgroundColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                _buildAdminProfileHero(isMobile),
                const SizedBox(height: 24),

                _buildAdminInfoSection(isMobile),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminProfileHero(bool isMobile) {
    return Container(
      height: isMobile ? 200 : 260,
      decoration: AdminDashboardStyles.cardDecoration.copyWith(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AdminDashboardStyles.primaryColor,
                      Color(0xFF8D6E63),
                      Color(0xFF795548),
                    ],
                  ),
                ),
              ),
            ),
            
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(isMobile ? 20 : 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: isMobile ? 80 : 120,
                        height: isMobile ? 80 : 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ClipOval(
                          child: _buildProfileImage(_userData?['profile_picture'], isMobile ? 80 : 120, isMobile),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: isMobile ? 28 : 36,
                            width: isMobile ? 28 : 36,
                            decoration: BoxDecoration(
                              color: AdminDashboardStyles.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Icon(
                              Icons.edit_outlined, 
                              color: Colors.white, 
                              size: isMobile ? 14 : 18
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: isMobile ? 16 : 32),
                  
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userData?['name'] ?? widget.adminName,
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _buildAdminInfoSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AdminDashboardStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin_outlined, color: AdminDashboardStyles.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AdminDashboardStyles.textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showChangePasswordDialog,
                icon: const Icon(Icons.vpn_key_outlined, color: AdminDashboardStyles.primaryColor, size: 20),
                tooltip: 'Change Password',
              ),
              IconButton(
                onPressed: _showEditAdminDialog,
                icon: const Icon(Icons.edit_outlined, color: AdminDashboardStyles.primaryColor, size: 20),
                tooltip: 'Edit Profile',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAdminInfoTile('Full Name', _userData?['name'] ?? widget.adminName, Icons.badge_outlined),
          _buildAdminInfoTile('Email Address', _userData?['email'] ?? 'admin@fitaura.com', Icons.email_outlined),
          _buildAdminInfoTile('Role', 'System Administrator', Icons.admin_panel_settings_outlined),
          _buildAdminInfoTile('Contact Number', _userData?['contact_number'] ?? _userData?['phone'] ?? '+92 300 1234567', Icons.phone_outlined),
          _buildAdminInfoTile('Address', _userData?['address'] ?? 'Fitaura HQ, Phase 6, Lahore', Icons.location_on_outlined),
        ],
      ),
    );
  }

  Widget _buildAdminInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AdminDashboardStyles.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AdminDashboardStyles.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AdminDashboardStyles.secondaryTextColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AdminDashboardStyles.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _showProductDetails(Map<String, dynamic> product, {required String mode}) {
    _detailsDialogAnimationController.forward();
    showDialog(
      context: context,
      barrierColor: AdminDashboardStyles.dialogBarrierColor,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 768;
        
        return AnimatedBuilder(
          animation: _detailsDialogAnimationController,
          builder: (context, child) {
            return Opacity(
              opacity: _detailsDialogFadeAnimation.value,
              child: Transform.scale(
                scale: _detailsDialogScaleAnimation.value,
                child: Dialog(
                  backgroundColor: AdminDashboardStyles.transparentColor,
                  elevation: 0,
                  insetPadding: AdminDashboardStyles.dialogInsetPadding(isMobile, MediaQuery.of(context).size.width),
                  child: Container(
                    constraints: AdminDashboardStyles.dialogConstraints(isMobile, MediaQuery.of(context).size.height),
                    decoration: AdminDashboardStyles.detailDialogDecoration,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: AdminDashboardStyles.detailHeaderDecoration,
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: AdminDashboardStyles.detailImageContainerDecoration,
                                  child: Icon(
                                    Icons.shopping_bag,
                                    color: AdminDashboardStyles.surfaceColor,
                                    size: 28,
                                  ),
                              ),
                              AdminDashboardStyles.hSpaceLarge,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['product_name'] ?? 'Product Details',
                                      style: AdminDashboardStyles.detailNameStyle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      product['store_name']?.toString() ?? 'Unknown Store',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AdminDashboardStyles.surfaceColor.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                
                                if (product['product_images'] != null && (product['product_images'] as List).isNotEmpty) ...[
                                   _buildSectionTitle('Product Images', Icons.image),
                                   AdminDashboardStyles.vSpaceMedium,
                                   SizedBox(
                                     height: 100,
                                     child: ListView.builder(
                                       scrollDirection: Axis.horizontal,
                                       itemCount: (product['product_images'] as List).length,
                                       itemBuilder: (context, index) {
                                         final imageUrl = (product['product_images'] as List)[index];
                                         return Container(
                                           width: 100,
                                           margin: const EdgeInsets.only(right: 12),
                                           decoration: BoxDecoration(
                                             borderRadius: BorderRadius.circular(12),
                                             border: Border.all(color: AdminDashboardStyles.secondaryTextColor.withOpacity(0.2)),
                                             image: DecorationImage(
                                               image: imageUrl.toString().startsWith('http') 
                                                   ? NetworkImage(imageUrl) as ImageProvider
                                                   : MemoryImage(base64Decode(imageUrl.toString().split(',').last)),
                                               fit: BoxFit.cover,
                                             ),
                                           ),
                                         );
                                       },
                                     ),
                                   ),
                                   const SizedBox(height: 24),
                                ],

                                _buildSectionTitle('Basic Information', Icons.description_outlined),
                                AdminDashboardStyles.vSpaceLarge,
                                Flex(
                                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                                  crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: isMobile ? 0 : 1,
                                      child: _buildDetailRow(
                                        Icons.category_outlined,
                                        'Category',
                                        product['category'] ?? 'N/A',
                                      ),
                                    ),
                                    if (!isMobile) AdminDashboardStyles.hSpaceMedium,
                                    if (isMobile) AdminDashboardStyles.vSpaceMedium,
                                    Expanded(
                                      flex: isMobile ? 0 : 1,
                                      child: _buildDetailRow(
                                        Icons.attach_money,
                                        'Price',
                                        'Rs ${product['price'] ?? 0}',
                                      ),
                                    ),
                                  ],
                                ),
                                AdminDashboardStyles.vSpaceMedium,
                                _buildDetailRow(
                                  Icons.people_outline,
                                  'Gender',
                                  product['gender']?.toString() ?? 'Not specified',
                                ),
                                AdminDashboardStyles.vSpaceMedium,
                                _buildDetailRow(
                                  Icons.notes,
                                  'Description',
                                  product['description'] ?? 'No description available.',
                                  isMultiline: true,
                                ),

                                if (true) ...[
                                  const SizedBox(height: 24),
                                  _buildSectionTitle('Variants', Icons.layers_outlined),
                                  AdminDashboardStyles.vSpaceMedium,
                                  FutureBuilder<List<Map<String, dynamic>>>(
                                    future: ApiService.getProductVariants(int.tryParse(product['id']?.toString() ?? product['product_id']?.toString() ?? '0') ?? 0),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Center(child: CircularProgressIndicator(color: AdminDashboardStyles.primaryColor)),
                                        );
                                      }
                                      
                                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                                        return Text(
                                          'No variants available',
                                          style: TextStyle(color: AdminDashboardStyles.secondaryTextColor, fontStyle: FontStyle.italic),
                                        );
                                      }
                                      
                                      final variants = snapshot.data!;
                                      
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: AdminDashboardStyles.backgroundColor,
                                          border: Border.all(color: AdminDashboardStyles.secondaryTextColor.withOpacity(0.1)),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: variants.asMap().entries.map((entry) {
                                            final index = entry.key;
                                            final variant = entry.value;
                                            final isLast = index == variants.length - 1;
                                            
                                            return Container(
                                              decoration: BoxDecoration(
                                                border: isLast ? null : Border(
                                                  bottom: BorderSide(color: AdminDashboardStyles.secondaryTextColor.withOpacity(0.1)),
                                                ),
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 2,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'Size',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: AdminDashboardStyles.secondaryTextColor,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          '${variant['size']}',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                            color: AdminDashboardStyles.textColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'Color',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: AdminDashboardStyles.secondaryTextColor,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          '${variant['color']}',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                            color: AdminDashboardStyles.textColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          'Price',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: AdminDashboardStyles.secondaryTextColor,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          'Rs ${variant['price_per_variant']}',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                            color: AdminDashboardStyles.primaryColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          'Stock',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: AdminDashboardStyles.secondaryTextColor,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          '${variant['stock_quantity']}',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                            color: AdminDashboardStyles.textColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      );
                                    },
                                  ),
                                ],

                                const SizedBox(height: 24),
                                _buildSectionTitle('Status', Icons.info_outline),
                                AdminDashboardStyles.vSpaceLarge,
                                _buildStatusChip(
                                  'Current Status', 
                                  product['is_verified'] == 1 
                                      ? 'Approved' 
                                      : (product['is_verified'] == -1 ? 'Rejected' : 'Pending')
                                ), 

                                const SizedBox(height: 24),
                                _buildSectionTitle('Actions', Icons.settings_outlined),
                                AdminDashboardStyles.vSpaceLarge,
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    if (mode == 'requests' || mode == 'rejected')
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          _detailsDialogAnimationController.reverse();
                                          Navigator.of(context).pop();
                                          _handleProductApprove(product);
                                        },
                                        icon: const Icon(Icons.check, size: 20, color: AdminDashboardStyles.surfaceColor),
                                        label: const Text(
                                          'Approve',
                                          style: TextStyle(color: AdminDashboardStyles.surfaceColor, fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AdminDashboardStyles.successColor,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isMobile ? 16 : 24, 
                                            vertical: isMobile ? 12 : 18,
                                          ),
                                          minimumSize: Size(0, isMobile ? 48 : 56),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    if (mode == 'requests')
                                      AdminDashboardStyles.hSpaceMedium,
                                    if (mode == 'requests' || mode == 'approved')
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          _detailsDialogAnimationController.reverse();
                                          Navigator.of(context).pop();
                                          _handleProductReject(product);
                                        },
                                        icon: const Icon(Icons.close, size: 20, color: AdminDashboardStyles.errorColor),
                                        label: const Text(
                                          'Reject',
                                          style: TextStyle(color: AdminDashboardStyles.errorColor, fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isMobile ? 16 : 24, 
                                            vertical: isMobile ? 12 : 18,
                                          ),
                                          minimumSize: Size(0, isMobile ? 48 : 56),
                                          side: const BorderSide(color: AdminDashboardStyles.errorColor, width: 1.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _detailsDialogAnimationController.reverse();
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminDashboardStyles.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                              ),
                              child: Text(
                                'Close',
                                style: TextStyle(
                                  color: AdminDashboardStyles.surfaceColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _detailsDialogAnimationController.reset();
    });
  }

  Future<void> _handleProductApprove(Map<String, dynamic> product) async {
    final productId = product['product_id'] ?? product['id'];
    if (productId == null) return;
    
    setState(() => _isLoading = true);
    
    final result = await ApiService.updateProductStatus(
      productId: int.parse(productId.toString()),
      isVerified: 1, 
    );
    
    setState(() => _isLoading = false);
    
    if (result['success']) {
      _loadData();
    } else {
      _showSnackBar(result['message'] ?? 'Failed to approve product', AdminDashboardStyles.errorColor);
    }
  }

  Future<void> _handleProductReject(Map<String, dynamic> product) async {
    final productId = product['product_id'] ?? product['id'];
    if (productId == null) return;
    
    setState(() => _isLoading = true);
    
    final result = await ApiService.updateProductStatus(
      productId: int.parse(productId.toString()),
      isVerified: -1, 
    );
    
    setState(() => _isLoading = false);
    
    if (result['success']) {
      _loadData();
    } else {
      _showSnackBar(result['message'] ?? 'Failed to reject product', AdminDashboardStyles.errorColor);
    }
  }
}
