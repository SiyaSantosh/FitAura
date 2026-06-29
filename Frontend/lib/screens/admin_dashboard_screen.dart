import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _complaintFilterOptions = [
    {'label': 'All', 'value': 'all'},
    {'label': 'Active', 'value': 'active'},
    {'label': 'Completed', 'value': 'completed'},
    {'label': 'Rejected', 'value': 'rejected'},
  ];
  String _complaintFilter = 'all';
  Map<int, Map<String, dynamic>> _complaintDrafts = {};
  Map<int, TextEditingController> _complaintCommentControllers = {};
  Map<int, TextEditingController> _complaintRefundControllers = {};
  Map<int, bool> _savingComplaintIds = {};
  Map<int, String?> _complaintValidationErrors = {};
  int get _unreadNotificationCount {
    return _notifications.where((notification) {
      final isRead = notification['is_read'];
      return isRead != 1 && isRead != '1';
    }).length;
  }

  int get _activeReviewComplaintsCount {
    return _complaints.where((complaint) {
      final status = complaint['status']?.toString().trim().toLowerCase() ?? '';
      return status == 'active' || status == 'review';
    }).length;
  }

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
  static const int _settingsTabIndex = 11;
  static const int _sendNotificationTabIndex = 12;
  static const int _complaintsTabIndex = 13;

  // Send-notification form state
  final TextEditingController _notifTitleController = TextEditingController();
  final TextEditingController _notifMessageController = TextEditingController();
  String _notifTarget = 'all_customers'; // all_customers | all_sellers | all_users | specific_user
  List<Map<String, dynamic>> _notifSelectedUsers = [];
  String _notifUserSearchQuery = '';
  bool _isSendingNotif = false;

  String _language = 'English';
  String _themeMode = 'Light';
  final List<String> _languages = ['English'];
  final List<String> _themeModes = ['Light'];

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
    {'icon': Icons.feedback_outlined, 'activeIcon': Icons.feedback, 'label': 'Complaints', 'index': _complaintsTabIndex, 'isParent': false},
    {'icon': Icons.send_outlined, 'activeIcon': Icons.send, 'label': 'Send Notification', 'index': _sendNotificationTabIndex, 'isParent': false},
  ];

  final List<Map<String, dynamic>> _bottomNavItems = [
    {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard, 'label': 'Home', 'index': 0},
    {'icon': Icons.account_circle_outlined, 'activeIcon': Icons.account_circle, 'label': 'Accounts', 'index': 1},
    {'icon': Icons.shopping_bag_outlined, 'activeIcon': Icons.shopping_bag, 'label': 'Products', 'index': 5},
    {'icon': Icons.feedback_outlined, 'activeIcon': Icons.feedback, 'label': 'Complaints', 'index': _complaintsTabIndex},
    {'icon': Icons.notifications_outlined, 'activeIcon': Icons.notifications, 'label': 'Alerts', 'index': 8},
    {'icon': Icons.settings_outlined, 'activeIcon': Icons.settings, 'label': 'Settings', 'index': _settingsTabIndex},
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
    _loadNotifications();
    _loadComplaints();
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
    for (final controller in _complaintCommentControllers.values) {
      controller.dispose();
    }
    for (final controller in _complaintRefundControllers.values) {
      controller.dispose();
    }
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

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.getAllComplaints();
      if (result['success'] && result['data'] != null) {
        final complaints = (result['data'] as List<dynamic>)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        final drafts = <int, Map<String, dynamic>>{};
        for (final complaint in complaints) {
          final complaintId = int.tryParse(complaint['complaint_id'].toString());
          if (complaintId == null) continue;
          drafts[complaintId] = {
            'status': (complaint['status'] ?? 'review').toString(),
            'admin_decision': (complaint['admin_decision'] ?? '').toString(),
            'admin_verification': (complaint['admin_verification'] ?? '').toString(),
            'admin_comment': (complaint['admin_comment'] ?? '').toString(),
            'refund_amount': (complaint['refund_amount'] ?? '0.00').toString(),
          };
        }

        setState(() {
          _complaints = complaints;
          _complaintDrafts = drafts;
        });

        for (final complaint in complaints) {
          final complaintId = int.tryParse(complaint['complaint_id'].toString());
          if (complaintId == null) continue;
          final controller = _complaintCommentControllers.putIfAbsent(
            complaintId,
            () => TextEditingController(),
          );
          final refundController = _complaintRefundControllers.putIfAbsent(
            complaintId,
            () => TextEditingController(),
          );
          final draft = drafts[complaintId] ?? {};
          final commentText = draft['admin_comment']?.toString() ?? '';
          final refundText = draft['refund_amount']?.toString() ?? '0.00';
          if (controller.text != commentText) {
            controller.text = commentText;
          }
          if (refundController.text != refundText) {
            refundController.text = refundText;
          }
        }
      } else {
        setState(() {
          _complaints = [];
          _complaintDrafts = {};
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load complaints', AdminDashboardStyles.errorColor);
      }
      setState(() {
        _complaints = [];
        _complaintDrafts = {};
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

    if (index == _complaintsTabIndex) {
      setState(() {
        _selectedTab = index;
      });
      _loadComplaints();
      return;
    }

    if (index == _profileTabIndex) {
      setState(() {
        _selectedTab = index;
      });
      _loadUserData();
      return;
    }

    if (index == _settingsTabIndex) {
      setState(() {
        _selectedTab = index;
      });
      return;
    }

    if (index == _sendNotificationTabIndex) {
      // Ensure user list is loaded so the specific-user picker works
      if (_allUsers.isEmpty) _loadData();
      setState(() {
        _selectedTab = index;
      });
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
                        unreadCount: item['index'] == _complaintsTabIndex ? _activeReviewComplaintsCount : 0,
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
                    unreadCount: _unreadNotificationCount,
                  ),
                  AdminDashboardStyles.vSpaceLarge,
                  _buildSidebarBottomItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    title: 'Settings',
                    onTap: () => _onTabChanged(_settingsTabIndex),
                    isSelected: _selectedTab == _settingsTabIndex,
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
    int unreadCount = 0,
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AdminDashboardStyles.sidebarNavItemTextStyle(isSelected, hasSelectedSubItem),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AdminDashboardStyles.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
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
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      isSelected || hasSelectedSubItem ? activeIcon : icon,
                      color: (isSelected || hasSelectedSubItem) ? AdminDashboardStyles.primaryColor : AdminDashboardStyles.secondaryTextColor,
                      size: 22,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AdminDashboardStyles.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
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
    int unreadCount = 0,
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
                      child: Row(
                        children: [ 
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
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AdminDashboardStyles.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
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
            child: (_selectedTab >= 1 && _selectedTab <= 7) || _selectedTab == _complaintsTabIndex
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
      title: (_selectedTab >= 1 && _selectedTab <= 7) || _selectedTab == _complaintsTabIndex
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
                  icon: Icons.feedback_outlined,
                  title: 'Complaints',
                  index: _complaintsTabIndex,
                ),
                _buildDrawerNavItem(
                  icon: Icons.notifications_none_outlined,
                  title: 'Notification',
                  index: _notificationsTabIndex,
                ),
                _buildDrawerNavItem(
                  icon: Icons.send_outlined,
                  title: 'Send Notification',
                  index: _sendNotificationTabIndex,
                ),
                _buildDrawerNavItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  index: _settingsTabIndex,
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
                      
                      Stack(
                      alignment: Alignment.center,
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
                        if (targetIndex == _notificationsTabIndex && _unreadNotificationCount > 0)
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (targetIndex == _complaintsTabIndex && _activeReviewComplaintsCount > 0)
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _activeReviewComplaintsCount > 99 ? '99+' : _activeReviewComplaintsCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
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
      case _settingsTabIndex:
        return 'Settings';
      case _profileTabIndex:
        return 'Admin Profile';
      case _sendNotificationTabIndex:
        return 'Send Notification';
      case _complaintsTabIndex:
        return 'Complaints';
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
      case _complaintsTabIndex:
        return _buildComplaintsView();
      case _notificationsTabIndex:
        return _buildNotificationsView();
      case _settingsTabIndex:
        return _buildSettingsView();
      case _profileTabIndex:
        return _buildAdminProfileView();
      case _sendNotificationTabIndex:
        return _buildSendNotificationView();
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildSendNotificationView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    // ── Seller-dashboard colour tokens ────────────────────────────────────
    const Color brownColor      = Color(0xFF704F38);
    const Color lightGray       = Color(0xFF797979);
    const Color darkText        = Color(0xFF000000);
    const Color beigeBackground = Color(0xFFF5F1EB);
    const Color whiteColor      = Colors.white;

    final audiences = [
      {'value': 'all_customers', 'label': 'All Customers', 'icon': Icons.people_outline},
      {'value': 'all_sellers',   'label': 'All Sellers',   'icon': Icons.store_outlined},
      {'value': 'all_users',     'label': 'All Users',     'icon': Icons.groups_outlined},
      {'value': 'specific_user', 'label': 'Specific User', 'icon': Icons.person_search_outlined},
    ];

    final filteredUsers = _notifUserSearchQuery.isEmpty
        ? _allUsers
        : _allUsers.where((u) {
            final name  = (u['name']  ?? '').toString().toLowerCase();
            final email = (u['email'] ?? '').toString().toLowerCase();
            return name.contains(_notifUserSearchQuery) || email.contains(_notifUserSearchQuery);
          }).toList();

    Widget buildField({
      required String label,
      required TextEditingController controller,
      String? hint,
      int maxLines = 1,
      TextInputType? keyboardType,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: lightGray.withOpacity(0.6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: brownColor, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : isMobile ? 14 : 16,
              ),
            ),
          ),
        ],
      );
    }

    Widget formPanel = Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Details',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Compose and broadcast a notification to your users',
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: lightGray,
            ),
          ),
          SizedBox(height: isMobile ? 24 : 32),

          buildField(
            label: 'Notification Title',
            controller: _notifTitleController,
            hint: 'e.g. New Arrivals This Week!',
          ),
          SizedBox(height: isMobile ? 20 : 24),

          buildField(
            label: 'Message',
            controller: _notifMessageController,
            hint: 'Write your notification message here…',
            maxLines: 5,
          ),
          SizedBox(height: isMobile ? 24 : 32),

          Text(
            'Send To',
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),
          const SizedBox(height: 12),

          ...audiences.map((opt) {
            final val      = opt['value'] as String;
            final lbl      = opt['label'] as String;
            final ico      = opt['icon']  as IconData;
            final selected = _notifTarget == val;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _notifTarget = val;
                  if (val != 'specific_user') _notifSelectedUsers.clear();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? brownColor.withOpacity(0.06) : whiteColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? brownColor : lightGray.withOpacity(0.3),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(ico, size: 20, color: selected ? brownColor : lightGray),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lbl,
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 15,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? brownColor : darkText,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? brownColor : Colors.transparent,
                        border: Border.all(
                          color: selected ? brownColor : lightGray.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),

          if (_notifTarget == 'specific_user') ...[
            SizedBox(height: isMobile ? 20 : 24),
            Text(
              'Choose Users',
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              onChanged: (v) => setState(() => _notifUserSearchQuery = v.toLowerCase()),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name or email…',
                hintStyle: TextStyle(color: lightGray.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: lightGray, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: brownColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 10),

            if (_notifSelectedUsers.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: brownColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: brownColor.withOpacity(0.3)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _notifSelectedUsers.map((u) {
                    return Chip(
                      backgroundColor: brownColor.withOpacity(0.12),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      label: Text(
                        u['name'] ?? 'User',
                        style: const TextStyle(fontSize: 12, color: brownColor, fontWeight: FontWeight.w600),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 14, color: brownColor),
                      onDeleted: () {
                        setState(() {
                          _notifSelectedUsers.removeWhere((item) => item['user_id'] == u['user_id']);
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

            Container(
              constraints: const BoxConstraints(maxHeight: 140),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lightGray.withOpacity(0.25)),
              ),
              child: filteredUsers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text('No users found', style: TextStyle(color: lightGray)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filteredUsers.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: lightGray.withOpacity(0.15)),
                      itemBuilder: (context, i) {
                        final user     = filteredUsers[i];
                        final isChosen = _notifSelectedUsers.any((item) => item['user_id'] == user['user_id']);
                        final role     = (user['role'] ?? '').toString().toLowerCase();
                        return ListTile(
                          dense: true,
                          selected: isChosen,
                          selectedTileColor: brownColor.withOpacity(0.06),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: brownColor.withOpacity(0.12),
                            child: Text(
                              (user['name'] ?? 'U').toString().isNotEmpty
                                  ? (user['name'] ?? 'U').toString()[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: brownColor,
                              ),
                            ),
                          ),
                          title: Text(
                            user['name']?.toString() ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isChosen ? FontWeight.w700 : FontWeight.w500,
                              color: darkText,
                            ),
                          ),
                          subtitle: Text(
                            user['email']?.toString() ?? '',
                            style: TextStyle(fontSize: 12, color: lightGray),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: lightGray.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  role.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: lightGray,
                                  ),
                                ),
                              ),
                              if (isChosen) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.check_circle, color: brownColor, size: 18),
                              ],
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              if (isChosen) {
                                _notifSelectedUsers.removeWhere((item) => item['user_id'] == user['user_id']);
                              } else {
                                _notifSelectedUsers.add(user);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );

    Widget sidebarPanel = SizedBox(
      width: isMobile ? double.infinity : 300,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: lightGray.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: beigeBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: lightGray.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: brownColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.campaign_outlined, color: brownColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _notifTitleController,
                              builder: (_, v, __) => Text(
                                v.text.isEmpty ? 'Notification Title' : v.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: v.text.isEmpty ? lightGray : darkText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 3),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _notifMessageController,
                              builder: (_, v, __) => Text(
                                v.text.isEmpty ? 'Your message will appear here…' : v.text,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: v.text.isEmpty ? lightGray.withOpacity(0.6) : lightGray,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.groups_outlined, size: 16, color: lightGray),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _notifTarget == 'all_customers' ? 'All Customers'
                            : _notifTarget == 'all_sellers' ? 'All Sellers'
                            : _notifTarget == 'all_users' ? 'All Users'
                            : _notifSelectedUsers.isNotEmpty
                                ? _notifSelectedUsers.map((u) => u['name'] ?? 'User').join(', ')
                                : 'Select user(s)…',
                        style: TextStyle(
                          fontSize: 13,
                          color: lightGray,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSendingNotif
                  ? null
                  : () async {
                      final title   = _notifTitleController.text.trim();
                      final message = _notifMessageController.text.trim();

                      if (title.isEmpty) {
                        _showSnackBar('Please enter a notification title', AdminDashboardStyles.errorColor);
                        return;
                      }
                      
                      // Title Word count validation: < 20 words or numbers
                      final titleWordCount = title.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
                      if (titleWordCount >= 20) {
                        _showSnackBar('Title must be less than 20 words/numbers (current: $titleWordCount)', AdminDashboardStyles.errorColor);
                        return;
                      }

                      if (message.isEmpty) {
                        _showSnackBar('Please enter a notification message', AdminDashboardStyles.errorColor);
                        return;
                      }

                      // Message Word count validation: < 50 words or numbers
                      final msgWordCount = message.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
                      if (msgWordCount >= 50) {
                        _showSnackBar('Message must be less than 50 words (current: $msgWordCount)', AdminDashboardStyles.errorColor);
                        return;
                      }

                      if (_notifTarget == 'specific_user' && _notifSelectedUsers.isEmpty) {
                        _showSnackBar('Please select at least one user to send to', AdminDashboardStyles.errorColor);
                        return;
                      }

                      setState(() => _isSendingNotif = true);

                      final userIds = _notifTarget == 'specific_user'
                          ? _notifSelectedUsers.map((u) => u['user_id'] as int).toList()
                          : null;

                      final result = await ApiService.sendAdminNotification(
                        title: title,
                        message: message,
                        target: _notifTarget,
                        userIds: userIds,
                      );

                      setState(() => _isSendingNotif = false);

                      if (result['success']) {
                        _notifTitleController.clear();
                        _notifMessageController.clear();
                        setState(() {
                          _notifSelectedUsers.clear();
                          _notifTarget          = 'all_customers';
                          _notifUserSearchQuery = '';
                        });
                      } else {
                        _showSnackBar(
                          result['message'] ?? 'Failed to send notification',
                          AdminDashboardStyles.errorColor,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: brownColor,
                disabledBackgroundColor: brownColor.withOpacity(0.5),
                padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSendingNotif
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'Send Notification',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                _notifTitleController.clear();
                _notifMessageController.clear();
                setState(() {
                  _notifSelectedUsers.clear();
                  _notifTarget          = 'all_customers';
                  _notifUserSearchQuery = '';
                });
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: brownColor, width: 1.5),
                padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Clear Form',
                style: TextStyle(
                  color: brownColor,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      color: beigeBackground,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: SingleChildScrollView(
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      formPanel,
                      const SizedBox(height: 20),
                      sidebarPanel,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: formPanel),
                      const SizedBox(width: 24),
                      sidebarPanel,
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      color: AdminDashboardStyles.backgroundColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 20 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Container(
              decoration: BoxDecoration(
                color: AdminDashboardStyles.surfaceColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preferences',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AdminDashboardStyles.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AdminDashboardStyles.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AdminDashboardStyles.dividerColor),
                    ),
                    child: Column(
                      children: [
                        _buildDropdownRow(
                          label: 'Language',
                          value: _language,
                          items: _languages,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _language = value);
                            }
                          },
                        ),
                        _buildDivider(),
                        _buildDropdownRow(
                          label: 'Theme',
                          value: _themeMode,
                          items: _themeModes,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _themeMode = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AdminDashboardStyles.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AdminDashboardStyles.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AdminDashboardStyles.dividerColor),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.lock_outline, color: AdminDashboardStyles.primaryColor),
                      title: const Text('Change password'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showChangePasswordDialog,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AdminDashboardStyles.textColor,
              ),
            ),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.keyboard_arrow_down, color: AdminDashboardStyles.textColor),
            items: items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(color: AdminDashboardStyles.textColor),
                    ),
                  ),
                )
                .toList(),
            onChanged: items.length > 1 ? onChanged : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Colors.transparent, height: 0);
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

  Widget _buildComplaintsView() {
    return Container(
      padding: AdminDashboardStyles.screenPadding,
      child: Column(
        children: [
          _buildComplaintFilter(),
          Expanded(child: _buildComplaintsList(_getFilteredComplaints())),
        ],
      ),
    );
  }

  Widget _buildComplaintFilter() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildComplaintFilterChip('All', 'all'),
          AdminDashboardStyles.hSpaceSmall,
          _buildComplaintFilterChip('Active', 'active'),
          AdminDashboardStyles.hSpaceSmall,
          _buildComplaintFilterChip('Completed', 'completed'),
          AdminDashboardStyles.hSpaceSmall,
          _buildComplaintFilterChip('Rejected', 'rejected'),
        ],
      ),
    );
  }

  Widget _buildComplaintFilterChip(String label, String value) {
    final isSelected = _complaintFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _complaintFilter = value;
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

  List<Map<String, dynamic>> _getFilteredComplaints() {
    final query = _searchController.text.toLowerCase();
    final normalizedComplaints = _complaints.where((complaint) {
      final status = (complaint['status'] ?? 'review').toString().toLowerCase();
      final matchesFilter = _complaintFilter == 'all'
          ? true
          : _complaintFilter == 'active'
              ? status == 'review' || status == 'active'
              : status == _complaintFilter;

      if (!matchesFilter) return false;
      if (query.isEmpty) return true;

      final customerName = (complaint['customer_name'] ?? '').toString().toLowerCase();
      final productName = (complaint['product_name'] ?? '').toString().toLowerCase();
      final issue = (complaint['issue'] ?? '').toString().toLowerCase();
      final description = (complaint['description'] ?? '').toString().toLowerCase();
      final type = (complaint['type'] ?? '').toString().toLowerCase();
      return customerName.contains(query) ||
          productName.contains(query) ||
          issue.contains(query) ||
          description.contains(query) ||
          type.contains(query);
    }).toList();

    final filteredComplaints = List<Map<String, dynamic>>.from(normalizedComplaints)
      ..sort((a, b) {
        final dateA = DateTime.tryParse((a['created_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse((b['created_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

    return filteredComplaints;
  }

  Widget _buildComplaintsList(List<Map<String, dynamic>> complaints) {
    if (complaints.isEmpty) {
      final query = _searchController.text.toLowerCase();
      final emptyMessage = query.isEmpty
          ? (_complaintFilter == 'all' ? 'No complaints yet' : 'No complaints match this filter')
          : 'No matching complaints';
      return _buildEmptyState(icon: Icons.feedback_outlined, message: emptyMessage);
    }

    return ListView.builder(
      itemCount: complaints.length,
      itemBuilder: (context, index) {
        final complaint = complaints[index];
        return _buildComplaintCard(
          complaint: complaint,
          onDetails: () => _showComplaintReviewDialog(complaint),
        );
      },
    );
  }

  Widget _buildComplaintCard({
    required Map<String, dynamic> complaint,
    VoidCallback? onDetails,
  }) {
    final complaintId = complaint['complaint_id']?.toString() ?? 'N/A';
    final productName = complaint['product_name']?.toString() ?? 'Unknown Product';
    final storeName = complaint['store_name']?.toString() ?? 'Unknown Store';
    final customerName = complaint['customer_name']?.toString() ?? 'Unknown Customer';
    final status = (complaint['status'] ?? 'review').toString().toLowerCase();
    final statusLabel = status == 'completed'
        ? 'Completed'
        : status == 'rejected'
            ? 'Rejected'
            : status == 'active'
                ? 'Active'
                : 'Review';

    Color statusColor = Colors.orange;
    if (status == 'completed') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;
    if (status == 'active') statusColor = Colors.blue;

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
                    color: AdminDashboardStyles.backgroundColor,
                  ),
                  child: Icon(
                    Icons.feedback_outlined,
                    color: AdminDashboardStyles.primaryColor,
                    size: 28,
                  ),
                ),
                AdminDashboardStyles.hSpaceLarge,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '#$complaintId • $productName',
                              style: AdminDashboardStyles.cardNameStyle.copyWith(
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                          Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 14,
                              color: AdminDashboardStyles.secondaryTextColor,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              customerName,
                              style: TextStyle(
                                fontSize: 14,
                                color: AdminDashboardStyles.secondaryTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
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
        ),
      ),
    );
  }

  Widget _buildComplaintMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EFE6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AdminDashboardStyles.primaryColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  List<String> _getComplaintImages(dynamic imagesData) {
    if (imagesData == null) return [];
    if (imagesData is List) {
      return imagesData.whereType<String>().where((item) => item.isNotEmpty).toList();
    }
    final raw = imagesData.toString().trim();
    if (raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().where((item) => item.isNotEmpty).toList();
      }
    } catch (_) {}
    return raw.split(',').where((item) => item.trim().isNotEmpty).toList();
  }

  Widget _buildComplaintImage(String? imageSource, {double width = 84, double height = 84}) {
    if (imageSource == null || imageSource.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF7EFE6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF704F38)),
      );
    }

    final normalized = imageSource.trim();
    if (normalized.startsWith('http')) {
      return Image.network(
        normalized,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFF7EFE6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.broken_image_outlined, color: Color(0xFF704F38)),
        ),
      );
    }

    try {
      final cleanBase64 = normalized.contains(',') ? normalized.split(',').last : normalized;
      return Image.memory(
        base64Decode(cleanBase64),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFF7EFE6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.broken_image_outlined, color: Color(0xFF704F38)),
        ),
      );
    } catch (_) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF7EFE6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF704F38)),
      );
    }
  }

  Future<void> _showComplaintPreviewDialog(Map<String, dynamic> complaint) async {
    final complaintId = int.tryParse(complaint['complaint_id'].toString());
    final brownColor = const Color(0xFF704F38);
    final beigeColor = const Color(0xFFF7EFE6);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final status = (complaint['status'] ?? 'review').toString().toLowerCase();
        final statusLabel = status == 'completed'
            ? 'Completed'
            : status == 'rejected'
                ? 'Rejected'
                : status == 'active'
                    ? 'Active'
                    : 'Review';

        final decision = (complaint['admin_decision'] ?? 'pending').toString().isNotEmpty
            ? complaint['admin_decision'].toString()
            : 'pending';
        final verification = (complaint['admin_verification'] ?? 'pending').toString().isNotEmpty
            ? complaint['admin_verification'].toString()
            : 'pending';

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: 520,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                  decoration: BoxDecoration(
                    color: brownColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_outlined, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Complaint Details',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildComplaintDetailRow('Complaint #', complaint['complaint_id']?.toString() ?? 'N/A'),
                        _buildComplaintDetailRow('Product', complaint['product_name']?.toString() ?? 'N/A'),
                        _buildComplaintDetailRow('Customer', complaint['customer_name']?.toString() ?? 'N/A'),
                        _buildComplaintDetailRow('Store', complaint['store_name']?.toString() ?? 'N/A'),
                        _buildComplaintDetailRow('Type', complaint['type']?.toString() ?? 'N/A'),
                        _buildComplaintDetailRow('Order #', complaint['order_id']?.toString() ?? 'N/A'),
                        _buildComplaintDetailRow('Status', statusLabel),
                        _buildComplaintDetailRow('Decision', decision.replaceAll('_', ' ').toUpperCase()),
                        _buildComplaintDetailRow('Verification', verification.replaceAll('_', ' ').toUpperCase()),
                        _buildComplaintDetailRow('Refund Amount', complaint['refund_amount']?.toString() ?? 'N/A'),
                        _buildComplaintDetailRow('Filed', _formatComplaintDate(complaint['created_at'])),
                        const SizedBox(height: 12),
                        Text('Issue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: brownColor)),
                        const SizedBox(height: 4),
                        Text(complaint['issue']?.toString() ?? 'No issue provided', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: brownColor)),
                        const SizedBox(height: 4),
                        Text(complaint['description']?.toString() ?? 'No description provided', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                        const SizedBox(height: 12),
                        Text('Admin Comment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: brownColor)),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: beigeColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (complaint['admin_comment'] ?? 'No comment yet').toString(),
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7EFE6),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(foregroundColor: brownColor),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: complaintId == null
                            ? null
                            : () async {
                                Navigator.of(dialogContext).pop();
                                await _showComplaintReviewDialog(complaint);
                              },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brownColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComplaintDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Future<void> _showComplaintReviewDialog(Map<String, dynamic> complaint) async {
    final complaintId = int.tryParse(complaint['complaint_id'].toString());
    if (complaintId == null) return;

    final draft = _complaintDrafts[complaintId] ?? {
      'status': (complaint['status'] ?? 'review').toString(),
      'admin_decision': (complaint['admin_decision'] ?? '').toString(),
      'admin_verification': (complaint['admin_verification'] ?? '').toString(),
      'admin_comment': (complaint['admin_comment'] ?? '').toString(),
      'refund_amount': (complaint['refund_amount'] ?? '0.00').toString(),
    };

    final commentController = _complaintCommentControllers.putIfAbsent(complaintId, () => TextEditingController());
    final refundController = _complaintRefundControllers.putIfAbsent(complaintId, () => TextEditingController());
    commentController.text = draft['admin_comment']?.toString() ?? '';
    refundController.text = draft['refund_amount']?.toString() ?? '0.00';

    _detailsDialogAnimationController.forward();

    await showDialog<void>(
      context: context,
      barrierColor: AdminDashboardStyles.dialogBarrierColor,
      barrierDismissible: true,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final isMobile = screenWidth < 768;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final complaintImages = _getComplaintImages(complaint['images']);
            final savedComplaintStatus = (complaint['status'] ?? '').toString().toLowerCase();
            final shouldLockFields = ['completed', 'rejected'].contains(savedComplaintStatus);
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
                      insetPadding: AdminDashboardStyles.dialogInsetPadding(isMobile, MediaQuery.of(dialogContext).size.width),
                      child: Container(
                        constraints: AdminDashboardStyles.dialogConstraints(isMobile, MediaQuery.of(dialogContext).size.height),
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
                                    child: const Icon(Icons.feedback, color: AdminDashboardStyles.surfaceColor, size: 28),
                                  ),
                                  AdminDashboardStyles.hSpaceLarge,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Complaint Review',
                                          style: AdminDashboardStyles.detailNameStyle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Review #${complaint['complaint_id'] ?? 'N/A'}',
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
                                    _buildSectionTitle('Complaint Information', Icons.info_outline),
                                    AdminDashboardStyles.vSpaceLarge,
                                    _buildDetailRow(Icons.inventory_2_outlined, 'Product', complaint['product_name']?.toString() ?? 'N/A'),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.person_outline, 'Customer', complaint['customer_name']?.toString() ?? 'Unknown Customer'),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.store_outlined, 'Store', complaint['store_name']?.toString() ?? 'Unknown Store'),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.warning_amber_rounded, 'Issue', complaint['issue']?.toString() ?? 'No issue provided'),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.description_outlined, 'Description', complaint['description']?.toString() ?? 'No description provided', isMultiline: true),
                                    if (complaintImages.isNotEmpty) ...[
                                      const SizedBox(height: 24),
                                      _buildSectionTitle('Evidence', Icons.image_outlined),
                                      AdminDashboardStyles.vSpaceMedium,
                                      SizedBox(
                                        height: 100,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: complaintImages.length,
                                          itemBuilder: (context, index) {
                                            final imageUrl = complaintImages[index];
                                            return Container(
                                              width: 100,
                                              margin: const EdgeInsets.only(right: 12),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: AdminDashboardStyles.secondaryTextColor.withOpacity(0.2)),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: _buildComplaintImage(imageUrl, width: 100, height: 100),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    _buildSectionTitle('Product Details', Icons.inventory_outlined),
                                    AdminDashboardStyles.vSpaceLarge,
                                    _buildDetailRow(Icons.label_outlined, 'Product Name', complaint['product_name']?.toString() ?? 'N/A'),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.tag_outlined, 'Category', complaint['product_category']?.toString() ?? 'N/A'),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.wc_outlined, 'Gender', complaint['product_gender']?.toString() ?? 'N/A'),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.currency_rupee_outlined, 'Product Price', 'Rs. ${complaint['product_price']?.toString() ?? 'N/A'}'),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.verified_outlined, 'Verified', (complaint['is_verified'] == 1 || complaint['is_verified'] == true) ? 'Yes' : 'No'),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.description_outlined, 'Product Description', complaint['product_description']?.toString() ?? 'No description available', isMultiline: true),
                                    const SizedBox(height: 24),
                                    _buildSectionTitle('Order Details', Icons.local_shipping_outlined),
                                    AdminDashboardStyles.vSpaceLarge,
                                    _buildDetailRow(Icons.numbers_outlined, 'Order #', complaint['order_id']?.toString() ?? 'N/A'),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.calendar_today_outlined, 'Order Date', _formatComplaintDate(complaint['order_date'] ?? complaint['created_at'])),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.info_outlined, 'Order Status', (complaint['order_status']?.toString() ?? 'N/A').toUpperCase()),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.currency_rupee_outlined, 'Order Total', 'Rs. ${complaint['total_price']?.toString() ?? 'N/A'}'),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.local_shipping_outlined, 'Shipping Type', (complaint['shipping_type']?.toString() ?? 'N/A').toUpperCase()),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.payment_outlined, 'Payment Method', complaint['payment_method']?.toString() ?? 'N/A'),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.phone_outlined, 'Contact Number', complaint['contact_number']?.toString() ?? 'N/A'),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.location_on_outlined, 'Shipping Address', complaint['shipping_address']?.toString() ?? 'N/A', isMultiline: true),
                                    const SizedBox(height: 24),
                                    _buildSectionTitle('Order Item Details', Icons.shopping_cart_outlined),
                                    AdminDashboardStyles.vSpaceLarge,
                                    _buildDetailRow(Icons.numbers_outlined, 'Quantity', complaint['order_quantity']?.toString() ?? 'N/A'),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.straighten_outlined, 'Size', complaint['order_size']?.toString() ?? 'N/A'),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.palette_outlined, 'Color', complaint['order_color']?.toString() ?? 'N/A'),
                                    AdminDashboardStyles.vSpaceMedium,
                                    _buildDetailRow(Icons.currency_rupee_outlined, 'Item Price', 'Rs. ${complaint['order_item_price']?.toString() ?? 'N/A'}'),
                                    const SizedBox(height: 24),
                                    _buildSectionTitle('Review Details', Icons.edit_outlined),
                                    AdminDashboardStyles.vSpaceLarge,
                                    DropdownButtonFormField<String>(
                                      value: (draft['status'] ?? 'review').toString(),
                                      onChanged: shouldLockFields ? null : (value) {
                                        setDialogState(() {
                                          draft['status'] = value ?? 'review';
                                          _complaintDrafts[complaintId] = {
                                            ...(_complaintDrafts[complaintId] ?? {}),
                                            'status': value ?? 'review',
                                          };
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Status',
                                        filled: true,
                                        fillColor: AdminDashboardStyles.backgroundColor,
                                        labelStyle: TextStyle(color: AdminDashboardStyles.primaryColor),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AdminDashboardStyles.primaryColor.withOpacity(0.25)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AdminDashboardStyles.primaryColor.withOpacity(0.25)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AdminDashboardStyles.primaryColor, width: 2),
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'review', child: Text('Review')),
                                        DropdownMenuItem(value: 'active', child: Text('Active')),
                                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                                        DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      value: (draft['admin_decision'] ?? 'pending').toString().isNotEmpty ? (draft['admin_decision'] ?? 'pending').toString() : 'pending',
                                      onChanged: shouldLockFields ? null : (value) {
                                        setDialogState(() {
                                          draft['admin_decision'] = value ?? 'pending';
                                          _complaintDrafts[complaintId] = {
                                            ...(_complaintDrafts[complaintId] ?? {}),
                                            'admin_decision': value ?? 'pending',
                                          };
                                          _complaintValidationErrors[complaintId] = null;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Decision',
                                        filled: true,
                                        fillColor: AdminDashboardStyles.backgroundColor,
                                        labelStyle: TextStyle(color: AdminDashboardStyles.primaryColor),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AdminDashboardStyles.primaryColor.withOpacity(0.25)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AdminDashboardStyles.primaryColor.withOpacity(0.25)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AdminDashboardStyles.primaryColor, width: 2),
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                        DropdownMenuItem(value: 'full_refund', child: Text('Full Refund')),
                                        DropdownMenuItem(value: 'half_refund', child: Text('Half Refund')),
                                        DropdownMenuItem(value: 'no_refund', child: Text('No Refund')),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      value: (draft['admin_verification'] ?? 'pending').toString().isNotEmpty ? (draft['admin_verification'] ?? 'pending').toString() : 'pending',
                                      onChanged: shouldLockFields ? null : (value) {
                                        setDialogState(() {
                                          draft['admin_verification'] = value ?? 'pending';
                                          _complaintDrafts[complaintId] = {
                                            ...(_complaintDrafts[complaintId] ?? {}),
                                            'admin_verification': value ?? 'pending',
                                          };
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Verification',
                                        filled: true,
                                        fillColor: AdminDashboardStyles.backgroundColor,
                                        labelStyle: TextStyle(color: AdminDashboardStyles.primaryColor),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AdminDashboardStyles.primaryColor.withOpacity(0.25)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AdminDashboardStyles.primaryColor.withOpacity(0.25)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AdminDashboardStyles.primaryColor, width: 2),
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                        DropdownMenuItem(value: 'verified_by_seller', child: Text('Verified by Seller')),
                                        DropdownMenuItem(value: 'verified_by_images', child: Text('Verified by Images')),
                                        DropdownMenuItem(value: 'not_verified', child: Text('Not Verified')),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: commentController,
                                      maxLines: 4,
                                      enabled: !shouldLockFields,
                                      readOnly: shouldLockFields,
                                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z\s.,]'))],
                                      decoration: InputDecoration(
                                        labelText: 'Admin Comment',
                                        filled: true,
                                        fillColor: AdminDashboardStyles.backgroundColor,
                                        labelStyle: TextStyle(color: AdminDashboardStyles.primaryColor),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AdminDashboardStyles.primaryColor.withOpacity(0.25)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AdminDashboardStyles.primaryColor.withOpacity(0.25)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AdminDashboardStyles.primaryColor, width: 2),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setDialogState(() {
                                          draft['admin_comment'] = value;
                                          _complaintDrafts[complaintId] = {
                                            ...(_complaintDrafts[complaintId] ?? {}),
                                            'admin_comment': value,
                                          };
                                          _complaintValidationErrors[complaintId] = null;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: refundController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      enabled: !shouldLockFields,
                                      readOnly: shouldLockFields,
                                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                      decoration: InputDecoration(
                                        labelText: 'Refund Amount',
                                        filled: true,
                                        fillColor: AdminDashboardStyles.backgroundColor,
                                        labelStyle: TextStyle(color: AdminDashboardStyles.primaryColor),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AdminDashboardStyles.primaryColor.withOpacity(0.25)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AdminDashboardStyles.primaryColor.withOpacity(0.25)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AdminDashboardStyles.primaryColor, width: 2),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setDialogState(() {
                                          draft['refund_amount'] = value;
                                          _complaintDrafts[complaintId] = {
                                            ...(_complaintDrafts[complaintId] ?? {}),
                                            'refund_amount': value,
                                          };
                                          _complaintValidationErrors[complaintId] = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_complaintValidationErrors[complaintId] != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _complaintValidationErrors[complaintId]!,
                                              style: TextStyle(color: Colors.red.shade700, fontSize: 12.5, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (shouldLockFields)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.amber.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.lock_outline, color: Colors.amber.shade800, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'This complaint has been finalized and the review fields are locked.',
                                              style: TextStyle(color: Colors.amber.shade800, fontSize: 12.5, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => Navigator.of(dialogContext).pop(),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                          side: BorderSide(color: AdminDashboardStyles.primaryColor, width: 1.2),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(color: AdminDashboardStyles.primaryColor, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: shouldLockFields
                                            ? null
                                            : () async {
                                                final validationError = _validateComplaintDraft(complaintId, draft);
                                                if (validationError != null) {
                                                  setDialogState(() {
                                                    _complaintValidationErrors[complaintId] = validationError;
                                                  });
                                                  return;
                                                }

                                                final success = await _saveComplaint(complaintId);
                                                if (success && mounted) {
                                                  Navigator.of(dialogContext).pop();
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AdminDashboardStyles.primaryColor,
                                          foregroundColor: AdminDashboardStyles.surfaceColor,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: Text(shouldLockFields ? 'Locked' : 'Save'),
                                      ),
                                    ],
                                  ),
                                ],
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
        );
      },
    ).then((_) {
      _detailsDialogAnimationController.reset();
    });
  }

  String? _validateComplaintDraft(int complaintId, Map<String, dynamic> draft) {
    final refundText = (draft['refund_amount'] ?? '').toString().trim();
    if (refundText.isNotEmpty) {
      final refundValue = double.tryParse(refundText);
      if (refundValue == null || refundValue < 0) {
        return 'Refund amount must be a valid non-negative number.';
      }
    }

    final comment = (draft['admin_comment'] ?? '').toString().trim();
    if (comment.isNotEmpty) {
      if (!RegExp(r'^[A-Za-z0-9\s.,]+$').hasMatch(comment)) {
        return 'Admin comment can only contain letters, numbers, spaces, commas, and dots.';
      }

      final wordCount = comment.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).length;
      if (wordCount >= 50) {
        return 'Admin comment must be less than 50 words.';
      }
    }

    _complaintValidationErrors[complaintId] = null;
    return null;
  }

  Future<bool> _saveComplaint(int complaintId) async {
    final draft = _complaintDrafts[complaintId];
    if (draft == null) return false;

    if (mounted) {
      setState(() {
        _savingComplaintIds[complaintId] = true;
      });
    }

    final refundText = (draft['refund_amount'] ?? '').toString().trim();
    final normalizedRefundText = refundText.isEmpty ? '0.00' : refundText;

    final result = await ApiService.updateComplaintStatus(
      complaintId: complaintId,
      status: draft['status']?.toString() ?? 'review',
      adminDecision: draft['admin_decision']?.toString(),
      adminVerification: draft['admin_verification']?.toString(),
      adminComment: draft['admin_comment']?.toString(),
      refundAmount: double.tryParse(normalizedRefundText),
    );

    bool success = false;
    if (mounted) {
      if (result['success']) {
        setState(() {
          final index = _complaints.indexWhere((complaint) => int.tryParse(complaint['complaint_id'].toString()) == complaintId);
          if (index != -1) {
            _complaints[index]['status'] = draft['status']?.toString() ?? 'review';
            _complaints[index]['admin_decision'] = draft['admin_decision']?.toString() ?? '';
            _complaints[index]['admin_verification'] = draft['admin_verification']?.toString() ?? '';
            _complaints[index]['admin_comment'] = draft['admin_comment']?.toString() ?? '';
            _complaints[index]['refund_amount'] = draft['refund_amount']?.toString() ?? '0.00';
          }

          if (['completed', 'rejected'].contains((draft['status'] ?? '').toString().toLowerCase())) {
            _complaintDrafts[complaintId] = {
              ...draft,
              'status': draft['status']?.toString() ?? 'review',
            };
          }
        });
        _showSnackBar('Complaint updated', Colors.green);
        success = true;
      } else {
        _showSnackBar(result['message'] ?? 'Failed to update complaint', AdminDashboardStyles.errorColor);
      }
    }

    if (mounted) {
      setState(() {
        _savingComplaintIds[complaintId] = false;
      });
    }

    return success;
  }

  String _formatComplaintDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return date.toString();
    }
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
