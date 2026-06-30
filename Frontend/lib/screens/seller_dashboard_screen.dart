import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'sign_in_screen.dart';
import '../widgets/custom_snackbar.dart';
import '../styles/seller_dashboard_styles.dart';
import '../styles/profile_styles.dart';
import '../services/socket_service.dart';
import 'chat_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  final String sellerName;
  final int? userId;

  const SellerDashboardScreen({
    super.key,
    required this.sellerName,
    this.userId,
  });

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen>
    with TickerProviderStateMixin {
  final TextEditingController _editStoreNameController =
      TextEditingController();
  final TextEditingController _editBioController = TextEditingController();
  final TextEditingController _editWebsiteController = TextEditingController();
  final TextEditingController _editInstagramController =
      TextEditingController();

  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editContactController = TextEditingController();
  final TextEditingController _editCnicController = TextEditingController();
  final TextEditingController _editAddressController = TextEditingController();

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final Color brownColor = const Color(0xFF704F38);
  final Color lightGray = const Color(0xFF797979);
  final Color darkText = const Color(0xFF000000);
  final Color whiteColor = Colors.white;
  final Color beigeBackground = const Color(0xFFF5F1EB);

  String? _editStoreNameError;
  String? _editBioError;
  String? _editWebsiteError;
  String? _editInstagramError;
  String? _editNameError;
  String? _editContactError;
  String? _editCnicError;
  String? _editAddressError;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  int _selectedTab = 0;
  bool _isLoading = false;
  bool _isSidebarHovered = true;
  bool _isProductsExpanded = false;
  bool _isOrdersExpanded = false;
  bool _isPromotionsExpanded = false;

  String _productSubTab = 'approved';

  String _orderSubTab = 'pending';

  String _promotionSubTab = 'active';

  Map<String, dynamic>? _storeInfo;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _notifications = [];
  List<dynamic> _chats = [];
  String _complaintFilter = 'all';

  double _storeWalletTotalBalance = 0.0;
  int _storeWalletCustomerCount = 0;
  List<Map<String, dynamic>> _storeWalletTransactions = [];

  int get _unreadNotificationCount {
    return _notifications.where((notification) {
      final status = notification['is_read'];
      return status != 1 && status != '1';
    }).length;
  }

  int get _unreadMessageCount {
    var count = 0;
    for (final chat in _chats) {
      if (chat is! Map) continue;
      final isMe = chat['last_message_sender_id'] == widget.userId;
      final unreadValue = chat['unread_count'];
      final unreadCount = unreadValue is int
          ? unreadValue
          : unreadValue is String
          ? int.tryParse(unreadValue) ?? 0
          : 0;
      final hasUnread = !isMe && unreadCount > 0;
      if (!hasUnread) continue;

      count += unreadCount > 0 ? unreadCount : 1;
    }
    return count;
  }

  String? _storeLogoPath;
  final TextEditingController _searchController = TextEditingController();

  static const int _notificationsTabIndex = 4;
  static const int _messagesTabIndex = 3;
  static const int _settingsTabIndex = 6;
  static const int _complaintsTabIndex = 8;
  static const int _transactionsTabIndex = 9;

  String _language = 'English';
  String _themeMode = 'Light';
  final List<String> _languages = ['English'];
  final List<String> _themeModes = ['Light'];

  final TextEditingController _productNameController = TextEditingController();

  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  int _currentStep = 0;
  List<Map<String, dynamic>> _variants = [];

  final TextEditingController _variantSizeController = TextEditingController();
  final TextEditingController _variantColorController = TextEditingController();
  final TextEditingController _variantPriceController = TextEditingController();

  final TextEditingController _variantStockController = TextEditingController();

  String? _selectedVariantSize;
  String? _selectedVariantColor;
  final GlobalKey _variantSizeFieldKey = GlobalKey();
  final GlobalKey _variantColorFieldKey = GlobalKey();

  String? _selectedCategory;
  String? _selectedGender;
  List<String> _productImages = [];

  String? _productNameError;

  String? _categoryError;
  String? _genderError;
  String? _priceError;
  String? _descriptionError;
  String? _imageError;

  String? _variantSizeError;
  String? _variantColorError;
  String? _variantPriceError;
  String? _variantStockError;

  bool _isEditing = false;
  int? _editingProductId;

  final GlobalKey _categoryFieldKey = GlobalKey();
  final GlobalKey _genderFieldKey = GlobalKey();

  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _promotionTitleController =
      TextEditingController();
  final TextEditingController _promotionDiscountController =
      TextEditingController();
  final TextEditingController _promotionStartDateController =
      TextEditingController();
  final TextEditingController _promotionEndDateController =
      TextEditingController();

  List<Map<String, dynamic>> _promotions = [];
  bool _isPromotionsLoading = false;
  List<int> _selectedProductIds = [];
  String? _promotionTitleError;
  String? _promotionDiscountError;
  String? _promotionStartDateError;
  String? _promotionEndDateError;
  String? _productsError;
  bool _isEditingPromotion = false;
  int? _editingPromotionId;
  // Promotion product filters
  String _promotionCategoryFilter = 'all';

  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.dashboard_outlined,
      'activeIcon': Icons.dashboard,
      'label': 'Dashboard',
      'index': 0,
    },
    {
      'icon': Icons.inventory_2_outlined,
      'activeIcon': Icons.inventory_2,
      'label': 'Products',
      'index': 1,
    },
    {
      'icon': Icons.shopping_bag_outlined,
      'activeIcon': Icons.shopping_bag,
      'label': 'Orders',
      'index': 2,
    },
    {
      'icon': Icons.receipt_long_outlined,
      'activeIcon': Icons.receipt_long,
      'label': 'Transactions',
      'index': _transactionsTabIndex,
    },
    {
      'icon': Icons.chat_outlined,
      'activeIcon': Icons.chat,
      'label': 'Messages',
      'index': 3,
    },
    {
      'icon': Icons.feedback_outlined,
      'activeIcon': Icons.feedback,
      'label': 'Complaints',
      'index': _complaintsTabIndex,
    },
    {
      'icon': Icons.campaign_outlined,
      'activeIcon': Icons.campaign,
      'label': 'Promotions',
      'index': 7,
    },
  ];

  final List<Map<String, dynamic>> _bottomNavItems = [
    {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
    {
      'icon': Icons.inventory_2_outlined,
      'activeIcon': Icons.inventory_2,
      'label': 'Products',
    },
    {
      'icon': Icons.shopping_bag_outlined,
      'activeIcon': Icons.shopping_bag,
      'label': 'Orders',
    },
    {
      'icon': Icons.chat_outlined,
      'activeIcon': Icons.chat,
      'label': 'Messages',
    },
    {
      'icon': Icons.notifications_none_outlined,
      'activeIcon': Icons.notifications,
      'label': 'Notifications',
    },
    {
      'icon': Icons.person_outline,
      'activeIcon': Icons.person,
      'label': 'Profile',
    },
    {
      'icon': Icons.settings_outlined,
      'activeIcon': Icons.settings,
      'label': 'Settings',
    },
  ];

  late AnimationController _logoutDialogAnimationController;
  late Animation<double> _logoutDialogScaleAnimation;
  late Animation<double> _logoutDialogFadeAnimation;

  late AnimationController _deleteProfileDialogAnimationController;
  late Animation<double> _deleteProfileDialogScaleAnimation;
  late Animation<double> _deleteProfileDialogFadeAnimation;

  late AnimationController _detailsDialogAnimationController;
  late Animation<double> _detailsDialogScaleAnimation;
  late Animation<double> _detailsDialogFadeAnimation;

  late AnimationController _deleteDialogAnimationController;
  late Animation<double> _deleteDialogScaleAnimation;
  late Animation<double> _deleteDialogFadeAnimation;

  late AnimationController _activeOrdersDialogAnimationController;
  late Animation<double> _activeOrdersDialogScaleAnimation;
  late Animation<double> _activeOrdersDialogFadeAnimation;

  @override
  void initState() {
    super.initState();
    _deleteProfileDialogAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _deleteProfileDialogScaleAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(
          CurvedAnimation(
            parent: _deleteProfileDialogAnimationController,
            curve: Curves.easeOutBack,
          ),
        );
    _deleteProfileDialogFadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(
          CurvedAnimation(
            parent: _deleteProfileDialogAnimationController,
            curve: Curves.easeIn,
          ),
        );

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

    _detailsDialogAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _detailsDialogScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _detailsDialogAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _detailsDialogFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _detailsDialogAnimationController,
        curve: Curves.easeIn,
      ),
    );

    _deleteDialogAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _deleteDialogScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _deleteDialogAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _deleteDialogFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _deleteDialogAnimationController,
        curve: Curves.easeIn,
      ),
    );

    _activeOrdersDialogAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _activeOrdersDialogScaleAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(
          CurvedAnimation(
            parent: _activeOrdersDialogAnimationController,
            curve: Curves.elasticOut,
          ),
        );

    _activeOrdersDialogFadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(
          CurvedAnimation(
            parent: _activeOrdersDialogAnimationController,
            curve: Curves.easeIn,
          ),
        );

    _loadStoreInfo();
    _loadData().then((_) {
      _loadNotifications();
      _loadChats();
      _loadComplaints();
    });
    _setupSocketListener();
  }

  void _setupSocketListener() {}

  @override
  void dispose() {
    _searchController.dispose();
    _productNameController.dispose();
    _minPriceController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _genderController.dispose();

    _variantSizeController.dispose();
    _variantColorController.dispose();
    _variantPriceController.dispose();
    _variantStockController.dispose();

    _editStoreNameController.dispose();
    _editBioController.dispose();
    _editWebsiteController.dispose();
    _editInstagramController.dispose();
    _editNameController.dispose();
    _editContactController.dispose();
    _editCnicController.dispose();
    _editAddressController.dispose();

    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    _logoutDialogAnimationController.dispose();
    _deleteProfileDialogAnimationController.dispose();
    _detailsDialogAnimationController.dispose();
    _deleteDialogAnimationController.dispose();
    _activeOrdersDialogAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _validateStoreName(String value) {
    if (value.trim().isEmpty) {
      _editStoreNameError = 'Store name is required';
      return false;
    }
    if (value.trim().length < 2) {
      _editStoreNameError = 'Min 2 characters';
      return false;
    }
    _editStoreNameError = null;
    return true;
  }

  bool _validateBio(String value) {
    if (value.trim().isEmpty) {
      _editBioError = 'Bio is required';
      return false;
    }
    if (value.trim().length < 10) {
      _editBioError = 'Min 10 characters';
      return false;
    }
    _editBioError = null;
    return true;
  }

  bool _validateWebsite(String value) {
    if (value.trim().isEmpty) {
      _editWebsiteError = null;
      return true;
    }
    final urlRegex = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');
    if (!urlRegex.hasMatch(value.trim())) {
      _editWebsiteError = 'Invalid URL (e.g., https://abc.com)';
      return false;
    }
    _editWebsiteError = null;
    return true;
  }

  bool _validateInstagram(String value) {
    if (value.trim().isEmpty) {
      _editInstagramError = null;
      return true;
    }
    final valueTrim = value.trim();
    if (!valueTrim.startsWith('@') || valueTrim.length < 2) {
      _editInstagramError = 'Must start with @';
      return false;
    }
    _editInstagramError = null;
    return true;
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
    if (value.trim().length != 11 ||
        !RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
      _editContactError = 'Must be 11 digits';
      return false;
    }
    _editContactError = null;
    return true;
  }

  bool _validateCNIC(String value) {
    if (value.trim().isEmpty) {
      _editCnicError = 'CNIC is required';
      return false;
    }
    if (value.trim().length != 13 ||
        !RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
      _editCnicError = 'Must be 13 digits';
      return false;
    }
    _editCnicError = null;
    return true;
  }

  bool _validateAddress(String value) {
    if (value.trim().isEmpty) {
      _editAddressError = 'Address is required';
      return false;
    }
    if (value.trim().length < 10) {
      _editAddressError = 'Min 10 characters';
      return false;
    }
    _editAddressError = null;
    return true;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    if (_selectedTab == 0) {
      await Future.wait([_loadStoreInfo(), _loadProducts(), _loadOrders()]);
    } else if (_selectedTab == 1) {
      await _loadProducts();
    } else if (_selectedTab == 3) {
      await _loadChats();
    } else if (_selectedTab == _complaintsTabIndex) {
      await _loadComplaints();
    } else if (_selectedTab == 5) {
      await Future.wait([_loadStoreInfo(), _loadUserData()]);
    } else if (_selectedTab == 7) {
      await Future.wait([_loadStoreInfo(), _loadProducts(), _loadPromotions()]);
    } else if (_selectedTab == _transactionsTabIndex) {
      await Future.wait([_loadStoreInfo(), _loadStoreWalletData()]);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadUserData() async {
    if (widget.userId == null) return;
    try {
      final result = await ApiService.getUserById(widget.userId!);
      if (result['success'] && result['data'] != null) {
        setState(() {
          _userData = result['data'] as Map<String, dynamic>;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadStoreInfo() async {
    if (widget.userId == null) {
      setState(() {
        _storeInfo = null;
        _storeLogoPath = null;
      });
      return;
    }

    try {
      final result = await ApiService.getStoreInfo(widget.userId!);
      if (result['success'] && result['data'] != null) {
        final storeData = result['data'] as Map<String, dynamic>;

        String? logoPath;
        if (storeData.containsKey('logo') && storeData['logo'] != null) {
          logoPath = storeData['logo'].toString();
        } else if (storeData.containsKey('logo_url') &&
            storeData['logo_url'] != null) {
          logoPath = storeData['logo_url'].toString();
        } else if (storeData.containsKey('logo_path') &&
            storeData['logo_path'] != null) {
          logoPath = storeData['logo_path'].toString();
        } else if (storeData.containsKey('store_logo') &&
            storeData['store_logo'] != null) {
          logoPath = storeData['store_logo'].toString();
        } else if (storeData.containsKey('image') &&
            storeData['image'] != null) {
          logoPath = storeData['image'].toString();
        } else if (storeData.containsKey('image_url') &&
            storeData['image_url'] != null) {
          logoPath = storeData['image_url'].toString();
        } else if (storeData.containsKey('store_image') &&
            storeData['store_image'] != null) {
          logoPath = storeData['store_image'].toString();
        }

        setState(() {
          _storeInfo = storeData;
          _storeLogoPath = logoPath?.isNotEmpty == true ? logoPath : null;
        });
      } else {
        setState(() {
          _storeInfo = null;
          _storeLogoPath = null;
        });
      }
    } catch (e) {
      setState(() {
        _storeInfo = null;
        _storeLogoPath = null;
      });
    }
  }

  Future<void> _loadStoreWalletData() async {
    if (widget.userId == null) return;

    try {
      final result = await ApiService.getStoreWalletData(widget.userId!);
      if (result['success'] && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        setState(() {
          _storeWalletTotalBalance =
              double.tryParse(data['total_balance']?.toString() ?? '0') ?? 0.0;
          _storeWalletCustomerCount =
              int.tryParse(data['customer_count']?.toString() ?? '0') ?? 0;
          _storeWalletTransactions =
              (data['transactions'] as List<dynamic>?)?.map((tx) {
                    final item = tx as Map<String, dynamic>;
                    final rawAmount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
                    final methodStr = item['method']?.toString() ?? '';

                    // If payment involved wallet credits, method contains 'Wallet Rs. <amount>'
                    double walletPortion = 0.0;
                    try {
                      final m = RegExp(r'Wallet\s*Rs\.?\s*([0-9]+(?:\.[0-9]+)?)', caseSensitive: false).firstMatch(methodStr);
                      if (m != null) walletPortion = double.tryParse(m.group(1) ?? '0') ?? 0.0;
                    } catch (_) {
                      walletPortion = 0.0;
                    }

                    // Adjust displayed amount for credits that include wallet usage
                    double displayedAmount = rawAmount;
                    if ((item['type'] ?? 'debit') == 'credit' && walletPortion > 0) {
                      displayedAmount = (rawAmount - walletPortion).clamp(0.0, double.infinity);
                    }

                    return {
                      'type': item['type'] ?? 'debit',
                      'amount': displayedAmount,
                      'raw_amount': rawAmount,
                      'wallet_portion': walletPortion,
                      'description': item['description'] ?? 'Transaction',
                      'method': methodStr,
                      'timestamp': item['timestamp'] ?? DateTime.now().toIso8601String(),
                    };
                  }).toList() ??
                  [];
        });
      } else {
        setState(() {
          _storeWalletTotalBalance = 0.0;
          _storeWalletCustomerCount = 0;
          _storeWalletTransactions = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Unable to load transactions')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _storeWalletTotalBalance = 0.0;
        _storeWalletCustomerCount = 0;
        _storeWalletTransactions = [];
      });
    }
  }

  Future<void> _loadOrders() async {
    if (widget.userId == null) {
      setState(() {
        _orders = [];
      });
      return;
    }

    try {
      final result = await ApiService.getSellerOrders(widget.userId!);
      if (result['success']) {
        final List<Map<String, dynamic>> rawOrders =
            List<Map<String, dynamic>>.from(result['data'] ?? []);

        rawOrders.sort((a, b) {
          final idA = int.tryParse(a['id'].toString()) ?? 0;
          final idB = int.tryParse(b['id'].toString()) ?? 0;
          return idB.compareTo(idA);
        });

        setState(() {
          _orders = rawOrders;
        });

        // Enrich orders with payment details (wallet_amount, payment_method) by fetching order details
        for (var o in rawOrders) {
          try {
            final id = int.tryParse(o['id']?.toString() ?? o['order_id']?.toString() ?? '') ?? 0;
            if (id == 0) continue;
            final detailsRes = await ApiService.getOrderDetails(id);
            if (detailsRes['success'] && detailsRes['data'] != null) {
              final od = detailsRes['data'] as Map<String, dynamic>;
              // Attach known keys if present
              if (od.containsKey('wallet_amount')) o['wallet_amount'] = od['wallet_amount'];
              if (od.containsKey('payment_method')) o['payment_method'] = od['payment_method'];
              if (od.containsKey('cash_amount')) o['cash_amount'] = od['cash_amount'];
            }
          } catch (_) {}
        }
        // Refresh state after enrichment
        setState(() {
          _orders = rawOrders;
        });
      } else {
        setState(() {
          _orders = [];
        });
      }
    } catch (e) {
      setState(() {
        _orders = [];
      });
    }
  }

  Future<void> _loadProducts() async {
    if (widget.userId == null) {
      setState(() {
        _products = [];
      });
      return;
    }

    try {
      final storeResult = await ApiService.getStoreInfo(widget.userId!);

      if (!storeResult['success'] || storeResult['data'] == null) {
        setState(() {
          _products = [];
        });
        return;
      }

      final storeData = storeResult['data'] as Map<String, dynamic>;

      final storeId =
          storeData['store_id'] ??
          storeData['store_Id'] ??
          storeData['Store_Id'] ??
          storeData['storeId'] ??
          storeData['id'] ??
          storeData['Id'];

      if (storeId == null) {
        setState(() {
          _products = [];
        });
        return;
      }

      final productsResult = await ApiService.getStoreProducts(
        storeId,
        role: 'seller',
      );

      if (productsResult['success'] && productsResult['data'] != null) {
        final productsList = productsResult['data'] as List<dynamic>;

        final mappedProducts = productsList
            .map((p) => p as Map<String, dynamic>)
            .toList();

        setState(() {
          _products = mappedProducts;
        });
      } else {
        setState(() {
          _products = [];
        });
      }
    } catch (e) {
      setState(() {
        _products = [];
      });
    }
  }

  Future<void> _loadComplaints() async {
    if (widget.userId == null) {
      setState(() {
        _complaints = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final storeResult = await ApiService.getStoreInfo(widget.userId!);
      int? storeId;
      if (storeResult['success'] && storeResult['data'] != null) {
        final storeData = storeResult['data'] as Map<String, dynamic>;
        storeId = int.tryParse(
          (storeData['store_id'] ??
                  storeData['store_Id'] ??
                  storeData['storeId'] ??
                  storeData['id'] ??
                  '')
              .toString(),
        );
      }

      final sellerResult = await ApiService.getSellerComplaints(widget.userId!);
      if (sellerResult['success'] && sellerResult['data'] != null) {
        final complaints = List<Map<String, dynamic>>.from(
          sellerResult['data'] ?? [],
        );
        setState(() {
          _complaints = complaints;
        });
      } else if (storeId != null) {
        final adminResult = await ApiService.getAllComplaints();
        if (adminResult['success'] && adminResult['data'] != null) {
          final complaints = (adminResult['data'] as List<dynamic>)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .where((complaint) {
                final complaintStoreId = complaint['store_id'];
                return complaintStoreId != null &&
                    int.tryParse(complaintStoreId.toString()) == storeId;
              })
              .toList();
          setState(() {
            _complaints = complaints;
          });
        } else {
          setState(() {
            _complaints = [];
          });
        }
      } else {
        setState(() {
          _complaints = [];
        });
      }
    } catch (e) {
      setState(() {
        _complaints = [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPromotions() async {
    if (widget.userId == null) return;
    try {
      final storeResult = await ApiService.getStoreInfo(widget.userId!);
      if (!storeResult['success'] || storeResult['data'] == null) return;

      final storeData = storeResult['data'] as Map<String, dynamic>;
      final storeId =
          storeData['store_id'] ??
          storeData['store_Id'] ??
          storeData['storeId'] ??
          storeData['id'];

      if (storeId == null) return;

      setState(() {
        _isPromotionsLoading = true;
      });

      final promotionsResult = await ApiService.getStorePromotions(storeId);
      if (promotionsResult['success'] && promotionsResult['data'] != null) {
        final list = promotionsResult['data'] as List<dynamic>;
        setState(() {
          _promotions = list.map((p) => p as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      print('Error loading promotions: $e');
    } finally {
      setState(() {
        _isPromotionsLoading = false;
      });
    }
  }

  Future<void> _loadNotifications() async {
    if (widget.userId == null) return;

    setState(() => _isLoading = true);

    final result = await ApiService.getUserNotifications(widget.userId!);
    if (result['success']) {
      final responseData = result['data'];
      List<Map<String, dynamic>> notifications = [];

      if (responseData is List) {
        notifications = responseData
            .map((notification) {
              if (notification is Map<String, dynamic>) {
                return notification;
              } else if (notification is Map) {
                return Map<String, dynamic>.from(notification);
              }
              return <String, dynamic>{};
            })
            .where((notification) => notification.isNotEmpty)
            .toList();
      }

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } else {
      final errorMessage = result['message'] ?? 'Failed to load notifications';
      if (mounted) {
        _showSnackBar(errorMessage, Colors.red);
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChats() async {
    if (widget.userId == null) return;

    setState(() => _isLoading = true);

    final result = await ApiService.getChatInbox(widget.userId!);
    if (result['success']) {
      setState(() {
        _chats = result['data'] ?? [];
        _isLoading = false;
      });
    } else {
      final errorMessage = result['message'] ?? 'Failed to load messages';
      if (mounted) {
        _showSnackBar(errorMessage, Colors.red);
      }
      setState(() => _isLoading = false);
    }
  }

  void _onTabChanged(int index) {
    if (index == _notificationsTabIndex) {
      if (_selectedTab != _notificationsTabIndex) {
        setState(() {
          _selectedTab = index;
        });
        _loadNotifications();
      }
      return;
    }

    if (index == _settingsTabIndex) {
      setState(() {
        _selectedTab = index;
      });
      return;
    }

    if (index == _complaintsTabIndex) {
      setState(() {
        _selectedTab = index;
      });
      _loadComplaints();
      return;
    }

    _searchController.clear();
    setState(() {
      _selectedTab = index;

      if (index != 1) {
        _productSubTab = 'approved';
      } else {
        _isProductsExpanded = true;
      }

      if (index != 2) {
        _orderSubTab = 'pending';
      } else {
        _isOrdersExpanded = true;
      }

      if (index != 7) {
        _promotionSubTab = 'active';
      } else {
        _isPromotionsExpanded = true;
      }
    });

    if (index == 3) {
      _loadChats();
    } else {
      _loadData();
    }
  }

  void _onProductSubTabChanged(String subTab) {
    bool tabChanged = _selectedTab != 1;

    setState(() {
      _selectedTab = 1;
      _isProductsExpanded = true;

      if (_isEditing && (subTab != 'add' || subTab == 'add')) {
        _isEditing = false;
        _editingProductId = null;
        _productNameController.clear();

        _minPriceController.clear();
        _descriptionController.clear();
        _selectedCategory = null;
        _selectedGender = null;
        _productImages.clear();
        _currentStep = 0;
        _variants.clear();
        _variantSizeController.clear();
        _variantColorController.clear();
        _variantPriceController.clear();
        _variantStockController.clear();
        _selectedVariantSize = null;
        _selectedVariantColor = null;
      }

      _productSubTab = subTab;
    });

    if (tabChanged) {
      _loadData();
    } else if (subTab != 'add') {
      _loadProducts();
    }
  }

  Future<void> _pickStoreLogo() async {
    if (widget.userId == null || _storeInfo?['store_id'] == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
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
        final logoData = 'data:$mimeType;base64,${base64Encode(bytes)}';

        final result = await ApiService.updateStoreInfo(
          storeId: int.parse(_storeInfo!['store_id'].toString()),
          storeName: _storeInfo!['store_name']?.toString() ?? '',
          bio: _storeInfo!['bio']?.toString() ?? '',
          website: _storeInfo!['website']?.toString(),
          instagram: _storeInfo!['instagram']?.toString(),
          logo: logoData,
        );

        if (result['success']) {
          if (result['requires_reverification'] == true) {
            _showReverificationNotice();
          } else {
            await _loadStoreInfo();
          }
        } else {
          _showSnackBar(
            result['message'] ?? 'Failed to update store logo',
            Colors.red,
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking store logo: $e');
      _showSnackBar('Failed to pick logo', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onOrderSubTabChanged(String subTab) {
    bool tabChanged = _selectedTab != 2;

    setState(() {
      _selectedTab = 2;
      _isOrdersExpanded = true;
      _orderSubTab = subTab;
    });

    if (tabChanged) {
      _loadData();
    }
  }

  void _onPromotionSubTabChanged(String subTab) {
    bool tabChanged = _selectedTab != 7;

    setState(() {
      _selectedTab = 7;
      _isPromotionsExpanded = true;
      _promotionSubTab = subTab;
    });

    if (tabChanged) {
      _loadData();
    }
  }

  bool _validateProductName() {
    final name = _productNameController.text.trim();
    if (name.isEmpty) {
      _productNameError = 'Product name is required';
      return false;
    }

    final letterCount = name.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (letterCount < 5 || letterCount > 20) {
      _productNameError = 'Product name must be 5-20 letters';
      return false;
    }
    _productNameError = null;
    return true;
  }

  bool _validateCategory() {
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      _categoryError = 'Category must be selected';
      return false;
    }
    _categoryError = null;
    return true;
  }

  bool _validateGender() {
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      _genderError = 'Gender must be selected';
      return false;
    }
    _genderError = null;
    return true;
  }

  bool _validatePrice() {
    final price = _minPriceController.text.trim();
    if (price.isEmpty) {
      _priceError = 'Price is required';
      return false;
    }
    final priceNum = double.tryParse(price);
    if (priceNum == null) {
      _priceError = 'Price must be a number';
      return false;
    }
    if (priceNum <= 0) {
      _priceError = 'Price must be greater than 0';
      return false;
    }
    _priceError = null;
    return true;
  }

  bool _validateDescription() {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      _descriptionError = 'Description is required';
      return false;
    }

    final alphanumericCount = description
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .length;
    if (alphanumericCount < 20) {
      _descriptionError = 'Description must be at least 20 letters/numbers';
      return false;
    }
    _descriptionError = null;
    return true;
  }

  bool _validateImages() {
    if (_productImages.isEmpty) {
      _imageError = 'At least 1 product image is required';
      return false;
    }
    if (_productImages.length > 5) {
      _imageError = 'Maximum 5 images allowed';
      return false;
    }
    _imageError = null;
    return true;
  }

  bool _validateAllFields() {
    bool isValid = true;
    isValid &= _validateProductName();

    isValid &= _validateCategory();
    isValid &= _validateGender();
    isValid &= _validatePrice();
    isValid &= _validateDescription();
    isValid &= _validateImages();
    return isValid;
  }

  Future<List<String>> _convertImagesToUrls() async {
    List<String> imageUrls = [];
    for (String imagePath in _productImages) {
      try {
        if (imagePath.startsWith('http://') ||
            imagePath.startsWith('https://')) {
          imageUrls.add(imagePath);
        } else if (imagePath.startsWith('data:image')) {
          imageUrls.add(imagePath);
        } else {
          if (kIsWeb) {
            imageUrls.add(imagePath);
          } else {
            final file = File(imagePath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final base64Image = base64Encode(bytes);

              String mimeType = 'image/jpeg';
              if (imagePath.toLowerCase().endsWith('.png')) {
                mimeType = 'image/png';
              } else if (imagePath.toLowerCase().endsWith('.gif')) {
                mimeType = 'image/gif';
              } else if (imagePath.toLowerCase().endsWith('.webp')) {
                mimeType = 'image/webp';
              }
              imageUrls.add('data:$mimeType;base64,$base64Image');
            }
          }
        }
      } catch (e) {}
    }
    return imageUrls;
  }

  Widget _buildImageWidget(
    String imagePath, {
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? Icon(Icons.image, color: lightGray);
        },
      );
    } else if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.split(',')[1];
        return Image.memory(
          base64Decode(base64String),
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? Icon(Icons.image, color: lightGray);
          },
        );
      } catch (e) {
        return errorWidget ?? Icon(Icons.image, color: lightGray);
      }
    } else if (kIsWeb) {
      return errorWidget ?? Icon(Icons.image, color: lightGray);
    } else {
      return Image.file(
        File(imagePath),
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? Icon(Icons.image, color: lightGray);
        },
      );
    }
  }

  Future<void> _handleSaveProduct() async {
    if (widget.userId == null) {
      _showSnackBar('User ID not found', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final imageUrls = await _convertImagesToUrls();

      if (imageUrls.isEmpty) {
        _showSnackBar('Failed to process images', Colors.red);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final price = double.parse(_minPriceController.text.trim());

      dynamic result;
      if (_isEditing && _editingProductId != null) {
        // Product is going back to admin for re-approval — remove from active promotions
        await _removeProductFromPromotions(_editingProductId!);

        result = await ApiService.updateProduct(
          productId: _editingProductId!,
          productName: _productNameController.text.trim(),
          category: _selectedCategory!,
          gender: _selectedGender!.toLowerCase(),
          price: price,
          description: _descriptionController.text.trim(),
          images: imageUrls,
          variants: _variants,
        );
      } else {
        result = await ApiService.createProduct(
          userId: widget.userId!,
          productName: _productNameController.text.trim(),
          category: _selectedCategory!,
          gender: _selectedGender!.toLowerCase(),
          price: price,
          description: _descriptionController.text.trim(),
          images: imageUrls,
          variants: _variants,
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        final wasEditing = _isEditing;

        _productNameController.clear();

        _minPriceController.clear();
        _descriptionController.clear();
        _selectedCategory = null;
        _selectedGender = null;
        _productImages.clear();

        _categoryController.clear();
        _genderController.clear();

        _variants.clear();
        _currentStep = 0;
        _selectedVariantSize = null;
        _selectedVariantColor = null;
        _variantPriceController.clear();
        _variantStockController.clear();
        _variantSizeController.clear();
        _variantColorController.clear();

        _isEditing = false;
        _editingProductId = null;

        await _loadProducts();

        if (!wasEditing) {
          setState(() {
            _productSubTab = 'pending';
          });
        }
      } else {
        final failMsg = _isEditing
            ? 'Failed to update product'
            : 'Failed to add product';
        _showSnackBar(result['message'] ?? failMsg, Colors.red);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }

  void _handleLogout() {
    _logoutDialogAnimationController.forward();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
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
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: isMobile
                        ? 24
                        : MediaQuery.of(context).size.width * 0.1,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 500,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: isMobile ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: isMobile ? 8 : 12),

                          Text(
                            'Are you sure you want to logout?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              color: lightGray,
                              height: 1.5,
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
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: lightGray.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 20 : 24,
                                      vertical: isMobile ? 14 : 16,
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: darkText,
                                      fontSize: isMobile ? 15 : 16,
                                      fontWeight: FontWeight.w600,
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
                                        builder: (context) =>
                                            const SignInScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brownColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 20 : 24,
                                      vertical: isMobile ? 14 : 16,
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.logout,
                                        color: whiteColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Logout',
                                        style: TextStyle(
                                          color: Colors.white,
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

  Future<void> _handleDeleteProfile() async {
    if (widget.userId == null) return;

    _showSnackBar('Checking profile status...', Colors.blue);

    try {
      final eligibilityResult =
          await ApiService.getSellerDeactivationEligibility(widget.userId!);

      if (!eligibilityResult['success']) {
        _showSnackBar(
          eligibilityResult['message'] ??
              'Failed to verify profile status. Please try again.',
          Colors.red,
        );
        return;
      }

      final blockers = List<String>.from(eligibilityResult['blockers'] ?? []);

      if (!eligibilityResult['canDeactivate'] || blockers.isNotEmpty) {
        _activeOrdersDialogAnimationController.forward();
        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.5),
          barrierDismissible: true,
          builder: (BuildContext context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isMobile = screenWidth < 768;
            final issueMessage = blockers.isEmpty
                ? 'You cannot deactivate your profile while there are outstanding issues for your store. Please resolve them first.'
                : 'You cannot deactivate your profile while there are ${blockers.map((blocker) {
                    switch (blocker) {
                      case 'active orders':
                        return 'active order(s)';
                      case 'unresolved complaints':
                        return 'unresolved complaint(s)';
                      case 'customer credit for your store':
                        return 'customer credit balance for your store';
                      default:
                        return blocker;
                    }
                  }).join(', ')}. Please resolve them first.';

            return AnimatedBuilder(
              animation: _activeOrdersDialogAnimationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _activeOrdersDialogFadeAnimation.value,
                  child: Transform.scale(
                    scale: _activeOrdersDialogScaleAnimation.value,
                    child: Dialog(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      insetPadding: EdgeInsets.symmetric(
                        horizontal: isMobile
                            ? 24
                            : MediaQuery.of(context).size.width * 0.1,
                      ),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: isMobile ? double.infinity : 500,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 24.0 : 32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Action Required',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 24 : 28,
                                  fontWeight: FontWeight.bold,
                                  color: darkText,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: isMobile ? 12 : 16),
                              Text(
                                issueMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  color: lightGray,
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: isMobile ? 24 : 32),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _activeOrdersDialogAnimationController
                                        .reverse()
                                        .then((_) {
                                          Navigator.of(context).pop();
                                        });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brownColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: isMobile ? 14 : 16,
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Ok',
                                        style: TextStyle(
                                          color: Colors.white,
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
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ).then((_) {
          _activeOrdersDialogAnimationController.reset();
        });
        return;
      }

      _deleteProfileDialogAnimationController.forward();
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.5),
        barrierDismissible: true,
        builder: (BuildContext context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 768;

          return AnimatedBuilder(
            animation: _deleteProfileDialogAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _deleteProfileDialogFadeAnimation.value,
                child: Transform.scale(
                  scale: _deleteProfileDialogScaleAnimation.value,
                  child: Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    insetPadding: EdgeInsets.symmetric(
                      horizontal: isMobile
                          ? 24
                          : MediaQuery.of(context).size.width * 0.1,
                    ),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 500,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Deactivate Profile',
                              style: TextStyle(
                                fontSize: isMobile ? 24 : 28,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: isMobile ? 8 : 12),

                            Text(
                              'Are you sure you want to deactivate your profile?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: lightGray,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: isMobile ? 20 : 28),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      _deleteProfileDialogAnimationController
                                          .reverse();
                                      Navigator.of(context).pop();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: lightGray.withOpacity(0.5),
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 20 : 24,
                                        vertical: isMobile ? 14 : 16,
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: darkText,
                                        fontSize: isMobile ? 15 : 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: isMobile ? 12 : 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      _deleteProfileDialogAnimationController
                                          .reverse();
                                      Navigator.of(context).pop();
                                      if (widget.userId == null) return;
                                      _showSnackBar(
                                        'Deactivating profile...',
                                        Colors.orange,
                                      );
                                      final result =
                                          await ApiService.deactivateSellerProfile(
                                            widget.userId!,
                                          );
                                      if (result['success']) {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SignInScreen(),
                                          ),
                                        );
                                      } else {
                                        _showSnackBar(
                                          result['message'] ??
                                              'Failed to deactivate profile',
                                          Colors.red,
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 20 : 24,
                                        vertical: isMobile ? 14 : 16,
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.block_outlined,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Deactivate',
                                          style: TextStyle(
                                            color: Colors.white,
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
        _deleteProfileDialogAnimationController.reset();
      });
    } catch (e) {
      _showSnackBar('An error occurred. Please try again.', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: beigeBackground,
      drawer: isMobile ? _buildMobileDrawer() : null,
      appBar: isMobile ? _buildMobileAppBar() : null,
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

              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(children: [Expanded(child: _buildContent())]);
  }

  PreferredSizeWidget _buildMobileAppBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    return AppBar(
      backgroundColor: whiteColor,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, color: darkText),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title:
          (_selectedTab == 1 && _productSubTab != 'add' ||
              _selectedTab == 2 ||
              _selectedTab == 3 ||
              _selectedTab == _complaintsTabIndex)
          ? Container(
              constraints: BoxConstraints(maxWidth: 300),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search here',
                  hintStyle: TextStyle(color: lightGray, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: lightGray, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: lightGray, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: beigeBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: lightGray.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: brownColor, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                style: TextStyle(fontSize: 14, color: darkText),
              ),
            )
          : null,
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMobile) ...[
              Text(
                _userData?['name'] ??
                    _storeInfo?['store_name'] ??
                    widget.sellerName,
                style: TextStyle(
                  color: darkText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
            ],
            GestureDetector(
              onTap: () => _onTabChanged(5),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                child: _buildStorePicture(
                  size: 36,
                  iconColor: whiteColor,
                  backgroundColor: brownColor,
                ),
              ),
            ),
          ],
        ),
      ],
      centerTitle: false,
      toolbarHeight: 64,
    );
  }

  Future<String?> _getValidLogoPath(String? storedPath) async {
    if (storedPath == null || storedPath.isEmpty) {
      return null;
    }

    if (storedPath.startsWith('http://') ||
        storedPath.startsWith('https://') ||
        storedPath.startsWith('data:image')) {
      return storedPath;
    }

    final file = File(storedPath);
    if (file.existsSync()) {
      return storedPath;
    }

    final fileName = path.basename(storedPath);

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String logosDir = path.join(appDocDir.path, 'logos');

      final reconstructedPath = path.join(logosDir, fileName);
      final reconstructedFile = File(reconstructedPath);

      if (reconstructedFile.existsSync()) {
        return reconstructedPath;
      }

      final logosDirectory = Directory(logosDir);
      if (await logosDirectory.exists()) {
        final files = await logosDirectory.list().toList();
        for (var file in files) {
          if (file is File) {
            final filePath = file.path;
            final fileBaseName = path.basename(filePath);

            if (widget.userId != null &&
                fileBaseName.contains('logo_${widget.userId}_')) {
              return filePath;
            }
          }
        }
      }
    } catch (e) {}

    return null;
  }

  Widget _buildStorePicture({
    required double size,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    if (_storeLogoPath != null && _storeLogoPath!.isNotEmpty) {
      final isUrl =
          _storeLogoPath!.startsWith('http://') ||
          _storeLogoPath!.startsWith('https://');
      final isBase64 = _storeLogoPath!.startsWith('data:image');

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: whiteColor.withOpacity(0.3), width: 2),
        ),
        child: ClipOval(
          child: isUrl || isBase64
              ? _buildImageWidget(
                  _storeLogoPath!,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: backgroundColor,
                    child: Icon(
                      Icons.store,
                      color: iconColor,
                      size: size * 0.5,
                    ),
                  ),
                )
              : FutureBuilder<String?>(
                  future: _getValidLogoPath(_storeLogoPath),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        color: backgroundColor,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              iconColor,
                            ),
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }

                    final validPath = snapshot.data;
                    if (validPath != null) {
                      return _buildImageWidget(
                        validPath,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: backgroundColor,
                          child: Icon(
                            Icons.store,
                            color: iconColor,
                            size: size * 0.5,
                          ),
                        ),
                      );
                    }

                    return Container(
                      color: backgroundColor,
                      child: Icon(
                        Icons.store,
                        color: iconColor,
                        size: size * 0.5,
                      ),
                    );
                  },
                ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Icon(Icons.store, color: iconColor, size: size * 0.5),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: whiteColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
            decoration: BoxDecoration(
              color: whiteColor,
              border: Border(
                bottom: BorderSide(color: lightGray.withOpacity(0.1), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: brownColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'f',
                          style: TextStyle(
                            color: whiteColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'fitaura',
                              style: TextStyle(
                                color: darkText,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(
                              text: '.',
                              style: TextStyle(
                                color: brownColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
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
                    Icons.inventory_2_outlined,
                    color: _selectedTab == 1 ? brownColor : lightGray,
                    size: 24,
                  ),
                  title: Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 16,
                      color: darkText,
                      fontWeight: _selectedTab == 1
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  initiallyExpanded: _selectedTab == 1,
                  children: [
                    _buildDrawerNavItem(
                      icon: Icons.check_circle_outline,
                      title: 'Approved Products',
                      index: 1,
                      isSubItem: true,
                      isSelectedOverride: _productSubTab == 'approved',
                      onTapOverride: () {
                        Navigator.of(context).pop();
                        _onTabChanged(1);
                        _onProductSubTabChanged('approved');
                      },
                    ),
                    _buildDrawerNavItem(
                      icon: Icons.pending_outlined,
                      title: 'Pending Approval',
                      index: 1,
                      isSubItem: true,
                      isSelectedOverride: _productSubTab == 'pending',
                      onTapOverride: () {
                        Navigator.of(context).pop();
                        _onTabChanged(1);
                        _onProductSubTabChanged('pending');
                      },
                    ),
                    _buildDrawerNavItem(
                      icon: Icons.cancel_outlined,
                      title: 'Rejected Products',
                      index: 1,
                      isSubItem: true,
                      isSelectedOverride: _productSubTab == 'rejected',
                      onTapOverride: () {
                        Navigator.of(context).pop();
                        _onTabChanged(1);
                        _onProductSubTabChanged('rejected');
                      },
                    ),
                    if (_isEditing)
                      _buildDrawerNavItem(
                        icon: Icons.edit_outlined,
                        title: 'Edit a Product',
                        index: 1,
                        isSubItem: true,
                        isSelectedOverride: _productSubTab == 'add',
                        onTapOverride: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    _buildDrawerNavItem(
                      icon: Icons.add,
                      title: 'Add a Product',
                      index: 1,
                      isSubItem: true,
                      isSelectedOverride:
                          _productSubTab == 'add' && !_isEditing,
                      onTapOverride: () {
                        Navigator.of(context).pop();
                        _onTabChanged(1);
                        _onProductSubTabChanged('add');
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  leading: Icon(
                    Icons.shopping_bag_outlined,
                    color: _selectedTab == 2 ? brownColor : lightGray,
                    size: 24,
                  ),
                  title: Text(
                    'Orders',
                    style: TextStyle(
                      fontSize: 16,
                      color: darkText,
                      fontWeight: _selectedTab == 2
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  initiallyExpanded: _selectedTab == 2,
                  children: [
                    _buildDrawerNavItem(
                      icon: Icons.pending_actions,
                      title: 'Pending Orders',
                      index: 2,
                      isSubItem: true,
                      isSelectedOverride: _orderSubTab == 'pending',
                      onTapOverride: () {
                        Navigator.of(context).pop();
                        _onTabChanged(2);
                        _onOrderSubTabChanged('pending');
                      },
                    ),
                    _buildDrawerNavItem(
                      icon: Icons.check_circle_outline,
                      title: 'Accepted Orders',
                      index: 2,
                      isSubItem: true,
                      isSelectedOverride: _orderSubTab == 'accepted',
                      onTapOverride: () {
                        Navigator.of(context).pop();
                        _onTabChanged(2);
                        _onOrderSubTabChanged('accepted');
                      },
                    ),
                    _buildDrawerNavItem(
                      icon: Icons.cancel_outlined,
                      title: 'Rejected Orders',
                      index: 2,
                      isSubItem: true,
                      isSelectedOverride: _orderSubTab == 'rejected',
                      onTapOverride: () {
                        Navigator.of(context).pop();
                        _onTabChanged(2);
                        _onOrderSubTabChanged('rejected');
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  leading: Icon(
                    Icons.campaign_outlined,
                    color: _selectedTab == 7 ? brownColor : lightGray,
                    size: 24,
                  ),
                  title: Text(
                    'Promotions',
                    style: TextStyle(
                      fontSize: 16,
                      color: darkText,
                      fontWeight: _selectedTab == 7
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  initiallyExpanded: _selectedTab == 7,
                  children: [
                    _buildDrawerNavItem(
                      icon: Icons.add,
                      title: 'Create Promotion',
                      index: 7,
                      isSubItem: true,
                      isSelectedOverride: _promotionSubTab == 'create',
                      onTapOverride: () {
                        Navigator.of(context).pop();
                        _onTabChanged(7);
                        _onPromotionSubTabChanged('create');
                      },
                    ),
                    _buildDrawerNavItem(
                      icon: Icons.check_circle_outline,
                      title: 'Active Promotions',
                      index: 7,
                      isSubItem: true,
                      isSelectedOverride: _promotionSubTab == 'active',
                      onTapOverride: () {
                        Navigator.of(context).pop();
                        _onTabChanged(7);
                        _onPromotionSubTabChanged('active');
                      },
                    ),
                    _buildDrawerNavItem(
                      icon: Icons.pause_circle_outline,
                      title: 'Inactive Promotions',
                      index: 7,
                      isSubItem: true,
                      isSelectedOverride: _promotionSubTab == 'inactive',
                      onTapOverride: () {
                        Navigator.of(context).pop();
                        _onTabChanged(7);
                        _onPromotionSubTabChanged('inactive');
                      },
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
                  index: 3,
                ),
                _buildDrawerNavItem(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  index: 4,
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
                icon: Icon(Icons.logout, color: brownColor, size: 20),
                label: Text(
                  'Logout',
                  style: TextStyle(
                    color: darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: brownColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
    VoidCallback? onTapOverride,
    bool? isSelectedOverride,
  }) {
    final isSelected = isSelectedOverride ?? (_selectedTab == index);
    return ListTile(
      contentPadding: EdgeInsets.only(left: isSubItem ? 56 : 16, right: 16),
      leading: Icon(
        icon,
        color: isSelected ? brownColor : lightGray,
        size: isSubItem ? 20 : 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isSubItem ? 15 : 16,
          color: darkText,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedTileColor: brownColor.withOpacity(0.1),
      onTap:
          onTapOverride ??
          () {
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
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_bottomNavItems.length, (index) {
            final item = _bottomNavItems[index];
            final targetIndex = item['index'] as int;
            final isSelected = _selectedTab == targetIndex;
            final unreadCount = targetIndex == _notificationsTabIndex
                ? _unreadNotificationCount
                : targetIndex == _messagesTabIndex
                ? _unreadMessageCount
                : 0;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  _onTabChanged(targetIndex);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 50,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            width: 44,
                            height: 44,
                            decoration: isSelected
                                ? BoxDecoration(
                                    color: whiteColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: brownColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  )
                                : null,
                            child: Icon(
                              isSelected
                                  ? (item['activeIcon'] ?? item['icon'])
                                        as IconData
                                  : item['icon'] as IconData,
                              color: isSelected ? brownColor : Colors.grey[400],
                              size: 24,
                            ),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: brownColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: whiteColor,
                                    width: 1.5,
                                  ),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Center(
                                  child: Text(
                                    unreadCount > 99
                                        ? '99+'
                                        : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
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

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isSidebarHovered ? 280 : 80,
      decoration: BoxDecoration(
        color: whiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _isSidebarHovered ? 24 : 20,
                vertical: _isSidebarHovered ? 16 : 12,
              ),
              child: Row(
                mainAxisAlignment: _isSidebarHovered
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: brownColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'f',
                        style: TextStyle(
                          color: whiteColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  if (_isSidebarHovered) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'fitaura',
                              style: TextStyle(
                                color: darkText,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(
                              text: '.',
                              style: TextStyle(
                                color: brownColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
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
              children: _navItems
                  .map<Widget>((Map<String, dynamic> item) {
                    final index = item['index'] as int;
                    if (index == 1) {
                      return _buildProductsNavItem(
                        icon: item['icon'] as IconData,
                        activeIcon: item['activeIcon'] as IconData,
                        title: item['label'] as String,
                        index: index,
                      );
                    } else if (index == 2) {
                      return _buildOrdersNavItem(
                        icon: item['icon'] as IconData,
                        activeIcon: item['activeIcon'] as IconData,
                        title: item['label'] as String,
                        index: index,
                      );
                    } else if (index == 7) {
                      return _buildPromotionsNavItem(
                        icon: item['icon'] as IconData,
                        activeIcon: item['activeIcon'] as IconData,
                        title: item['label'] as String,
                        index: index,
                      );
                    }
                    return _buildSidebarNavItem(
                      icon: item['icon'] as IconData,
                      activeIcon: item['activeIcon'] as IconData,
                      title: item['label'] as String,
                      index: index,
                      unreadCount: index == _messagesTabIndex
                          ? _unreadMessageCount
                          : index == _complaintsTabIndex
                          ? _complaints.length
                          : 0,
                    );
                  })
                  .toList(growable: false),
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

                const SizedBox(height: 8),
                _buildSidebarBottomItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  title: 'Settings',
                  onTap: () => _onTabChanged(_settingsTabIndex),
                  isSelected: _selectedTab == _settingsTabIndex,
                ),

                const SizedBox(height: 8),
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
    int unreadCount = 0,
  }) {
    final isSelected = _selectedTab == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => _onTabChanged(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: EdgeInsets.symmetric(
            horizontal: _isSidebarHovered ? 16 : 8,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? brownColor.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: brownColor.withOpacity(0.4), width: 1.5)
                : null,
          ),
          child: _isSidebarHovered
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      isSelected ? activeIcon : icon,
                      color: isSelected ? brownColor : lightGray,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                color: isSelected ? brownColor : darkText,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: brownColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount > 99
                                    ? '99+'
                                    : unreadCount.toString(),
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
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isSelected ? activeIcon : icon,
                        color: isSelected ? brownColor : lightGray,
                        size: 22,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: brownColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: whiteColor, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 9 ? '9+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
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
  }

  Widget _buildProductsNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedTab == index;

    final hasSelectedSubItem = _selectedTab == 1;
    final isExpanded = _isProductsExpanded;

    return Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () {
              setState(() {
                _isProductsExpanded = !_isProductsExpanded;
              });
              if (_selectedTab != 1) {
                _onTabChanged(1);
                _onProductSubTabChanged('approved');
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: EdgeInsets.symmetric(
                horizontal: _isSidebarHovered ? 16 : 8,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: (isSelected || hasSelectedSubItem)
                    ? brownColor.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: (isSelected || hasSelectedSubItem)
                    ? Border.all(color: brownColor.withOpacity(0.4), width: 1.5)
                    : null,
              ),
              child: _isSidebarHovered
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          isSelected || hasSelectedSubItem ? activeIcon : icon,
                          color: (isSelected || hasSelectedSubItem)
                              ? brownColor
                              : lightGray,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              color: (isSelected || hasSelectedSubItem)
                                  ? brownColor
                                  : darkText,
                              fontWeight: (isSelected || hasSelectedSubItem)
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isSidebarHovered)
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: (isSelected || hasSelectedSubItem)
                                ? brownColor
                                : lightGray,
                            size: 20,
                          ),
                      ],
                    )
                  : Center(
                      child: Icon(
                        isSelected || hasSelectedSubItem ? activeIcon : icon,
                        color: (isSelected || hasSelectedSubItem)
                            ? brownColor
                            : lightGray,
                        size: 22,
                      ),
                    ),
            ),
          ),
        ),

        if (isExpanded && _isSidebarHovered)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 4),
            child: Column(
              children: [
                _buildSubNavItem(
                  'Approved Products',
                  _selectedTab == 1 && _productSubTab == 'approved',
                  icon: Icons.check_circle_outline,
                  onTap: () => _onProductSubTabChanged('approved'),
                ),
                const SizedBox(height: 4),
                _buildSubNavItem(
                  'Pending Approval',
                  _selectedTab == 1 && _productSubTab == 'pending',
                  icon: Icons.pending_outlined,
                  onTap: () => _onProductSubTabChanged('pending'),
                ),
                const SizedBox(height: 4),
                _buildSubNavItem(
                  'Rejected Products',
                  _selectedTab == 1 && _productSubTab == 'rejected',
                  icon: Icons.cancel_outlined,
                  onTap: () => _onProductSubTabChanged('rejected'),
                ),
                const SizedBox(height: 4),
                if (_isEditing) ...[
                  _buildSubNavItem(
                    'Edit a Product',
                    _selectedTab == 1 && _productSubTab == 'add',
                    icon: Icons.edit_outlined,
                    onTap: () {},
                  ),
                  const SizedBox(height: 4),
                ],
                _buildSubNavItem(
                  'Add a Product',
                  _selectedTab == 1 && _productSubTab == 'add' && !_isEditing,
                  icon: Icons.add,
                  onTap: () => _onProductSubTabChanged('add'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOrdersNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedTab == index;
    final hasSelectedSubItem = _selectedTab == 2;
    final isExpanded = _isOrdersExpanded;

    return Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () {
              setState(() {
                _isOrdersExpanded = !_isOrdersExpanded;
              });
              if (_selectedTab != 2) {
                _onTabChanged(2);
                _onOrderSubTabChanged('pending');
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: EdgeInsets.symmetric(
                horizontal: _isSidebarHovered ? 16 : 8,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: (isSelected || hasSelectedSubItem)
                    ? brownColor.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: (isSelected || hasSelectedSubItem)
                    ? Border.all(color: brownColor.withOpacity(0.4), width: 1.5)
                    : null,
              ),
              child: _isSidebarHovered
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          isSelected || hasSelectedSubItem ? activeIcon : icon,
                          color: (isSelected || hasSelectedSubItem)
                              ? brownColor
                              : lightGray,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              color: (isSelected || hasSelectedSubItem)
                                  ? brownColor
                                  : darkText,
                              fontWeight: (isSelected || hasSelectedSubItem)
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isSidebarHovered)
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: (isSelected || hasSelectedSubItem)
                                ? brownColor
                                : lightGray,
                            size: 20,
                          ),
                      ],
                    )
                  : Center(
                      child: Icon(
                        isSelected || hasSelectedSubItem ? activeIcon : icon,
                        color: (isSelected || hasSelectedSubItem)
                            ? brownColor
                            : lightGray,
                        size: 22,
                      ),
                    ),
            ),
          ),
        ),

        if (isExpanded && _isSidebarHovered)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 4),
            child: Column(
              children: [
                _buildSubNavItem(
                  'Pending Orders',
                  _selectedTab == 2 && _orderSubTab == 'pending',
                  icon: Icons.pending_actions,
                  onTap: () => _onOrderSubTabChanged('pending'),
                ),
                const SizedBox(height: 4),
                _buildSubNavItem(
                  'Accepted Orders',
                  _selectedTab == 2 && _orderSubTab == 'accepted',
                  icon: Icons.check_circle_outline,
                  onTap: () => _onOrderSubTabChanged('accepted'),
                ),
                const SizedBox(height: 4),
                _buildSubNavItem(
                  'Rejected Orders',
                  _selectedTab == 2 && _orderSubTab == 'rejected',
                  icon: Icons.cancel_outlined,
                  onTap: () => _onOrderSubTabChanged('rejected'),
                ),
                const SizedBox(height: 4),
                _buildSubNavItem(
                  'Completed Orders',
                  _selectedTab == 2 && _orderSubTab == 'completed',
                  icon: Icons.assignment_turned_in_outlined,
                  onTap: () => _onOrderSubTabChanged('completed'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPromotionsNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedTab == index;
    final hasSelectedSubItem = _selectedTab == 7;
    final isExpanded = _isPromotionsExpanded;

    return Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () {
              setState(() {
                _isPromotionsExpanded = !_isPromotionsExpanded;
              });
              if (_selectedTab != 7) {
                _onTabChanged(7);
                _onPromotionSubTabChanged('active');
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: EdgeInsets.symmetric(
                horizontal: _isSidebarHovered ? 16 : 8,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: (isSelected || hasSelectedSubItem)
                    ? brownColor.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: (isSelected || hasSelectedSubItem)
                    ? Border.all(color: brownColor.withOpacity(0.4), width: 1.5)
                    : null,
              ),
              child: _isSidebarHovered
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          isSelected || hasSelectedSubItem ? activeIcon : icon,
                          color: (isSelected || hasSelectedSubItem)
                              ? brownColor
                              : lightGray,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              color: (isSelected || hasSelectedSubItem)
                                  ? brownColor
                                  : darkText,
                              fontWeight: (isSelected || hasSelectedSubItem)
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isSidebarHovered)
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: (isSelected || hasSelectedSubItem)
                                ? brownColor
                                : lightGray,
                            size: 20,
                          ),
                      ],
                    )
                  : Center(
                      child: Icon(
                        isSelected || hasSelectedSubItem ? activeIcon : icon,
                        color: (isSelected || hasSelectedSubItem)
                            ? brownColor
                            : lightGray,
                        size: 22,
                      ),
                    ),
            ),
          ),
        ),

        if (isExpanded && _isSidebarHovered)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 4),
            child: Column(
              children: [
                _buildSubNavItem(
                  'Active Promotions',
                  _selectedTab == 7 && _promotionSubTab == 'active',
                  icon: Icons.check_circle_outline,
                  onTap: () => _onPromotionSubTabChanged('active'),
                ),
                const SizedBox(height: 4),
                _buildSubNavItem(
                  'Inactive Promotions',
                  _selectedTab == 7 && _promotionSubTab == 'inactive',
                  icon: Icons.pause_circle_outline,
                  onTap: () => _onPromotionSubTabChanged('inactive'),
                ),
                const SizedBox(height: 4),
                _buildSubNavItem(
                  'Create Promotion',
                  _selectedTab == 7 && _promotionSubTab == 'create',
                  icon: Icons.add,
                  onTap: () => _onPromotionSubTabChanged('create'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubNavItem(
    String title,
    bool isSelected, {
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? brownColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              icon != null
                  ? Icon(
                      icon,
                      size: 18,
                      color: isSelected ? brownColor : lightGray,
                    )
                  : Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? brownColor : lightGray,
                        shape: BoxShape.circle,
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? brownColor : darkText,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
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
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: _isSidebarHovered ? 16 : 8,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? brownColor.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: brownColor.withOpacity(0.4), width: 1.5)
                : null,
          ),
          child: _isSidebarHovered
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      isSelected ? activeIcon : icon,
                      color: isLogout
                          ? Colors.red
                          : (isSelected ? brownColor : lightGray),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                color: isLogout
                                    ? Colors.red
                                    : (isSelected ? brownColor : darkText),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: brownColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount > 99
                                    ? '99+'
                                    : unreadCount.toString(),
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
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isSelected ? activeIcon : icon,
                        color: isLogout
                            ? Colors.red
                            : (isSelected ? brownColor : lightGray),
                        size: 22,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: brownColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: whiteColor, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 9 ? '9+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
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
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: whiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: isMobile ? 2 : 3),
                Text(
                  'Manage your store from here',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: lightGray,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: isMobile ? 2 : 3,
            child:
                (_selectedTab == 1 && _productSubTab != 'add' ||
                    _selectedTab == 2 ||
                    _selectedTab == _complaintsTabIndex)
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
                        decoration: InputDecoration(
                          hintText: 'Search here',
                          hintStyle: TextStyle(
                            color: lightGray,
                            fontSize: isMobile ? 13 : 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: lightGray,
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: lightGray,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: beigeBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: lightGray.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: brownColor, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 14 : 18,
                            vertical: isMobile ? 12 : 14,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: darkText,
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
              child: _buildSellerProfile(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerProfile() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => _onTabChanged(5),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 12,
            vertical: isMobile ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: beigeBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStorePicture(
                size: isMobile ? 36 : 40,
                iconColor: whiteColor,
                backgroundColor: brownColor,
              ),
              if (!isMobile) ...[
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _userData?['name'] ??
                          _storeInfo?['store_name'] ??
                          widget.sellerName,
                      style: TextStyle(
                        fontSize: 14,
                        color: darkText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Store Owner',
                      style: TextStyle(
                        fontSize: 12,
                        color: lightGray,
                        fontWeight: FontWeight.w400,
                      ),
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

  String _getHeaderTitle() {
    switch (_selectedTab) {
      case 0:
        return 'Dashboard';
      case 1:
        if (_isEditing && _productSubTab == 'add') {
          return 'Edit Product';
        }
        if (_productSubTab == 'add') {
          return 'Add Product';
        }
        if (_productSubTab == 'approved') {
          return 'Approved Products';
        }
        if (_productSubTab == 'pending') {
          return 'Pending Approval';
        }
        if (_productSubTab == 'rejected') {
          return 'Rejected Products';
        }
        return 'Products';
      case 2:
        if (_orderSubTab == 'pending') return 'Pending Orders';
        if (_orderSubTab == 'accepted') return 'Accepted Orders';
        if (_orderSubTab == 'completed') return 'Completed Orders';
        if (_orderSubTab == 'rejected') return 'Rejected Orders';
        return 'Orders';
      case 7:
        if (_promotionSubTab == 'create') return 'Create Promotion';
        if (_promotionSubTab == 'active') return 'Active Promotions';
        if (_promotionSubTab == 'inactive') return 'Inactive Promotions';
        return 'Promotions';
      case _transactionsTabIndex:
        return 'Transactions';
      case _complaintsTabIndex:
        return 'Complaints';
      case _notificationsTabIndex:
        return 'Notifications';
      case 5:
        return 'Profile';
      case _settingsTabIndex:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(brownColor),
        ),
      );
    }

    switch (_selectedTab) {
      case 0:
        return _buildDashboardView();
      case 1:
        if (_productSubTab == 'add') {
          return _buildAddProductView();
        } else {
          return _buildProductsView();
        }
      case 2:
        return _buildOrdersView();
      case _transactionsTabIndex:
        return _buildTransactionsView();
      case _complaintsTabIndex:
        return _buildComplaintsView();
      case 7:
        return _buildPromotionsView();
      case 3:
        return _buildMessagesView();
      case _notificationsTabIndex:
        return _buildNotificationsView();
      case 5:
        return _buildProfileView();
      case _settingsTabIndex:
        return _buildSettingsView();
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildTransactionsView() {
    return Scaffold(
      backgroundColor: beigeBackground,
      body: RefreshIndicator(
        onRefresh: _loadStoreWalletData,
        color: brownColor,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Store Wallet Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildStatCard('Customers with Balance',
                          _storeWalletCustomerCount.toString(),
                          Icons.people_outline, Colors.indigo),
                      _buildStatCard('Total Store Credits',
                          'Rs ${_storeWalletTotalBalance.toStringAsFixed(2)}',
                          Icons.account_balance_wallet_outlined,
                          Colors.teal),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaction History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_storeWalletTransactions.length} transactions',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_storeWalletTransactions.isEmpty)
                    SizedBox(
                      height: 220,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 58,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No transactions yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _storeWalletTransactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(
                            _storeWalletTransactions[index]);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? 'debit';
    final amount = transaction['amount'] ?? 0.0;
    final description = transaction['description'] ?? 'Transaction';
    final method = transaction['method'] ?? '';
    final timestamp = transaction['timestamp'];
    final isCredit = type == 'credit';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCredit ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isCredit ? Colors.green : Colors.red,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (method.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    method,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _formatTransactionDate(timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}Rs. ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTransactionDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return date.toString();
    }
  }

  Widget _buildSettingsView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      color: ProfileStyles.beigeBackgroundColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 20 : 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Container(
              decoration: BoxDecoration(
                color: ProfileStyles.whiteColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
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
                      color: ProfileStyles.darkTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: ProfileStyles.beigeBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ProfileStyles.borderColor),
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
                      color: ProfileStyles.darkTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: ProfileStyles.beigeBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ProfileStyles.borderColor),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.lock_outline,
                        color: ProfileStyles.primaryColor,
                      ),
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
                color: ProfileStyles.darkTextColor,
              ),
            ),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: ProfileStyles.darkTextColor,
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: ProfileStyles.darkTextColor,
                      ),
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

    final productsCount = _products.where((p) {
      final isVerified = p['is_verified'];
      return isVerified == 1 || isVerified == '1' || isVerified == true;
    }).length;
    final ordersCount = _orders.where((order) {
      final status = (order['status'] ?? order['order_status'] ?? '')
          .toString()
          .toLowerCase();
      return status == 'pending';
    }).length;

    final deliveredCount = _orders.where((order) {
      final status = order['status']?.toString().toLowerCase() ?? '';
      return status == 'delivered' || status == 'completed';
    }).length;

    double totalRevenue = 0.0;
    final List<String> _revenueLog = [];
    for (var order in _orders) {
      final status = (order['status'] ?? order['order_status'] ?? '')
          .toString()
          .toLowerCase();

      if (status == 'completed') {
        // Parse seller's order total (displayed as "Your Order Price")
        double orderTotalVal = 0.0;
        final ot = order['total'];
        if (ot != null) {
          if (ot is num) {
            orderTotalVal = ot.toDouble();
          } else if (ot is String) {
            orderTotalVal = double.tryParse(ot) ?? 0.0;
          }
        }

        final paymentMethod = (order['payment_method'] ?? order['payment_type'] ?? '')
            .toString()
            .toLowerCase();

        final double walletUsed = double.tryParse(order['wallet_amount']?.toString() ?? '0') ?? 0.0;

        double contribution = 0.0;
        if (paymentMethod.contains('cash') || paymentMethod.contains('cod')) {
          contribution = orderTotalVal;
        } else if (paymentMethod.contains('wallet')) {
          contribution = (orderTotalVal - walletUsed);
        } else {
          contribution = orderTotalVal;
        }
        totalRevenue += contribution;
        _revenueLog.add('Order ${order['id'] ?? order['order_id'] ?? '-'}: status=$status, payment_method=$paymentMethod, order_total=$orderTotalVal, wallet_used=$walletUsed, contribution= $contribution');
      }
    }

    // Subtract refund amounts for completed complaints
    for (var complaint in _complaints) {
      final cStatus = (complaint['status'] ?? '').toString().toLowerCase();
      if (cStatus == 'completed') {
        final refund = complaint['refund_amount'];
        double refundVal = 0.0;
        if (refund != null) {
          if (refund is num) {
            refundVal = refund.toDouble();
          } else if (refund is String) {
            refundVal = double.tryParse(refund) ?? 0.0;
          }
        }
        totalRevenue -= refundVal;
        _revenueLog.add('Complaint ${complaint['complaint_id'] ?? '-'}: status=$cStatus, refund=$refundVal (subtracted)');
      }
    }

    // Print detailed breakdown to console for debugging
    try {
      print('--- Revenue Breakdown ---');
      for (var line in _revenueLog) {
        print(line);
      }
      print('Total Revenue (computed): $totalRevenue');
      print('--- End Revenue Breakdown ---');
    } catch (_) {}

    final query = _searchController.text.toLowerCase();
    final filteredRecentOrders = _orders.where((order) {
      final status = (order['status'] ?? order['order_status'] ?? '')
          .toString()
          .toLowerCase();
      if (status != 'pending') return false;

      if (query.isEmpty) return true;

      final id = (order['id'] ?? '').toString().toLowerCase();
      final customer = (order['customer_name'] ?? '').toString().toLowerCase();
      return id.contains(query) ||
          status.contains(query) ||
          customer.contains(query);
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isMobile ? 2 : 4,
                crossAxisSpacing: isMobile ? 12 : 16,
                mainAxisSpacing: isMobile ? 12 : 16,
                childAspectRatio: isMobile ? 1.1 : 1.5,
                children: [
                  _buildStatCard(
                    'Total Products',
                    productsCount.toString(),
                    Icons.inventory_2_outlined,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'New Orders',
                    ordersCount.toString(),
                    Icons.shopping_bag_outlined,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Total Delivered',
                    deliveredCount.toString(),
                    Icons.check_circle_outlined,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Total Revenue',
                    'Rs ${totalRevenue.toStringAsFixed(0)}',
                    Icons.attach_money_outlined,
                    Colors.purple,
                  ),
                ],
              ),

              SizedBox(height: isMobile ? 8 : 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Orders',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _onTabChanged(2),
                    child: Text(
                      'View All',
                      style: TextStyle(color: brownColor),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 8 : 16),
              if (filteredRecentOrders.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      query.isEmpty ? 'No recent orders' : 'No orders found',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF797979),
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: filteredRecentOrders
                      .take(5)
                      .map(
                        (order) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildOrderCard(order: order),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: lightGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      color: beigeBackground,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHero(isMobile),
                const SizedBox(height: 24),

                _buildProfileStats(isMobile),
                const SizedBox(height: 24),

                if (isMobile)
                  Column(
                    children: [
                      _buildStoreInfoSection(),
                      const SizedBox(height: 16),
                      _buildPersonalInfoSection(),
                    ],
                  )
                else
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildStoreInfoSection()),

                        const SizedBox(width: 24),
                        Expanded(child: _buildPersonalInfoSection()),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: SellerDashboardStyles.profileCardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red.shade400,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Danger Zone',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade400,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.red.withOpacity(0.15), height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delete Profile',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: darkText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Permanently deactivate your seller account and all associated data.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: lightGray,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _handleDeleteProfile,
                            icon: const Icon(
                              Icons.delete_forever_outlined,
                              size: 18,
                            ),
                            label: const Text(
                              'Delete',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
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

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHero(bool isMobile) {
    return Container(
      height: isMobile ? 200 : 260,
      decoration: SellerDashboardStyles.profileCardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      brownColor,
                      brownColor.withOpacity(0.8),
                      brownColor.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
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
                      Hero(
                        tag: 'store_logo',
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: _buildStorePicture(
                            size: isMobile ? 80 : 120,
                            iconColor: brownColor,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickStoreLogo,
                          child: Container(
                            height: isMobile ? 28 : 36,
                            width: isMobile ? 28 : 36,
                            decoration: BoxDecoration(
                              color: brownColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: isMobile ? 14 : 18,
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _storeInfo?['store_name'] ?? 'Store Name',
                                style: TextStyle(
                                  fontSize: isMobile ? 24 : 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _storeInfo?['bio'] ??
                              'Growing my fashion business with FitAura.',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildProfileStats(bool isMobile) {
    final productsCount = _products.length;
    final ordersCount = _orders.where((o) {
      final status = (o['status'] ?? o['order_status'] ?? '')
          .toString()
          .toLowerCase();
      return status == 'completed' || status == 'delivered';
    }).length;
    final rating = _storeInfo?['overall_rating']?.toString() ?? '5.0';

    return Container(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 20 : 24),
      decoration: SellerDashboardStyles.profileCardDecoration,
      child: Row(
        children: [
          _buildStatItem(
            'Total Products',
            productsCount.toString(),
            Icons.shopping_bag_outlined,
          ),
          _buildStatVerticalDivider(),
          _buildStatItem(
            'Overall Rating',
            rating,
            Icons.star_rounded,
            isRating: true,
          ),
          _buildStatVerticalDivider(),
          _buildStatItem(
            'Orders Completed',
            ordersCount.toString(),
            Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, {
    bool isRating = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: brownColor.withOpacity(0.6), size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF000000),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: lightGray,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.black.withOpacity(0.06),
    );
  }

  Widget _buildStoreInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: SellerDashboardStyles.profileCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_outlined, color: brownColor, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Store Details',
                  style: SellerDashboardStyles.profileSectionTitleStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: _showEditStoreDialog,
                icon: Icon(Icons.edit_outlined, color: brownColor, size: 20),
                tooltip: 'Edit Store Details',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoTile(
            'Store URL',
            _storeInfo?['website'] ?? 'fitaura.com/store/unique',
            Icons.link_rounded,
          ),
          _buildInfoTile(
            'Instagram',
            _storeInfo?['instagram'] ?? '@fitaura_official',
            Icons.camera_alt_outlined,
          ),
          _buildInfoTile(
            'Category',
            _storeInfo?['category'] ?? 'Fashion & Apparel',
            Icons.category_outlined,
          ),
          _buildInfoTile(
            'Member Since',
            _formatDate(_storeInfo?['created_at']),
            Icons.calendar_today_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: SellerDashboardStyles.profileCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_pin_outlined, color: brownColor, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Personal Info',
                  style: SellerDashboardStyles.profileSectionTitleStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: _showChangePasswordDialog,
                icon: Icon(Icons.vpn_key_outlined, color: brownColor, size: 20),
                tooltip: 'Change Password',
              ),
              IconButton(
                onPressed: _showEditPersonalDialog,
                icon: Icon(Icons.edit_outlined, color: brownColor, size: 20),
                tooltip: 'Edit Personal Details',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoTile(
            'Full Name',
            _userData?['name'] ?? widget.sellerName,
            Icons.badge_outlined,
          ),
          _buildInfoTile(
            'Email Address',
            _userData?['email'] ?? 'seller@fitaura.com',
            Icons.email_outlined,
          ),
          _buildInfoTile(
            'Contact',
            _userData?['contact_number'] ?? '+92 300 1234567',
            Icons.phone_android_outlined,
          ),
          _buildInfoTile(
            'CNIC Number',
            _obfuscateCNIC(_userData?['cnic']),
            Icons.fingerprint_rounded,
          ),
          _buildInfoTile(
            'Office Address',
            _userData?['address'] ?? 'Street 1, Lahore, Pakistan',
            Icons.location_on_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: brownColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: brownColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: SellerDashboardStyles.infoLabelStyle),
                const SizedBox(height: 2),
                Text(value, style: SellerDashboardStyles.infoValueStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditStoreDialog() {
    if (_storeInfo == null) {
      _showSnackBar('Store information not loaded', Colors.orange);
      return;
    }

    _editStoreNameController.text = _storeInfo?['store_name']?.toString() ?? '';
    _editBioController.text = _storeInfo?['bio']?.toString() ?? '';
    _editWebsiteController.text = _storeInfo?['website']?.toString() ?? '';
    _editInstagramController.text = _storeInfo?['instagram']?.toString() ?? '';

    setState(() {
      _editStoreNameError = null;
      _editBioError = null;
      _editWebsiteError = null;
      _editInstagramError = null;
    });

    _showProfileEditDialog(
      title: 'Edit Store Details',
      contentBuilder: (context, setDialogState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEditTextField(
            _editStoreNameController,
            'Store Name',
            Icons.store,
            errorText: _editStoreNameError,
            onChanged: (v) => setDialogState(() => _validateStoreName(v)),
          ),
          const SizedBox(height: 16),
          _buildEditTextField(
            _editBioController,
            'Bio',
            Icons.description,
            maxLines: 3,
            errorText: _editBioError,
            onChanged: (v) => setDialogState(() => _validateBio(v)),
          ),
          const SizedBox(height: 16),
          _buildEditTextField(
            _editWebsiteController,
            'Website URL',
            Icons.link,
            errorText: _editWebsiteError,
            onChanged: (v) => setDialogState(() => _validateWebsite(v)),
          ),
          const SizedBox(height: 16),
          _buildEditTextField(
            _editInstagramController,
            'Instagram Handle',
            Icons.camera_alt,
            errorText: _editInstagramError,
            onChanged: (v) => setDialogState(() => _validateInstagram(v)),
          ),
        ],
      ),
      onSave: (setDialogState) async {
        if (widget.userId == null || _storeInfo?['store_id'] == null) return;

        final isValid =
            _validateStoreName(_editStoreNameController.text) &
            _validateBio(_editBioController.text) &
            _validateWebsite(_editWebsiteController.text) &
            _validateInstagram(_editInstagramController.text);

        if (!isValid) {
          setDialogState(() {});
          return;
        }

        final result = await ApiService.updateStoreInfo(
          storeId: int.parse(_storeInfo!['store_id'].toString()),
          storeName: _editStoreNameController.text.trim(),
          bio: _editBioController.text.trim(),
          website: _editWebsiteController.text.trim(),
          instagram: _editInstagramController.text.trim(),
          logo: _storeInfo!['logo'],
        );

        if (result['success']) {
          if (mounted) Navigator.pop(context);
          if (result['requires_reverification'] == true) {
            _showReverificationNotice();
          } else {
            await _loadStoreInfo();
          }
        } else {
          _showSnackBar(
            result['message'] ?? 'Failed to update store',
            Colors.red,
          );
        }
      },
    );
  }

  void _showEditPersonalDialog() {
    if (_userData == null) {
      _showSnackBar('Personal information not loaded', Colors.orange);
      return;
    }

    _editNameController.text = _userData?['name']?.toString() ?? '';
    _editContactController.text =
        _userData?['contact_number']?.toString() ?? '';
    _editCnicController.text = _userData?['cnic']?.toString() ?? '';
    _editAddressController.text = _userData?['address']?.toString() ?? '';

    setState(() {
      _editNameError = null;
      _editContactError = null;
      _editCnicError = null;
      _editAddressError = null;
    });

    _showProfileEditDialog(
      title: 'Edit Personal Details',
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
          const SizedBox(height: 16),
          _buildEditTextField(
            _editCnicController,
            'CNIC Number',
            Icons.badge,
            errorText: _editCnicError,
            onChanged: (v) => setDialogState(() => _validateCNIC(v)),
          ),
          const SizedBox(height: 16),
          _buildEditTextField(
            _editAddressController,
            'Home Address',
            Icons.home_work,
            maxLines: 2,
            errorText: _editAddressError,
            onChanged: (v) => setDialogState(() => _validateAddress(v)),
          ),
        ],
      ),
      onSave: (setDialogState) async {
        if (widget.userId == null) return;

        final isValid =
            _validateName(_editNameController.text) &
            _validatePhone(_editContactController.text) &
            _validateCNIC(_editCnicController.text) &
            _validateAddress(_editAddressController.text);

        if (!isValid) {
          setDialogState(() {});
          return;
        }

        final result = await ApiService.updateProfile(
          userId: widget.userId!,
          name: _editNameController.text.trim(),
          cnic: _editCnicController.text.trim(),
          contactNumber: _editContactController.text.trim(),
          address: _editAddressController.text.trim(),
          gender: _userData?['gender'],
          profilePicture: _userData?['profile_picture'],
        );

        if (result['success']) {
          if (mounted) Navigator.pop(context);
          if (result['requires_reverification'] == true) {
            _showReverificationNotice();
          } else {
            await _loadUserData();
          }
        } else {
          _showSnackBar('Failed to update personal information', Colors.red);
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
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Center(
            child: Text(
              'Change Password',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
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
              child: Text('Cancel', style: TextStyle(color: lightGray)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (widget.userId == null) return;

                      if (!isPasswordVerified) {
                        if (_currentPasswordController.text.isEmpty) {
                          setDialogState(
                            () => _currentPasswordError =
                                'Current password is required',
                          );
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

                        setDialogState(() {
                          isLoading = false;
                        });

                        if (result['success']) {
                          setDialogState(() => isPasswordVerified = true);
                        } else {
                          setDialogState(
                            () => _currentPasswordError =
                                result['message'] ?? 'Incorrect password',
                          );
                        }
                      } else {
                        bool isValid = true;
                        if (_newPasswordController.text.isEmpty) {
                          _newPasswordError = 'New password is required';
                          isValid = false;
                        } else if (_newPasswordController.text.length < 8) {
                          _newPasswordError = 'Min 8 characters';
                          isValid = false;
                        } else if (!_newPasswordController.text.contains(
                              RegExp(r'[a-zA-Z]'),
                            ) ||
                            !_newPasswordController.text.contains(
                              RegExp(r'[0-9]'),
                            )) {
                          _newPasswordError =
                              'Must contain 1 alphabet and 1 number';
                          isValid = false;
                        } else {
                          _newPasswordError = null;
                        }

                        if (_confirmPasswordController.text !=
                            _newPasswordController.text) {
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
                          _showSnackBar(
                            result['message'] ?? 'Failed to change password',
                            Colors.red,
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: brownColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isPasswordVerified ? 'Save Changes' : 'Next',
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
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
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Center(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          content: SingleChildScrollView(
            child: contentBuilder(context, setDialogState),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: lightGray)),
            ),
            ElevatedButton(
              onPressed: () => onSave(setDialogState),
              style: ElevatedButton.styleFrom(
                backgroundColor: brownColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReverificationNotice() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: whiteColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            'Account Under Review',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        content: const Text(
          'Your profile/store update has been updated and sent to admin for verification. For security, you will now be logged out.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const SignInScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brownColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    String? errorText,
    Function(String)? onChanged,
    bool obscureText = false,
  }) {
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
            labelStyle: TextStyle(color: darkText.withOpacity(0.7)),
            prefixIcon: Icon(icon, color: brownColor, size: 20),
            filled: true,
            fillColor: beigeBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: errorText != null
                  ? const BorderSide(color: Colors.red, width: 1.5)
                  : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: errorText != null
                  ? const BorderSide(color: Colors.red, width: 1.5)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: errorText != null
                  ? const BorderSide(color: Colors.red, width: 2.0)
                  : BorderSide(color: brownColor, width: 2.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({required String label, required String hint}) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: lightGray),
        filled: true,
        fillColor: beigeBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightGray.withOpacity(0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: brownColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: const TextStyle(fontSize: 15),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Jan 2024';
    try {
      final dt = DateTime.parse(date.toString());
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return "${months[dt.month - 1]} ${dt.year}";
    } catch (_) {
      return 'Jan 2024';
    }
  }

  String _obfuscateCNIC(dynamic cnic) {
    if (cnic == null || cnic.toString().isEmpty) return 'Not Provided';
    final s = cnic.toString();
    if (s.length < 10) return s;
    return "${s.substring(0, 5)}-XXXXXXX-${s.substring(s.length - 1)}";
  }

  Widget _buildOrdersView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    List<Map<String, dynamic>> filteredOrders = _orders.where((order) {
      final status = (order['status'] ?? order['order_status'] ?? '')
          .toString()
          .toLowerCase();

      if (_orderSubTab == 'pending') {
        return status == 'pending';
      } else if (_orderSubTab == 'accepted') {
        return ['accepted', 'shipped', 'delivered'].contains(status);
      } else if (_orderSubTab == 'completed') {
        return status == 'completed';
      } else if (_orderSubTab == 'rejected') {
        return status == 'rejected';
      }
      return true;
    }).toList();

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filteredOrders = filteredOrders.where((order) {
        final id = (order['id'] ?? '').toString().toLowerCase();
        return id.contains(query);
      }).toList();
    }

    if (filteredOrders.isEmpty) {
      String message = 'No orders found';
      if (_orderSubTab == 'pending')
        message = 'No pending orders';
      else if (_orderSubTab == 'accepted')
        message = 'No accepted orders';
      else if (_orderSubTab == 'completed')
        message = 'No completed orders';
      else if (_orderSubTab == 'rejected')
        message = 'No rejected orders';

      if (query.isNotEmpty) message = 'No matching orders found';

      return _buildEmptyState(
        icon: Icons.shopping_bag_outlined,
        message: message,
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: ListView.builder(
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          final order = filteredOrders[index];
          return _buildOrderCard(order: order);
        },
      ),
    );
  }

  Widget _buildProductsView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    List<Map<String, dynamic>> filteredProducts = [];
    if (_productSubTab == 'approved') {
      filteredProducts = _products.where((p) {
        final isVerified = p['is_verified'];
        final matches =
            isVerified == 1 || isVerified == '1' || isVerified == true;
        return matches;
      }).toList();
    } else if (_productSubTab == 'pending') {
      filteredProducts = _products.where((p) {
        final isVerified = p['is_verified'];

        final matches =
            isVerified == 0 ||
            isVerified == '0' ||
            isVerified == false ||
            isVerified == null;
        return matches;
      }).toList();
    } else if (_productSubTab == 'rejected') {
      filteredProducts = _products.where((p) {
        final isVerified = p['is_verified'];
        return isVerified == -1 || isVerified == '-1';
      }).toList();
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filteredProducts = filteredProducts.where((p) {
        final name = (p['product_name'] ?? '').toString().toLowerCase();
        return name.contains(query);
      }).toList();
    }

    if (filteredProducts.isEmpty) {
      String message = 'No approved products yet';
      if (_productSubTab == 'pending') {
        message = 'No pending products yet';
      } else if (_productSubTab == 'rejected') {
        message = 'No rejected products yet';
      }

      return _buildEmptyState(
        icon: Icons.inventory_2_outlined,
        message: message,
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      color: beigeBackground,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(product: product);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintsView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    final query = _searchController.text.toLowerCase();
    final normalizedComplaints = _complaints.where((complaint) {
      final status = (complaint['status'] ?? 'review').toString().toLowerCase();
      final matchesFilter = _complaintFilter == 'all'
          ? true
          : _complaintFilter == 'active'
          ? status == 'review'
          : status == _complaintFilter;

      if (!matchesFilter) return false;

      if (query.isEmpty) return true;

      final customerName = (complaint['customer_name'] ?? '')
          .toString()
          .toLowerCase();
      final productName = (complaint['product_name'] ?? '')
          .toString()
          .toLowerCase();
      final issue = (complaint['issue'] ?? '').toString().toLowerCase();
      final description = (complaint['description'] ?? '')
          .toString()
          .toLowerCase();
      return customerName.contains(query) ||
          productName.contains(query) ||
          issue.contains(query) ||
          description.contains(query);
    }).toList();

    final filteredComplaints =
        List<Map<String, dynamic>>.from(normalizedComplaints)..sort((a, b) {
          final dateA =
              DateTime.tryParse((a['created_at'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final dateB =
              DateTime.tryParse((b['created_at'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return dateB.compareTo(dateA);
        });

    final emptyMessage = query.isEmpty
        ? (_complaintFilter == 'all'
              ? 'No complaints yet'
              : 'No complaints match this filter')
        : 'No matching complaints';

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      color: beigeBackground,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: Container(
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer Complaints',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Monitor and review every complaint linked to your store',
                              style: TextStyle(fontSize: 13, color: lightGray),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.end,
                      children: [
                        _buildComplaintFilterChip('All', 'all'),
                        _buildComplaintFilterChip('Active', 'active'),
                        _buildComplaintFilterChip('Completed', 'completed'),
                        _buildComplaintFilterChip('Rejected', 'rejected'),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: lightGray.withOpacity(0.16)),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredComplaints.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                          child: _buildEmptyState(
                            icon: Icons.feedback_outlined,
                            message: emptyMessage,
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: isMobile ? 1200 : 1500,
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dataTableTheme: DataTableThemeData(
                                    headingRowColor:
                                        WidgetStateProperty.resolveWith(
                                          (states) => beigeBackground,
                                        ),
                                    dividerThickness: 1.1,
                                    dataRowMinHeight: 58,
                                    dataRowMaxHeight: 72,
                                    headingTextStyle: TextStyle(
                                      color: brownColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                    dataTextStyle: TextStyle(
                                      color: darkText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                child: DataTable(
                                  columnSpacing: isMobile ? 16 : 22,
                                  columns: const [
                                    DataColumn(label: Text('Complaint ID')),
                                    DataColumn(label: Text('Customer')),
                                    DataColumn(label: Text('Product')),
                                    DataColumn(label: Text('Order')),
                                    DataColumn(label: Text('Product ID')),
                                    DataColumn(label: Text('Store ID')),
                                    DataColumn(label: Text('User ID')),
                                    DataColumn(label: Text('Issue')),
                                    DataColumn(label: Text('Description')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Admin Decision')),
                                    DataColumn(
                                      label: Text('Admin Verification'),
                                    ),
                                    DataColumn(label: Text('Admin Comment')),
                                    DataColumn(label: Text('Refund Amount')),
                                    DataColumn(label: Text('Images')),
                                    DataColumn(label: Text('Filed On')),
                                  ],
                                  rows: filteredComplaints.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final complaint = entry.value;
                                    final complaintId =
                                        complaint['complaint_id'] ?? 'N/A';
                                    final customerName =
                                        complaint['customer_name'] ??
                                        'Customer';
                                    final productName =
                                        complaint['product_name'] ?? 'Product';
                                    final issue = complaint['issue'] ?? 'Issue';
                                    final status =
                                        (complaint['status'] ?? 'review')
                                            .toString()
                                            .toLowerCase();
                                    final orderId =
                                        complaint['order_id'] ?? 'N/A';
                                    final productId =
                                        complaint['product_id'] ?? 'N/A';
                                    final storeId =
                                        complaint['store_id'] ?? 'N/A';
                                    final userId =
                                        complaint['user_id'] ?? 'N/A';
                                    final description =
                                        complaint['description'] ??
                                        'No description provided';
                                    final adminDecision =
                                        complaint['admin_decision'] ?? '—';
                                    final adminVerification =
                                        complaint['admin_verification'] ?? '—';
                                    final adminComment =
                                        complaint['admin_comment'] ?? '—';
                                    final refundAmount =
                                        complaint['refund_amount'] ?? '0.00';
                                    final images =
                                        complaint['images'] != null &&
                                            complaint['images']
                                                .toString()
                                                .isNotEmpty
                                        ? 'Yes'
                                        : 'No';
                                    final createdAt = complaint['created_at'];

                                    return DataRow(
                                      color: WidgetStateProperty.resolveWith((
                                        states,
                                      ) {
                                        return index.isEven
                                            ? Colors.white
                                            : const Color(0xFFF7EFE6);
                                      }),
                                      cells: [
                                        DataCell(Text('#$complaintId')),
                                        DataCell(
                                          Text(
                                            customerName,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            productName,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(Text('#$orderId')),
                                        DataCell(
                                          Text(
                                            productId.toString(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            storeId.toString(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            userId.toString(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            issue,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 220,
                                            child: Text(
                                              description,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          _buildComplaintStatusBadge(status),
                                        ),
                                        DataCell(
                                          Text(
                                            adminDecision.toString(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            adminVerification.toString(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 220,
                                            child: Text(
                                              adminComment.toString(),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            'Rs. $refundAmount',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            images,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(
                                          Text(_formatComplaintDate(createdAt)),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
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
  }

  Widget _buildComplaintFilterChip(String label, String value) {
    final isSelected = _complaintFilter == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => setState(() => _complaintFilter = value),
      selectedColor: brownColor.withOpacity(0.16),
      backgroundColor: const Color(0xFFF7EFE6),
      side: BorderSide(
        color: isSelected
            ? brownColor.withOpacity(0.45)
            : const Color(0xFFE6D8C6),
      ),
      labelStyle: TextStyle(
        color: isSelected ? brownColor : const Color(0xFF6D4C41),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
    );
  }

  Widget _buildComplaintStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'completed') color = Colors.green;
    if (status == 'rejected') color = Colors.red;
    if (status == 'review') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<dynamic> _decodeComplaintImages(dynamic images) {
    if (images == null || images.toString().isEmpty) {
      return [];
    }
    try {
      return jsonDecode(images.toString()) as List<dynamic>;
    } catch (_) {
      return images
          .toString()
          .split(',')
          .where((item) => item.isNotEmpty)
          .toList();
    }
  }

  String _formatComplaintDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return date.toString();
    }
  }

  Widget _buildMessagesView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    final query = _searchController.text.toLowerCase();
    final filteredChats = query.isEmpty
        ? _chats
        : _chats.where((chat) {
            final otherUserName = (chat['other_user_name'] ?? '')
                .toString()
                .toLowerCase();
            final lastMessage = (chat['last_message'] ?? '')
                .toString()
                .toLowerCase();
            return otherUserName.contains(query) || lastMessage.contains(query);
          }).toList();

    if (filteredChats.isEmpty) {
      return _buildEmptyState(
        icon: Icons.chat_bubble_outline,
        message: 'No messages yet',
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      color: beigeBackground,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView.builder(
            itemCount: filteredChats.length,
            itemBuilder: (context, index) {
              final chat = filteredChats[index];
              return _buildChatCard(chat);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: brownColor,
              onPrimary: Colors.white,
              onSurface: darkText,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: brownColor),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        _promotionStartDateError = null;
        _promotionEndDateError = null;
      });
    }
  }

  void _savePromotionLocally(
    String title,
    int discount,
    String startDateStr,
    String endDateStr,
  ) {
    setState(() {
      final localPromo = {
        'promotion_id': DateTime.now().millisecondsSinceEpoch,
        'title': title,
        'discount': discount,
        'start_date': startDateStr,
        'end_date': endDateStr,
        'product_names': _products
            .where((p) => _selectedProductIds.contains(p['product_id']))
            .map((p) => p['product_name'])
            .join(', '),
      };
      _promotions.insert(0, localPromo);

      _promotionTitleController.clear();
      _promotionDiscountController.clear();
      _promotionStartDateController.clear();
      _promotionEndDateController.clear();
      _selectedProductIds.clear();

      _onPromotionSubTabChanged('active');
    });
  }

  Future<void> _handleSavePromotion() async {
    setState(() {
      _promotionTitleError = null;
      _promotionDiscountError = null;
      _promotionStartDateError = null;
      _promotionEndDateError = null;
      _productsError = null;
    });

    final title = _promotionTitleController.text.trim();
    final discountStr = _promotionDiscountController.text.trim();
    final startDateStr = _promotionStartDateController.text.trim();
    final endDateStr = _promotionEndDateController.text.trim();

    bool hasError = false;

    if (title.isEmpty) {
      _promotionTitleError = 'Title is required';
      hasError = true;
    } else if (title.length >= 20) {
      _promotionTitleError = 'Title must be less than 20 characters';
      hasError = true;
    } else if (!RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(title)) {
      _promotionTitleError = 'Letters and numbers only';
      hasError = true;
    }

    int? discount;
    if (discountStr.isEmpty) {
      _promotionDiscountError = 'Discount is required';
      hasError = true;
    } else {
      discount = int.tryParse(discountStr);
      if (discount == null) {
        _promotionDiscountError = 'Numbers only';
        hasError = true;
      } else if (discount <= 0 || discount > 100) {
        _promotionDiscountError = 'Must be between 1 and 100';
        hasError = true;
      }
    }

    DateTime? startDate;
    DateTime? endDate;
    if (startDateStr.isEmpty) {
      _promotionStartDateError = 'Start date is required';
      hasError = true;
    } else {
      try {
        startDate = DateTime.parse(startDateStr);
      } catch (_) {
        _promotionStartDateError = 'Invalid start date';
        hasError = true;
      }
    }

    if (endDateStr.isEmpty) {
      _promotionEndDateError = 'End date is required';
      hasError = true;
    } else {
      try {
        endDate = DateTime.parse(endDateStr);
      } catch (_) {
        _promotionEndDateError = 'Invalid end date';
        hasError = true;
      }
    }

    if (startDate != null && endDate != null) {
      if (endDate.isBefore(startDate) || endDate.isAtSameMomentAs(startDate)) {
        _promotionEndDateError = 'End date must be after start date';
        hasError = true;
      }
    }

    if (_selectedProductIds.isEmpty) {
      _productsError = 'Select at least one product';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    final storeId =
        _storeInfo?['store_id'] ??
        _storeInfo?['store_Id'] ??
        _storeInfo?['storeId'] ??
        _storeInfo?['id'];

    if (storeId == null) {
      _showSnackBar('Store ID not found', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await ApiService.createPromotion(
        storeId: storeId,
        title: title,
        discount: discount!,
        startDate: startDateStr,
        endDate: endDateStr,
        productIds: _selectedProductIds,
      );

      if (res['success']) {
        _promotionTitleController.clear();
        _promotionDiscountController.clear();
        _promotionStartDateController.clear();
        _promotionEndDateController.clear();
        _selectedProductIds.clear();

        _onPromotionSubTabChanged('active');
        await _loadPromotions();
      } else {
        _showSnackBar(
          res['message'] ?? 'Failed to save promotion. Saving locally.',
          Colors.orange,
        );
        _savePromotionLocally(title, discount!, startDateStr, endDateStr);
      }
    } catch (e) {
      _showSnackBar('Error saving promotion. Saving locally.', Colors.orange);
      _savePromotionLocally(title, discount!, startDateStr, endDateStr);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildPromotionFormContent(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Promotion',
          style: TextStyle(
            fontSize: isMobile ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Set up a promotion campaign with a discount and schedule.',
          style: TextStyle(fontSize: isMobile ? 13 : 14, color: lightGray),
        ),
        SizedBox(height: isMobile ? 24 : 32),
        _buildFormField(
          label: 'Promotion Title',
          controller: _promotionTitleController,
          isMobile: isMobile,
          error: _promotionTitleError,
          onChanged: () {
            setState(() {
              _promotionTitleError = null;
            });
          },
        ),
        SizedBox(height: isMobile ? 20 : 24),
        _buildFormField(
          label: 'Discount (%)',
          controller: _promotionDiscountController,
          isMobile: isMobile,
          keyboardType: TextInputType.number,
          error: _promotionDiscountError,
          onChanged: () {
            setState(() {
              _promotionDiscountError = null;
            });
          },
        ),
        SizedBox(height: isMobile ? 20 : 24),
        _buildFormField(
          label: 'Start Date',
          controller: _promotionStartDateController,
          isMobile: isMobile,
          readOnly: true,
          onTap: () => _selectDate(context, _promotionStartDateController),
          error: _promotionStartDateError,
        ),
        SizedBox(height: isMobile ? 20 : 24),
        _buildFormField(
          label: 'End Date',
          controller: _promotionEndDateController,
          isMobile: isMobile,
          readOnly: true,
          onTap: () => _selectDate(context, _promotionEndDateController),
          error: _promotionEndDateError,
        ),
      ],
    );
  }

  Widget _buildPromotionSidebar(
    bool isMobile,
    List<Map<String, dynamic>> activeProducts,
  ) {
    return SizedBox(
      width: isMobile ? double.infinity : 380,
      height: isMobile ? null : 560,
      child: Container(
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
              'Select Products',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select active products to apply this promotion.',
              style: TextStyle(fontSize: isMobile ? 12 : 13, color: lightGray),
            ),
            const SizedBox(height: 16),
            // Promotion product filters: Select All + category chips
            Builder(
              builder: (context) {
                final categories = activeProducts
                    .map((p) => (p['category'] ?? 'Uncategorized').toString())
                    .toSet()
                    .toList();
                categories.sort();
                final filteredProducts = activeProducts.where((p) {
                  if (_promotionCategoryFilter == 'all') return true;
                  final cat = (p['category'] ?? 'Uncategorized').toString();
                  return cat.toLowerCase() ==
                      _promotionCategoryFilter.toLowerCase();
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _productsError = null;
                              final ids = filteredProducts
                                  .map((p) => p['product_id'] ?? 0)
                                  .whereType<int>()
                                  .toList();
                              final allSelected = ids.every(
                                (id) => _selectedProductIds.contains(id),
                              );
                              if (allSelected) {
                                // deselect filtered
                                _selectedProductIds.removeWhere(
                                  (id) => ids.contains(id),
                                );
                              } else {
                                // select all filtered
                                for (final id in ids) {
                                  if (!_selectedProductIds.contains(id))
                                    _selectedProductIds.add(id);
                                }
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: beigeBackground,
                            foregroundColor: darkText,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            side: BorderSide.none,
                          ),
                          child: Text(
                            'Select All',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('All'),
                                  selected: _promotionCategoryFilter == 'all',
                                  onSelected: (_) {
                                    setState(
                                      () => _promotionCategoryFilter = 'all',
                                    );
                                  },
                                  backgroundColor: beigeBackground,
                                  selectedColor: brownColor,
                                  showCheckmark: false,
                                  labelStyle: TextStyle(
                                    color: _promotionCategoryFilter == 'all'
                                        ? whiteColor
                                        : darkText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  pressElevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  side: BorderSide(color: Colors.transparent),
                                ),
                                const SizedBox(width: 8),
                                ...categories.map(
                                  (cat) => Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(cat),
                                      selected:
                                          _promotionCategoryFilter
                                              .toLowerCase() ==
                                          cat.toLowerCase(),
                                      onSelected: (_) {
                                        setState(
                                          () => _promotionCategoryFilter = cat,
                                        );
                                      },
                                      backgroundColor: beigeBackground,
                                      selectedColor: brownColor,
                                      showCheckmark: false,
                                      labelStyle: TextStyle(
                                        color:
                                            _promotionCategoryFilter
                                                    .toLowerCase() ==
                                                cat.toLowerCase()
                                            ? whiteColor
                                            : darkText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      pressElevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      side: BorderSide(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // pass filteredProducts down via context using a closure variable
                    SizedBox(width: 0, height: 0),
                  ],
                );
              },
            ),
            if (_productsError != null) ...[
              Text(
                _productsError!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (isMobile) ...[
              (() {
                final filteredProductsMobile = activeProducts.where((p) {
                  if (_promotionCategoryFilter == 'all') return true;
                  final cat = (p['category'] ?? 'Uncategorized').toString();
                  return cat.toLowerCase() ==
                      _promotionCategoryFilter.toLowerCase();
                }).toList();

                return Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: filteredProductsMobile.isEmpty
                      ? Center(
                          child: Text(
                            'No active products available\n(Must have is_visible = 1)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: lightGray,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredProductsMobile.length,
                          itemBuilder: (context, index) {
                            final product = filteredProductsMobile[index];
                            final productId = product['product_id'] ?? 0;
                            final isSelected = _selectedProductIds.contains(
                              productId,
                            );
                            final imageUrls = _parseProductImages(
                              product['product_images'],
                            );
                            final imageUrl = imageUrls.isNotEmpty
                                ? imageUrls[0]
                                : '';

                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  _productsError = null;
                                  if (value == true) {
                                    _selectedProductIds.add(productId);
                                  } else {
                                    _selectedProductIds.remove(productId);
                                  }
                                });
                              },
                              title: Text(
                                product['product_name'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: darkText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Rs. ${product['price']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: brownColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              secondary: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: beigeBackground,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: _buildImageWidget(imageUrl),
                                ),
                              ),
                              activeColor: brownColor,
                              checkColor: whiteColor,
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                );
              })(),
            ] else ...[
              (() {
                final filteredProducts = activeProducts.where((p) {
                  if (_promotionCategoryFilter == 'all') return true;
                  final cat = (p['category'] ?? 'Uncategorized').toString();
                  return cat.toLowerCase() ==
                      _promotionCategoryFilter.toLowerCase();
                }).toList();

                return Expanded(
                  child: filteredProducts.isEmpty
                      ? Center(
                          child: Text(
                            'No active products available\n(Must have is_visible = 1)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: lightGray,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final productId = product['product_id'] ?? 0;
                            final isSelected = _selectedProductIds.contains(
                              productId,
                            );
                            final imageUrls = _parseProductImages(
                              product['product_images'],
                            );
                            final imageUrl = imageUrls.isNotEmpty
                                ? imageUrls[0]
                                : '';

                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  _productsError = null;
                                  if (value == true) {
                                    _selectedProductIds.add(productId);
                                  } else {
                                    _selectedProductIds.remove(productId);
                                  }
                                });
                              },
                              title: Text(
                                product['product_name'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: darkText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Rs. ${product['price']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: brownColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              secondary: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: beigeBackground,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: _buildImageWidget(imageUrl),
                                ),
                              ),
                              activeColor: brownColor,
                              checkColor: whiteColor,
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                );
              })(),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSavePromotion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brownColor,
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save Promotion',
                  style: TextStyle(
                    color: whiteColor,
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _parseProductImages(dynamic images) {
    if (images == null) return [];
    if (images is List) return images.map((e) => e.toString()).toList();
    if (images is String) {
      try {
        final decoded = jsonDecode(images);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
      return [images];
    }
    return [];
  }

  void _startEditingPromotion(Map<String, dynamic> promotion) {
    setState(() {
      _isEditingPromotion = true;
      _editingPromotionId = promotion['promotion_id'] is int
          ? promotion['promotion_id']
          : int.tryParse(promotion['promotion_id'].toString());

      _promotionTitleController.text = promotion['title']?.toString() ?? '';
      _promotionDiscountController.text =
          promotion['discount']?.toString() ?? '';

      final startDate = promotion['start_date'] != null
          ? promotion['start_date'].toString().split('T')[0]
          : '';
      final endDate = promotion['end_date'] != null
          ? promotion['end_date'].toString().split('T')[0]
          : '';
      _promotionStartDateController.text = startDate;
      _promotionEndDateController.text = endDate;

      final productIdsString = promotion['product_ids']?.toString() ?? '';
      _selectedProductIds = productIdsString
          .split(',')
          .where((id) => id.trim().isNotEmpty)
          .map((id) => int.tryParse(id.trim()))
          .where((id) => id != null)
          .cast<int>()
          .toList();

      _promotionSubTab = 'edit';
      _promotionTitleError = null;
      _promotionDiscountError = null;
      _promotionStartDateError = null;
      _promotionEndDateError = null;
      _productsError = null;
    });
  }

  void _cancelEditingPromotion() {
    setState(() {
      _promotionTitleController.clear();
      _promotionDiscountController.clear();
      _promotionStartDateController.clear();
      _promotionEndDateController.clear();
      _selectedProductIds.clear();
      _isEditingPromotion = false;
      _editingPromotionId = null;
      _promotionSubTab = 'active';
    });
  }

  Future<void> _handleUpdatePromotion() async {
    final promotionId = _editingPromotionId;
    if (promotionId == null) return;

    final title = _promotionTitleController.text.trim();
    final discountStr = _promotionDiscountController.text.trim();
    final startDateStr = _promotionStartDateController.text.trim();
    final endDateStr = _promotionEndDateController.text.trim();

    bool hasError = false;

    if (title.isEmpty) {
      _promotionTitleError = 'Title is required';
      hasError = true;
    }

    final discount = int.tryParse(discountStr);
    if (discountStr.isEmpty ||
        discount == null ||
        discount <= 0 ||
        discount > 100) {
      _promotionDiscountError = 'Enter a valid discount (1-100)';
      hasError = true;
    }

    if (startDateStr.isEmpty) {
      _promotionStartDateError = 'Start date is required';
      hasError = true;
    }

    if (endDateStr.isEmpty) {
      _promotionEndDateError = 'End date is required';
      hasError = true;
    }

    if (startDateStr.isNotEmpty && endDateStr.isNotEmpty) {
      final startDate = DateTime.parse(startDateStr);
      final endDate = DateTime.parse(endDateStr);
      if (endDate.isBefore(startDate) || endDate.isAtSameMomentAs(startDate)) {
        _promotionEndDateError = 'End date must be after start date';
        hasError = true;
      }
    }

    if (_selectedProductIds.isEmpty) {
      _productsError = 'Select at least one product';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await ApiService.updatePromotion(
        promotionId: promotionId,
        title: title,
        discount: discount!,
        startDate: startDateStr,
        endDate: endDateStr,
        productIds: _selectedProductIds,
      );

      if (res['success']) {
        _promotionTitleController.clear();
        _promotionDiscountController.clear();
        _promotionStartDateController.clear();
        _promotionEndDateController.clear();
        _selectedProductIds.clear();

        setState(() {
          _isEditingPromotion = false;
          _editingPromotionId = null;
        });

        _onPromotionSubTabChanged('active');
        await _loadPromotions();
      } else {
        _showSnackBar(
          res['message'] ?? 'Failed to update promotion',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Error updating promotion', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePromotionStatus(Map<String, dynamic> promotion) async {
    final promotionId = promotion['promotion_id'] is int
        ? promotion['promotion_id']
        : int.tryParse(promotion['promotion_id'].toString());
    if (promotionId == null) return;

    final currentStatus = promotion['status'] ?? 1;
    final currentStatusInt = int.tryParse(currentStatus.toString()) ?? 1;
    final newStatus = currentStatusInt == 1 ? 0 : 1;

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await ApiService.updatePromotionStatus(
        promotionId,
        newStatus,
      );
      if (res['success']) {
        setState(() {
          promotion['status'] = newStatus;
        });

        await _loadPromotions();
      } else {
        _showSnackBar(res['message'] ?? 'Failed to update status', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error updating promotion status', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePromotion(Map<String, dynamic> promotion) async {
    final promotionId = promotion['promotion_id'] is int
        ? promotion['promotion_id']
        : int.tryParse(promotion['promotion_id'].toString());
    if (promotionId == null) return;

    _logoutDialogAnimationController.forward();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
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
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: isMobile
                        ? 24
                        : MediaQuery.of(context).size.width * 0.1,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 500,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: brownColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: brownColor,
                              size: 32,
                            ),
                          ),
                          SizedBox(height: isMobile ? 16 : 20),
                          Text(
                            'Delete Promotion',
                            style: TextStyle(
                              fontSize: isMobile ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: isMobile ? 8 : 12),
                          Text(
                            'Are you sure you want to delete this promotion? This action cannot be undone.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              color: lightGray,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: isMobile ? 20 : 28),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    _logoutDialogAnimationController.reverse();
                                    Navigator.of(context).pop();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: lightGray.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 20 : 24,
                                      vertical: isMobile ? 14 : 16,
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: darkText,
                                      fontSize: isMobile ? 15 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: isMobile ? 12 : 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    _logoutDialogAnimationController.reverse();
                                    Navigator.of(context).pop();

                                    setState(() {
                                      _isLoading = true;
                                    });

                                    try {
                                      final res =
                                          await ApiService.updatePromotionStatus(
                                            promotionId,
                                            -1,
                                          );
                                      if (res['success']) {
                                        await _loadPromotions();
                                      } else {
                                        _showSnackBar(
                                          res['message'] ??
                                              'Failed to delete promotion',
                                          Colors.red,
                                        );
                                      }
                                    } catch (e) {
                                      _showSnackBar(
                                        'Error deleting promotion',
                                        Colors.red,
                                      );
                                    } finally {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brownColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 20 : 24,
                                      vertical: isMobile ? 14 : 16,
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 15 : 16,
                                      fontWeight: FontWeight.w700,
                                    ),
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

  Widget _buildPromotionSidebarForEdit(
    bool isMobile,
    List<Map<String, dynamic>> activeProducts,
  ) {
    return SizedBox(
      width: isMobile ? double.infinity : 380,
      height: isMobile ? null : 560,
      child: Container(
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
              'Select Products',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select active products to apply this promotion.',
              style: TextStyle(fontSize: isMobile ? 12 : 13, color: lightGray),
            ),
            const SizedBox(height: 16),
            // Promotion product filters: Select All + category chips (same as Create)
            Builder(
              builder: (context) {
                final categories = activeProducts
                    .map((p) => (p['category'] ?? 'Uncategorized').toString())
                    .toSet()
                    .toList();
                categories.sort();
                final filteredProducts = activeProducts.where((p) {
                  if (_promotionCategoryFilter == 'all') return true;
                  final cat = (p['category'] ?? 'Uncategorized').toString();
                  return cat.toLowerCase() ==
                      _promotionCategoryFilter.toLowerCase();
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _productsError = null;
                              final ids = filteredProducts
                                  .map((p) => p['product_id'] ?? 0)
                                  .whereType<int>()
                                  .toList();
                              final allSelected = ids.every(
                                (id) => _selectedProductIds.contains(id),
                              );
                              if (allSelected) {
                                // deselect filtered
                                _selectedProductIds.removeWhere(
                                  (id) => ids.contains(id),
                                );
                              } else {
                                // select all filtered
                                for (final id in ids) {
                                  if (!_selectedProductIds.contains(id))
                                    _selectedProductIds.add(id);
                                }
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: beigeBackground,
                            foregroundColor: darkText,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            side: BorderSide.none,
                          ),
                          child: Text(
                            'Select All',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('All'),
                                  selected: _promotionCategoryFilter == 'all',
                                  onSelected: (_) {
                                    setState(
                                      () => _promotionCategoryFilter = 'all',
                                    );
                                  },
                                  backgroundColor: beigeBackground,
                                  selectedColor: brownColor,
                                  showCheckmark: false,
                                  labelStyle: TextStyle(
                                    color: _promotionCategoryFilter == 'all'
                                        ? whiteColor
                                        : darkText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  pressElevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  side: BorderSide(color: Colors.transparent),
                                ),
                                const SizedBox(width: 8),
                                ...categories.map(
                                  (cat) => Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(cat),
                                      selected:
                                          _promotionCategoryFilter
                                              .toLowerCase() ==
                                          cat.toLowerCase(),
                                      onSelected: (_) {
                                        setState(
                                          () => _promotionCategoryFilter = cat,
                                        );
                                      },
                                      backgroundColor: beigeBackground,
                                      selectedColor: brownColor,
                                      showCheckmark: false,
                                      labelStyle: TextStyle(
                                        color:
                                            _promotionCategoryFilter
                                                    .toLowerCase() ==
                                                cat.toLowerCase()
                                            ? whiteColor
                                            : darkText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      pressElevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      side: BorderSide(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // pass filteredProducts down via context using a closure variable
                    SizedBox(width: 0, height: 0),
                  ],
                );
              },
            ),
            if (_productsError != null) ...[
              Text(
                _productsError!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (isMobile)
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: activeProducts.isEmpty
                    ? Center(
                        child: Text(
                          'No active products available\n(Must have is_visible = 1)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: lightGray,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: activeProducts.length,
                        itemBuilder: (context, index) {
                          final product = activeProducts[index];
                          final productId = product['product_id'] ?? 0;
                          final isSelected = _selectedProductIds.contains(
                            productId,
                          );
                          final imageUrls = _parseProductImages(
                            product['product_images'],
                          );
                          final imageUrl = imageUrls.isNotEmpty
                              ? imageUrls[0]
                              : '';

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                _productsError = null;
                                if (value == true) {
                                  _selectedProductIds.add(productId);
                                } else {
                                  _selectedProductIds.remove(productId);
                                }
                              });
                            },
                            title: Text(
                              product['product_name'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: darkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Rs. ${product['price']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: brownColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            secondary: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: beigeBackground,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: _buildImageWidget(imageUrl),
                              ),
                            ),
                            activeColor: brownColor,
                            checkColor: whiteColor,
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
              )
            else
              Expanded(
                child: activeProducts.isEmpty
                    ? Center(
                        child: Text(
                          'No active products available\n(Must have is_visible = 1)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: lightGray,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: activeProducts.length,
                        itemBuilder: (context, index) {
                          final product = activeProducts[index];
                          final productId = product['product_id'] ?? 0;
                          final isSelected = _selectedProductIds.contains(
                            productId,
                          );
                          final imageUrls = _parseProductImages(
                            product['product_images'],
                          );
                          final imageUrl = imageUrls.isNotEmpty
                              ? imageUrls[0]
                              : '';

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                _productsError = null;
                                if (value == true) {
                                  _selectedProductIds.add(productId);
                                } else {
                                  _selectedProductIds.remove(productId);
                                }
                              });
                            },
                            title: Text(
                              product['product_name'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: darkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Rs. ${product['price']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: brownColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            secondary: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: beigeBackground,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: _buildImageWidget(imageUrl),
                              ),
                            ),
                            activeColor: brownColor,
                            checkColor: whiteColor,
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleUpdatePromotion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brownColor,
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Update Promotion',
                  style: TextStyle(
                    color: whiteColor,
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionsView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (_promotionSubTab == 'edit') {
      final activeProducts = _products.where((p) {
        final isVisible = p['is_visible'];
        return isVisible == 1 || isVisible == '1' || isVisible == true;
      }).toList();

      return Container(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        color: ProfileStyles.beigeBackgroundColor,
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isMobile ? 20 : 32),
                          decoration: BoxDecoration(
                            color: ProfileStyles.whiteColor,
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Edit Promotion',
                                    style: TextStyle(
                                      fontSize: isMobile ? 20 : 24,
                                      fontWeight: FontWeight.bold,
                                      color: darkText,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _cancelEditingPromotion,
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text('Cancel'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Update this promotion campaign details.',
                                style: TextStyle(
                                  fontSize: isMobile ? 13 : 14,
                                  color: lightGray,
                                ),
                              ),
                              SizedBox(height: isMobile ? 24 : 32),
                              _buildFormField(
                                label: 'Promotion Title',
                                controller: _promotionTitleController,
                                isMobile: isMobile,
                                error: _promotionTitleError,
                                onChanged: () {
                                  setState(() {
                                    _promotionTitleError = null;
                                  });
                                },
                              ),
                              SizedBox(height: isMobile ? 20 : 24),
                              _buildFormField(
                                label: 'Discount (%)',
                                controller: _promotionDiscountController,
                                isMobile: isMobile,
                                keyboardType: TextInputType.number,
                                error: _promotionDiscountError,
                                onChanged: () {
                                  setState(() {
                                    _promotionDiscountError = null;
                                  });
                                },
                              ),
                              SizedBox(height: isMobile ? 20 : 24),
                              _buildFormField(
                                label: 'Start Date',
                                controller: _promotionStartDateController,
                                isMobile: isMobile,
                                readOnly: true,
                                onTap: () => _selectDate(
                                  context,
                                  _promotionStartDateController,
                                ),
                                error: _promotionStartDateError,
                              ),
                              SizedBox(height: isMobile ? 20 : 24),
                              _buildFormField(
                                label: 'End Date',
                                controller: _promotionEndDateController,
                                isMobile: isMobile,
                                readOnly: true,
                                onTap: () => _selectDate(
                                  context,
                                  _promotionEndDateController,
                                ),
                                error: _promotionEndDateError,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildPromotionSidebarForEdit(isMobile, activeProducts),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 560,
                            padding: EdgeInsets.all(isMobile ? 20 : 32),
                            decoration: BoxDecoration(
                              color: ProfileStyles.whiteColor,
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
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Edit Promotion',
                                      style: TextStyle(
                                        fontSize: isMobile ? 20 : 24,
                                        fontWeight: FontWeight.bold,
                                        color: darkText,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _cancelEditingPromotion,
                                      icon: const Icon(Icons.close, size: 16),
                                      label: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Update this promotion campaign details.',
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : 14,
                                    color: lightGray,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 24 : 32),
                                _buildFormField(
                                  label: 'Promotion Title',
                                  controller: _promotionTitleController,
                                  isMobile: isMobile,
                                  error: _promotionTitleError,
                                  onChanged: () {
                                    setState(() {
                                      _promotionTitleError = null;
                                    });
                                  },
                                ),
                                SizedBox(height: isMobile ? 20 : 24),
                                _buildFormField(
                                  label: 'Discount (%)',
                                  controller: _promotionDiscountController,
                                  isMobile: isMobile,
                                  keyboardType: TextInputType.number,
                                  error: _promotionDiscountError,
                                  onChanged: () {
                                    setState(() {
                                      _promotionDiscountError = null;
                                    });
                                  },
                                ),
                                SizedBox(height: isMobile ? 20 : 24),
                                _buildFormField(
                                  label: 'Start Date',
                                  controller: _promotionStartDateController,
                                  isMobile: isMobile,
                                  readOnly: true,
                                  onTap: () => _selectDate(
                                    context,
                                    _promotionStartDateController,
                                  ),
                                  error: _promotionStartDateError,
                                ),
                                SizedBox(height: isMobile ? 20 : 24),
                                _buildFormField(
                                  label: 'End Date',
                                  controller: _promotionEndDateController,
                                  isMobile: isMobile,
                                  readOnly: true,
                                  onTap: () => _selectDate(
                                    context,
                                    _promotionEndDateController,
                                  ),
                                  error: _promotionEndDateError,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: isMobile ? 16 : 24),
                        _buildPromotionSidebarForEdit(isMobile, activeProducts),
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    if (_promotionSubTab == 'create') {
      final activeProducts = _products.where((p) {
        final isVisible = p['is_visible'];
        return isVisible == 1 || isVisible == '1' || isVisible == true;
      }).toList();

      return Container(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        color: ProfileStyles.beigeBackgroundColor,
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isMobile ? 20 : 32),
                          decoration: BoxDecoration(
                            color: ProfileStyles.whiteColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _buildPromotionFormContent(isMobile),
                        ),
                        const SizedBox(height: 20),
                        _buildPromotionSidebar(isMobile, activeProducts),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 560,
                            padding: EdgeInsets.all(isMobile ? 20 : 32),
                            decoration: BoxDecoration(
                              color: ProfileStyles.whiteColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _buildPromotionFormContent(isMobile),
                          ),
                        ),
                        SizedBox(width: isMobile ? 16 : 24),
                        _buildPromotionSidebar(isMobile, activeProducts),
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    if (_isPromotionsLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(brownColor),
        ),
      );
    }

    final activePromotions = _promotions.where((p) {
      final status = p['status'];
      return status == 1 || status == '1' || status == null;
    }).toList();

    final inactivePromotions = _promotions.where((p) {
      final status = p['status'];
      return status == 0 || status == '0';
    }).toList();

    final filteredPromotions = _promotionSubTab == 'active'
        ? activePromotions
        : inactivePromotions;

    if (filteredPromotions.isEmpty) {
      final message = _promotionSubTab == 'active'
          ? 'No active promotions yet'
          : 'No inactive promotions yet';
      return _buildEmptyState(icon: Icons.campaign_outlined, message: message);
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      color: ProfileStyles.beigeBackgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView.builder(
            itemCount: filteredPromotions.length,
            itemBuilder: (context, index) {
              final promotion = filteredPromotions[index];
              final title = promotion['title'] ?? 'Untitled promotion';
              final discount = promotion['discount'] ?? 0;
              final startDate = promotion['start_date'] != null
                  ? promotion['start_date'].toString().split('T')[0]
                  : '';
              final endDate = promotion['end_date'] != null
                  ? promotion['end_date'].toString().split('T')[0]
                  : '';

              final status = promotion['status'];
              final isCurrentlyActive =
                  status == 1 || status == '1' || status == null;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: whiteColor,
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
                            decoration: BoxDecoration(
                              color: brownColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.campaign_outlined,
                              color: brownColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: darkText,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$discount% OFF',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 12,
                                      color: lightGray,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$startDate  to  $endDate',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: lightGray,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: lightGray.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              _showPromotionDetails(promotion);
                            },
                            icon: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: brownColor,
                            ),
                            label: Text(
                              'Review',
                              style: TextStyle(color: brownColor, fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 22,
                              ),
                              minimumSize: const Size(0, 56),
                              side: BorderSide(color: brownColor, width: 1),
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
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChatCard(dynamic chat) {
    final otherUserId = chat['other_user_id'];
    final otherUserName = chat['other_user_name'] ?? 'Unknown User';
    final otherUserAvatar = _extractChatAvatar(chat);
    final lastMessage = chat['last_message'] ?? '';
    final timeAgo = _formatTimeAgo(chat['last_message_time']);
    final isMe = chat['last_message_sender_id'] == widget.userId;

    final isUnread =
        !isMe &&
        (chat['is_read'] == 0 ||
            chat['is_read'] == false ||
            chat['is_read'] == '0' ||
            (chat['unread_count'] != null && chat['unread_count'] > 0) ||
            (chat['is_read'] == null && chat['unread_count'] == null));
    final isRead = !isUnread;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: isRead ? whiteColor : brownColor.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRead
              ? lightGray.withOpacity(0.1)
              : brownColor.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildChatAvatar(avatar: otherUserAvatar, isRead: isRead),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                otherUserName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: darkText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              timeAgo,
              style: TextStyle(
                color: isRead ? lightGray : darkText.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            isMe ? 'You: $lastMessage' : lastMessage,
            style: TextStyle(
              color: isRead ? lightGray : darkText.withOpacity(0.7),
              fontSize: 14,
              fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        onTap: () async {
          if (widget.userId == null) return;
          await _openChatWindow(
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            otherUserAvatar: otherUserAvatar,
          );
        },
      ),
    );
  }

  Future<void> _openChatWindow({
    required int otherUserId,
    required String otherUserName,
    String? otherUserAvatar,
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final shouldOpenFloatingChat = kIsWeb && screenWidth >= 768;

    if (shouldOpenFloatingChat) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        builder: (dialogContext) {
          return Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24, bottom: 0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 380,
                  height: 540,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ChatScreen(
                    currentUserId: widget.userId!,
                    otherUserId: otherUserId,
                    otherUserName: otherUserName,
                    storeLogo: otherUserAvatar,
                    showCloseButton: true,
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            currentUserId: widget.userId!,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            storeLogo: otherUserAvatar,
          ),
        ),
      );
    }

    _loadChats();
  }

  String? _extractChatAvatar(dynamic chat) {
    if (chat is! Map) return null;

    const imageKeys = [
      'other_user_profile_picture',
      'other_user_profile_image',
      'other_user_avatar',
      'other_user_image',
      'profile_picture',
      'profile_image',
      'avatar',
      'image',
      'user_image',
      'user_profile',
      'logo',
      'store_logo',
    ];

    for (final key in imageKeys) {
      final value = chat[key];
      if (value == null) continue;
      final image = value.toString().trim();
      if (image.isNotEmpty && image.toLowerCase() != 'null') {
        return image;
      }
    }
    return null;
  }

  Widget _buildChatAvatar({required String? avatar, required bool isRead}) {
    if (avatar != null && avatar.isNotEmpty) {
      try {
        ImageProvider provider;
        if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
          provider = NetworkImage(avatar);
        } else {
          final bytes = base64Decode(avatar.split(',').last);
          provider = MemoryImage(bytes);
        }

        return CircleAvatar(
          backgroundColor: isRead
              ? brownColor.withOpacity(0.1)
              : brownColor.withOpacity(0.2),
          radius: 24,
          backgroundImage: provider,
        );
      } catch (_) {}
    }

    return CircleAvatar(
      backgroundColor: isRead
          ? brownColor.withOpacity(0.1)
          : brownColor.withOpacity(0.2),
      radius: 24,
      child: Icon(Icons.person, color: brownColor, size: 28),
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
      color: beigeBackground,
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
    final isRead =
        (notification['is_read'] == 1 || notification['is_read'] == '1');
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
            final result = await ApiService.markUserNotificationRead(
              notificationId is int
                  ? notificationId
                  : int.parse(notificationId.toString()),
            );
            if (result['success']) {
              _loadNotifications();
            }
          }

          final lowerTitle = title.toLowerCase();
          final lowerMessage = message.toLowerCase();

          if (lowerTitle.contains('order') || lowerMessage.contains('order')) {
            setState(() {
              _selectedTab = 2;
              _orderSubTab = 'pending';
            });
          } else if (lowerTitle.contains('product') ||
              lowerMessage.contains('product')) {
            if (lowerTitle.contains('approved') ||
                lowerMessage.contains('approved')) {
              setState(() {
                _selectedTab = 1;
                _productSubTab = 'approved';
                _isProductsExpanded = true;
              });
            } else if (lowerTitle.contains('rejected') ||
                lowerMessage.contains('rejected')) {
              setState(() {
                _selectedTab = 1;
                _productSubTab = 'rejected';
                _isProductsExpanded = true;
              });
            } else if (lowerTitle.contains('pending') ||
                lowerMessage.contains('pending')) {
              setState(() {
                _selectedTab = 1;
                _productSubTab = 'pending';
                _isProductsExpanded = true;
              });
            } else {
              _onTabChanged(1);
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: SellerDashboardStyles.notificationCardDecoration(isRead),
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
                      border: Border.all(color: borderColor, width: 2),
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
                        decoration:
                            SellerDashboardStyles.unreadIndicatorDecoration,
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
                      style: SellerDashboardStyles.notificationTitleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: SellerDashboardStyles.notificationMessageStyle(
                        isRead,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeAgo,
                    style: SellerDashboardStyles.notificationTimeStyle,
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
                          final result =
                              await ApiService.deleteUserNotification(
                                notificationId is int
                                    ? notificationId
                                    : int.parse(notificationId.toString()),
                              );
                          if (result['success']) {
                            _loadNotifications();
                            _showSnackBar(
                              'Notification deleted',
                              Colors.black87,
                            );
                          } else {
                            _showSnackBar(
                              result['message'] ?? 'Failed to delete',
                              Colors.red,
                            );
                          }
                        } catch (e) {
                          _showSnackBar('An error occurred', Colors.red);
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

  Widget _buildAddProductView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      color: beigeBackground,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
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
                        child: _currentStep == 1
                            ? _buildVariantsForm(isMobile)
                            : _buildProductFormContent(isMobile),
                      ),
                      SizedBox(height: 20),

                      if (_currentStep == 0) _buildProductSidebar(isMobile),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
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
                          child: _currentStep == 1
                              ? _buildVariantsForm(isMobile)
                              : _buildProductFormContent(isMobile),
                        ),
                      ),
                      if (_currentStep == 0) ...[
                        SizedBox(width: isMobile ? 16 : 24),

                        _buildProductSidebar(isMobile),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    required bool isMobile,
    String? error,
    VoidCallback? onChanged,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
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
              enabled: enabled,
              readOnly: readOnly,
              onTap: onTap,
              keyboardType: keyboardType,
              onChanged: (_) {
                if (error != null && onChanged != null) {
                  onChanged();
                }
              },
              decoration: InputDecoration(
                filled: !enabled,
                fillColor: enabled ? null : lightGray.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: error != null
                        ? Colors.red
                        : lightGray.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: error != null
                        ? Colors.red
                        : lightGray.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: error != null ? Colors.red : brownColor,
                    width: 2,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: lightGray.withOpacity(0.2)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isMobile ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
        if (error != null)
          Positioned(right: 0, top: -8, child: _buildErrorTooltip(error)),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isMobile,
    String? error,
    GlobalKey? fieldKey,
    TextEditingController? controller,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
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
            GestureDetector(
              onTap: () => _showDropdownMenu(
                items: items,
                onChanged: onChanged,
                fieldKey: fieldKey,
                controller: controller,
                label: label,
              ),
              child: AbsorbPointer(
                child: TextFormField(
                  key: fieldKey,
                  controller: controller,
                  readOnly: true,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Select $label',
                    hintStyle: TextStyle(
                      color: lightGray.withOpacity(0.5),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: error != null
                            ? Colors.red
                            : lightGray.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: error != null
                            ? Colors.red
                            : lightGray.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: brownColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    suffixIcon: Icon(
                      Icons.keyboard_arrow_down,
                      color: lightGray.withOpacity(0.6),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (error != null)
          Positioned(right: 0, top: -8, child: _buildErrorTooltip(error)),
      ],
    );
  }

  void _showDropdownMenu({
    required List<String> items,
    required Function(String?) onChanged,
    GlobalKey? fieldKey,
    TextEditingController? controller,
    required String label,
  }) {
    if (fieldKey?.currentContext == null) return;

    final RenderBox renderBox =
        fieldKey!.currentContext!.findRenderObject() as RenderBox;
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
      items: items
          .map(
            (item) => PopupMenuItem<String>(
              value: item,
              child: Container(
                width: size.width,
                alignment: Alignment.centerLeft,
                child: Text(item, style: const TextStyle(fontSize: 14)),
              ),
            ),
          )
          .toList(),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      constraints: BoxConstraints(minWidth: size.width, maxWidth: size.width),
    ).then((selectedValue) {
      if (selectedValue != null) {
        onChanged(selectedValue);
        if (controller != null) {
          controller.text = selectedValue;
        }
      }
    });
  }

  Widget _buildToggleCard({
    required String title,
    required bool value,
    required Function(bool) onChanged,
    String? description,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightGray.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: brownColor,
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                color: lightGray,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductFormContent(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditing ? 'Edit Product Details' : 'Basic Details',
          style: TextStyle(
            fontSize: isMobile ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isEditing
              ? 'Modify the product\'s information'
              : 'Manage the product\'s basic information',
          style: TextStyle(fontSize: isMobile ? 13 : 14, color: lightGray),
        ),
        SizedBox(height: isMobile ? 24 : 32),

        _buildFormField(
          label: 'Product Name',
          controller: _productNameController,
          isMobile: isMobile,
          error: _productNameError,
          onChanged: () {
            setState(() {
              _productNameError = null;
            });
          },
        ),
        SizedBox(height: isMobile ? 20 : 24),
        SizedBox(height: isMobile ? 20 : 24),
        if (isMobile) ...[
          _buildDropdownField(
            label: 'Category',
            value: _selectedCategory,
            items: [
              'Tops',
              'Bottoms',
              'Dresses',
              'Sets',
              'Activewear',
              'Sleepwear',
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
                _categoryController.text = value ?? '';
                _categoryError = null;
              });
            },
            isMobile: isMobile,
            error: _categoryError,
            fieldKey: _categoryFieldKey,
            controller: _categoryController,
          ),
          SizedBox(height: 20),
          _buildDropdownField(
            label: 'Gender',
            value: _selectedGender,
            items: ['Male', 'Female'],
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
                _genderController.text = value ?? '';
                _genderError = null;
              });
            },
            isMobile: isMobile,
            error: _genderError,
            fieldKey: _genderFieldKey,
            controller: _genderController,
          ),
          SizedBox(height: 20),
          _buildFormField(
            label: 'Price (Rs)',
            controller: _minPriceController,
            keyboardType: TextInputType.number,
            isMobile: isMobile,
            error: _priceError,
            onChanged: () {
              setState(() {
                _priceError = null;
              });
            },
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: 'Category',
                  value: _selectedCategory,
                  items: [
                    'Tops',
                    'Bottoms',
                    'Dresses',
                    'Sets',
                    'Activewear',
                    'Sleepwear',
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _categoryController.text = value ?? '';
                      _categoryError = null;
                    });
                  },
                  isMobile: isMobile,
                  error: _categoryError,
                  fieldKey: _categoryFieldKey,
                  controller: _categoryController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  label: 'Gender',
                  value: _selectedGender,
                  items: ['Male', 'Female'],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                      _genderController.text = value ?? '';
                      _genderError = null;
                    });
                  },
                  isMobile: isMobile,
                  error: _genderError,
                  fieldKey: _genderFieldKey,
                  controller: _genderController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField(
                  label: 'Price (Rs)',
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  isMobile: isMobile,
                  error: _priceError,
                  onChanged: () {
                    setState(() {
                      _priceError = null;
                    });
                  },
                ),
              ),
            ],
          ),
        SizedBox(height: isMobile ? 20 : 24),

        Text(
          'Description',
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              onChanged: (_) {
                if (_descriptionError != null) {
                  setState(() {
                    _descriptionError = null;
                  });
                }
              },
              decoration: InputDecoration(
                hintText: 'Enter product description...',
                hintStyle: TextStyle(color: lightGray.withOpacity(0.6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _descriptionError != null
                        ? Colors.red
                        : lightGray.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _descriptionError != null
                        ? Colors.red
                        : lightGray.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _descriptionError != null ? Colors.red : brownColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            if (_descriptionError != null)
              Positioned(
                right: 0,
                top: -8,
                child: _buildErrorTooltip(_descriptionError!),
              ),
          ],
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildImageUploadSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightGray.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product Images',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
              Text(
                '${_productImages.length}/5',
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: lightGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Upload 1-5 product images',
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              color: lightGray,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ...List.generate(_productImages.length, (index) {
                return _buildImagePreview(
                  imagePath: _productImages[index],
                  index: index,
                  isMobile: isMobile,
                );
              }),

              if (_productImages.length < 5)
                _buildAddImageButton(isMobile: isMobile),
            ],
          ),
          if (_imageError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildErrorTooltip(_imageError!),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview({
    required String imagePath,
    required int index,
    required bool isMobile,
  }) {
    return Stack(
      children: [
        Container(
          width: isMobile ? 60 : 75,
          height: isMobile ? 60 : 75,
          decoration: BoxDecoration(
            color: beigeBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: lightGray.withOpacity(0.3), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImageWidget(
              imagePath,
              fit: BoxFit.cover,
              errorWidget: Icon(
                Icons.image,
                color: lightGray,
                size: isMobile ? 24 : 30,
              ),
            ),
          ),
        ),

        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _productImages.removeAt(index);
              });
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: whiteColor, width: 1.5),
              ),
              child: Icon(Icons.close, color: whiteColor, size: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton({required bool isMobile}) {
    return GestureDetector(
      onTap: () {
        _pickImage();
      },
      child: Container(
        width: isMobile ? 60 : 75,
        height: isMobile ? 60 : 75,
        decoration: BoxDecoration(
          color: beigeBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: lightGray.withOpacity(0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: brownColor,
              size: isMobile ? 22 : 26,
            ),
            const SizedBox(height: 4),
            Text(
              'Add Image',
              style: TextStyle(
                fontSize: isMobile ? 9 : 10,
                color: brownColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_productImages.length >= 5) {
      _showSnackBar('Maximum 5 images allowed', Colors.orange);
      return;
    }

    final ImagePicker picker = ImagePicker();

    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Image Source',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: brownColor),
                title: Text('Gallery', style: TextStyle(color: darkText)),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: brownColor),
                title: Text('Camera', style: TextStyle(color: darkText)),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        String imagePath;
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          final base64Image = base64Encode(bytes);

          String mimeType = 'image/jpeg';
          final fileName = image.name.toLowerCase();
          if (fileName.endsWith('.png')) {
            mimeType = 'image/png';
          } else if (fileName.endsWith('.gif')) {
            mimeType = 'image/gif';
          } else if (fileName.endsWith('.webp')) {
            mimeType = 'image/webp';
          }
          imagePath = 'data:$mimeType;base64,$base64Image';
        } else {
          imagePath = image.path;
        }
        setState(() {
          _productImages.add(imagePath);
          _imageError = null;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    bool isError =
        backgroundColor == Colors.red ||
        backgroundColor == Colors.redAccent ||
        backgroundColor == const Color(0xFFE53935);
    CustomSnackBar.show(context, message, isError: isError);
  }

  Widget _buildErrorTooltip(String errorMessage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              errorMessage,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextStep() {
    if (!_validateAllFields()) {
      setState(() {});
      return;
    }

    setState(() {
      _currentStep = 1;
    });
  }

  void _handleAddVariant() {
    setState(() {
      _variantSizeError = null;
      _variantColorError = null;
      _variantPriceError = null;
      _variantStockError = null;
    });

    final size = _selectedVariantSize;
    final color = _selectedVariantColor;
    final price = _variantPriceController.text.trim();
    final stock = _variantStockController.text.trim();

    bool isValid = true;

    if (size == null) {
      _variantSizeError = 'Size is required';
      isValid = false;
    }

    if (color == null) {
      _variantColorError = 'Color is required';
      isValid = false;
    }

    if (price.isEmpty) {
      _variantPriceError = 'Price is required';
      isValid = false;
    } else if (double.tryParse(price) == null) {
      _variantPriceError = 'Price must be a number';
      isValid = false;
    }

    if (stock.isEmpty) {
      _variantStockError = 'Stock is required';
      isValid = false;
    } else if (int.tryParse(stock) == null) {
      _variantStockError = 'Stock must be a whole number';
      isValid = false;
    }

    if (!isValid) {
      setState(() {});
      return;
    }

    setState(() {
      _variants.add({
        'size': size,
        'color': color,
        'price_per_variant': double.tryParse(price) ?? 0.0,
        'stock_quantity': int.tryParse(stock) ?? 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      _selectedVariantSize = null;
      _selectedVariantColor = null;
      _variantPriceController.clear();
      _variantStockController.clear();
      _variantSizeController.clear();
      _variantColorController.clear();
    });
  }

  void _handleRemoveVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }

  Widget _buildVariantsForm(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Product Variants',
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_back, color: brownColor),
              onPressed: () {
                setState(() {
                  _currentStep = 0;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Add size and color variants for your product',
          style: TextStyle(fontSize: isMobile ? 13 : 14, color: lightGray),
        ),
        SizedBox(height: isMobile ? 24 : 32),

        if (isMobile) ...[
          _buildDropdownField(
            label: 'Size',
            value: _selectedVariantSize,
            items: ['X Small', 'Small', 'Medium', 'Large', 'XL', 'XXL'],
            onChanged: (val) {
              setState(() {
                _selectedVariantSize = val;
                _variantSizeController.text = val ?? '';
                _variantSizeError = null;
              });
            },
            isMobile: true,
            error: _variantSizeError,
            fieldKey: _variantSizeFieldKey,
            controller: _variantSizeController,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Color',
            value: _selectedVariantColor,
            items: [
              'Red',
              'Blue',
              'Green',
              'Black',
              'White',
              'Yellow',
              'Pink',
              'Purple',
              'Grey',
              'Brown',
              'Orange',
              'Navy',
              'Maroon',
              'Teal',
            ],
            onChanged: (val) {
              setState(() {
                _selectedVariantColor = val;
                _variantColorController.text = val ?? '';
                _variantColorError = null;
              });
            },
            isMobile: true,
            error: _variantColorError,
            fieldKey: _variantColorFieldKey,
            controller: _variantColorController,
          ),
          const SizedBox(height: 16),
          _buildFormField(
            label: 'Price per Variant',
            controller: _variantPriceController,
            isMobile: true,
            keyboardType: TextInputType.number,
            error: _variantPriceError,
            onChanged: () {
              setState(() {
                _variantPriceError = null;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildFormField(
            label: 'Stock Quantity',
            controller: _variantStockController,
            isMobile: true,
            keyboardType: TextInputType.number,
            error: _variantStockError,
            onChanged: () {
              setState(() {
                _variantStockError = null;
              });
            },
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: 'Size',
                  value: _selectedVariantSize,
                  items: ['X Small', 'Small', 'Medium', 'Large', 'XL', 'XXL'],
                  onChanged: (val) {
                    setState(() {
                      _selectedVariantSize = val;
                      _variantSizeController.text = val ?? '';
                      _variantSizeError = null;
                    });
                  },
                  isMobile: false,
                  error: _variantSizeError,
                  fieldKey: _variantSizeFieldKey,
                  controller: _variantSizeController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                  label: 'Color',
                  value: _selectedVariantColor,
                  items: [
                    'Red',
                    'Blue',
                    'Green',
                    'Black',
                    'White',
                    'Yellow',
                    'Pink',
                    'Purple',
                    'Grey',
                    'Brown',
                    'Orange',
                    'Navy',
                    'Maroon',
                    'Teal',
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedVariantColor = val;
                      _variantColorController.text = val ?? '';
                      _variantColorError = null;
                    });
                  },
                  isMobile: false,
                  error: _variantColorError,
                  fieldKey: _variantColorFieldKey,
                  controller: _variantColorController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'Price',
                  controller: _variantPriceController,
                  isMobile: false,
                  keyboardType: TextInputType.number,
                  error: _variantPriceError,
                  onChanged: () {
                    setState(() {
                      _variantPriceError = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  label: 'Stock',
                  controller: _variantStockController,
                  isMobile: false,
                  keyboardType: TextInputType.number,
                  error: _variantStockError,
                  onChanged: () {
                    setState(() {
                      _variantStockError = null;
                    });
                  },
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _handleAddVariant,
            icon: Icon(Icons.add, color: brownColor),
            label: Text('Add Variant', style: TextStyle(color: brownColor)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: brownColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        if (_variants.isNotEmpty) ...[
          Text(
            'Added Variants (${_variants.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _variants.length,
              separatorBuilder: (c, i) =>
                  Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
              itemBuilder: (context, index) {
                final variant = _variants[index];
                return ListTile(
                  title: Text('${variant['size']} - ${variant['color']}'),
                  subtitle: Text(
                    'Price: ${variant['price_per_variant']} | Stock: ${variant['stock_quantity']}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _handleRemoveVariant(index),
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 40),
        Divider(color: Colors.grey.withOpacity(0.2)),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_variants.isEmpty) {
                _showSnackBar('Please add at least one variant', Colors.orange);
                return;
              }
              _handleSaveProduct();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brownColor,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              _isEditing ? 'Update Product' : 'Save Product',
              style: TextStyle(
                color: whiteColor,
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductSidebar(bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : 350,
      child: Column(
        children: [
          if (_currentStep == 0) _buildImageUploadSection(isMobile),
          SizedBox(height: isMobile ? 24 : 24),
          SizedBox(height: isMobile ? 20 : 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep == 0) {
                  _handleNextStep();
                  return;
                }

                setState(() {
                  _productNameError = null;

                  _categoryError = null;
                  _priceError = null;
                  _descriptionError = null;
                });

                if (!_validateAllFields()) {
                  setState(() {});
                  return;
                }

                if (_variants.isEmpty) {
                  _showSnackBar(
                    'Please add at least one variant',
                    Colors.orange,
                  );
                  return;
                }

                _handleSaveProduct();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brownColor,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                (_currentStep == 0)
                    ? 'Next'
                    : (_isEditing ? 'Update Product' : 'Save'),
                style: TextStyle(
                  color: whiteColor,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _editingProductId = null;
                    _productNameController.clear();

                    _minPriceController.clear();
                    _descriptionController.clear();
                    _selectedCategory = null;
                    _productImages.clear();
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: brownColor, width: 1.5),
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel Edit',
                  style: TextStyle(
                    color: brownColor,
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagsSection({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightGray.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tags',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
              Icon(Icons.keyboard_arrow_down, color: lightGray),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Categorize your store products and organize search results for customers',
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              color: lightGray,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    return _buildEmptyState(
      icon: Icons.chat_bubble_outline,
      message: 'No messages yet',
    );
  }

  Widget _buildOrderCard({required Map<String, dynamic> order}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    final orderId = order['id'] ?? '0';
    final customerName = order['customer_name'] ?? 'Guest';
    final total = order['total'] ?? '0.00';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: whiteColor,
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
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: brownColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: brownColor,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #$orderId',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customerName,
                        style: TextStyle(
                          fontSize: 14,
                          color: darkText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs $total',
                        style: TextStyle(fontSize: 13, color: lightGray),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: lightGray.withOpacity(0.2)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    _showOrderDetails(order);
                  },
                  icon: Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: brownColor,
                  ),
                  label: Text(
                    'Review',
                    style: TextStyle(color: brownColor, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    minimumSize: const Size(0, 56),
                    side: BorderSide(color: brownColor, width: 1),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) async {
    final orderId = int.parse(order['id'].toString());
    final orderTotal = order['total'] ?? '0.00';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ApiService.getOrderDetails(orderId);
    Navigator.pop(context);

    if (!result['success']) {
      _showSnackBar(
        result['message'] ?? 'Failed to load order details',
        Colors.red,
      );
      return;
    }

    final orderData = result['data'];
    final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);

    if (!mounted) return;

    _detailsDialogAnimationController.forward();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: true,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 768;
        final double walletUsed = double.tryParse(orderData['wallet_amount']?.toString() ?? '0') ?? 0.0;
        final double cashPaid = double.tryParse(orderData['cash_amount']?.toString() ?? '0') ?? 0.0;

        return AnimatedBuilder(
          animation: _detailsDialogAnimationController,
          builder: (context, child) {
            return Opacity(
              opacity: _detailsDialogFadeAnimation.value,
              child: Transform.scale(
                scale: _detailsDialogScaleAnimation.value,
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: isMobile
                        ? 20
                        : MediaQuery.of(context).size.width * 0.1,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 800,
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: brownColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: whiteColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    color: whiteColor,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #$orderId',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: whiteColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Order Review',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: whiteColor.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: whiteColor),
                                onPressed: () {
                                  _detailsDialogAnimationController.reverse();
                                  Navigator.of(context).pop();
                                },
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
                                _buildSectionTitle(
                                  'Basic Information',
                                  Icons.person_outline,
                                ),
                                const SizedBox(height: 12),
                                Flex(
                                  direction: isMobile
                                      ? Axis.vertical
                                      : Axis.horizontal,
                                  crossAxisAlignment: isMobile
                                      ? CrossAxisAlignment.stretch
                                      : CrossAxisAlignment.center,
                                  children: [
                                    if (isMobile)
                                      _buildDetailRow(
                                        Icons.person_outline,
                                        'Customer',
                                        orderData['customer_name'] ?? 'N/A',
                                      )
                                    else
                                      Expanded(
                                        child: _buildDetailRow(
                                          Icons.person_outline,
                                          'Customer',
                                          orderData['customer_name'] ?? 'N/A',
                                        ),
                                      ),

                                    if (isMobile)
                                      const SizedBox(height: 12)
                                    else
                                      const SizedBox(width: 12),

                                    if (isMobile)
                                      _buildDetailRow(
                                        Icons.email_outlined,
                                        'Email',
                                        orderData['customer_email'] ?? 'N/A',
                                      )
                                    else
                                      Expanded(
                                        child: _buildDetailRow(
                                          Icons.email_outlined,
                                          'Email',
                                          orderData['customer_email'] ?? 'N/A',
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Flex(
                                  direction: isMobile
                                      ? Axis.vertical
                                      : Axis.horizontal,
                                  crossAxisAlignment: isMobile
                                      ? CrossAxisAlignment.stretch
                                      : CrossAxisAlignment.center,
                                  children: [
                                    if (isMobile)
                                      _buildDetailRow(
                                        Icons.phone_outlined,
                                        'Contact Number',
                                        orderData['contact_number'] ??
                                            orderData['customer_phone'] ??
                                            'N/A',
                                      )
                                    else
                                      Expanded(
                                        child: _buildDetailRow(
                                          Icons.phone_outlined,
                                          'Contact Number',
                                          orderData['contact_number'] ??
                                              orderData['customer_phone'] ??
                                              'N/A',
                                        ),
                                      ),

                                    if (isMobile)
                                      const SizedBox(height: 12)
                                    else
                                      const SizedBox(width: 12),

                                    if (isMobile)
                                      _buildDetailRow(
                                        Icons.payment_outlined,
                                        'Payment Method',
                                        orderData['payment_method'] ?? 'N/A',
                                      )
                                    else
                                      Expanded(
                                        child: _buildDetailRow(
                                          Icons.payment_outlined,
                                          'Payment Method',
                                          orderData['payment_method'] ?? 'N/A',
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (walletUsed != 0) ...[
                                  _buildDetailRow(
                                    Icons.account_balance_wallet_outlined,
                                    'Wallet Used',
                                    'Rs. ${walletUsed.toStringAsFixed(2)}',
                                  ),
                                  if (cashPaid != 0) const SizedBox(height: 12),
                                ],
                                if (cashPaid != 0)
                                  _buildDetailRow(
                                    Icons.money_outlined,
                                    'Cash Paid',
                                    'Rs. ${cashPaid.toStringAsFixed(2)}',
                                  ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  Icons.location_on_outlined,
                                  'Address',
                                  orderData['shipping_address'] ?? 'N/A',
                                  isMultiline: true,
                                ),

                                const SizedBox(height: 24),

                                _buildSectionTitle(
                                  'Order Items',
                                  Icons.inventory_2_outlined,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: beigeBackground,
                                    border: Border.all(
                                      color: lightGray.withOpacity(0.1),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: items.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final item = entry.value;
                                      final isLast = index == items.length - 1;

                                      Widget imageWidget;
                                      if (item['image'] != null) {
                                        imageWidget = ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: _buildImageWidget(
                                            item['image'],
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      } else {
                                        imageWidget = Icon(
                                          Icons.image,
                                          size: 24,
                                          color: lightGray,
                                        );
                                      }

                                      return Container(
                                        decoration: BoxDecoration(
                                          border: isLast
                                              ? null
                                              : Border(
                                                  bottom: BorderSide(
                                                    color: lightGray
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 48,
                                                    height: 48,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: imageWidget,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Product',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: lightGray,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          item['product_name'] ??
                                                              'Product',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: darkText,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Variant',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: lightGray,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${item['size'] ?? '-'}/${item['color'] ?? '-'}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: darkText,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            Expanded(
                                              flex: 1,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Qty',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: lightGray,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${item['quantity']}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: darkText,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    'Price',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: lightGray,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Rs ${item['price']}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: brownColor,
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
                                ),

                                const SizedBox(height: 24),

                                _buildSectionTitle(
                                  'Price Consideration',
                                  Icons.attach_money,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  Icons.account_balance_wallet_outlined,
                                  'Your Order Price',
                                  'Rs $orderTotal',
                                ),

                                const SizedBox(height: 24),

                                _buildSectionTitle(
                                  'Order Status',
                                  Icons.info_outline,
                                ),
                                const SizedBox(height: 12),
                                _buildStatusChip(
                                  'Current Status',
                                  orderData['order_status'] ?? 'Pending',
                                ),

                                const SizedBox(height: 24),

                                if ([
                                  'pending',
                                  'accepted',
                                  'shipped',
                                  'delivered',
                                ].contains(
                                  orderData['order_status']
                                      ?.toString()
                                      .toLowerCase(),
                                )) ...[
                                  _buildSectionTitle(
                                    'Actions',
                                    Icons.settings_outlined,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      if (orderData['order_status']
                                              ?.toString()
                                              .toLowerCase() ==
                                          'pending') ...[
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            _updateOrderStatus(
                                              orderId,
                                              'accepted',
                                            );
                                            Navigator.of(context).pop();
                                          },
                                          icon: Icon(
                                            Icons.check_circle_outline,
                                            color: whiteColor,
                                            size: 20,
                                          ),
                                          label: Text(
                                            'Accept',
                                            style: TextStyle(
                                              color: whiteColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 18,
                                            ),
                                            minimumSize: const Size(0, 56),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            _updateOrderStatus(
                                              orderId,
                                              'rejected',
                                            );
                                            Navigator.of(context).pop();
                                          },
                                          icon: Icon(
                                            Icons.cancel_outlined,
                                            color: whiteColor,
                                            size: 20,
                                          ),
                                          label: Text(
                                            'Reject',
                                            style: TextStyle(
                                              color: whiteColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 18,
                                            ),
                                            minimumSize: const Size(0, 56),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                        ),
                                      ] else if (orderData['order_status']
                                              ?.toString()
                                              .toLowerCase() ==
                                          'accepted') ...[
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            _updateOrderStatus(
                                              orderId,
                                              'shipped',
                                            );
                                            Navigator.of(context).pop();
                                          },
                                          icon: Icon(
                                            Icons.local_shipping_outlined,
                                            color: whiteColor,
                                            size: 20,
                                          ),
                                          label: Text(
                                            'Mark as Shipped',
                                            style: TextStyle(
                                              color: whiteColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 18,
                                            ),
                                            minimumSize: const Size(0, 56),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                        ),
                                      ] else if (orderData['order_status']
                                              ?.toString()
                                              .toLowerCase() ==
                                          'shipped') ...[
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            _updateOrderStatus(
                                              orderId,
                                              'delivered',
                                            );
                                            Navigator.of(context).pop();
                                          },
                                          icon: Icon(
                                            Icons.home_outlined,
                                            color: whiteColor,
                                            size: 20,
                                          ),
                                          label: Text(
                                            'Mark as Delivered',
                                            style: TextStyle(
                                              color: whiteColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 18,
                                            ),
                                            minimumSize: const Size(0, 56),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                        ),
                                      ] else if (orderData['order_status']
                                              ?.toString()
                                              .toLowerCase() ==
                                          'delivered') ...[
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            _updateOrderStatus(
                                              orderId,
                                              'completed',
                                            );
                                            Navigator.of(context).pop();
                                          },
                                          icon: Icon(
                                            Icons.done_all_outlined,
                                            color: whiteColor,
                                            size: 20,
                                          ),
                                          label: Text(
                                            'Mark as Completed',
                                            style: TextStyle(
                                              color: whiteColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF2E7D32,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 18,
                                            ),
                                            minimumSize: const Size(0, 56),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 24),
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
                                _detailsDialogAnimationController
                                    .reverse()
                                    .then((_) {
                                      Navigator.of(context).pop();
                                    });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brownColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Close',
                                style: TextStyle(
                                  color: whiteColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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

  Future<void> _updateOrderStatus(int orderId, String status) async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.updateOrderStatus(orderId, status);
      if (result['success']) {
        await _loadOrders();

        setState(() {
          if (['accepted', 'shipped', 'delivered'].contains(status)) {
            _orderSubTab = 'accepted';
          } else if (status == 'completed') {
            _orderSubTab = 'completed';
          } else if (status == 'rejected') {
            _orderSubTab = 'rejected';
          }
        });
      } else {
        _showSnackBar(
          result['message'] ?? 'Failed to update order',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('An error occurred', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildProductCard({required Map<String, dynamic> product}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    final productId = product['id'] ?? product['product_id'] ?? '0';
    final productName =
        product['product_name'] ?? product['name'] ?? 'Product Name';
    final category = product['category'] ?? 'Uncategorized';
    final price = product['price'] ?? product['minimum_selling_price'] ?? '0';

    // --- Look up active promotion for this product ---
    Map<String, dynamic>? activePromotion;
    int discountPercent = 0;
    for (final promo in _promotions) {
      final promoStatus = promo['status'];
      final isActive =
          promoStatus == 1 || promoStatus == '1' || promoStatus == null;
      if (!isActive) continue;
      final idsStr = promo['product_ids']?.toString() ?? '';
      final ids = idsStr
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final pidStr = productId.toString();
      if (ids.contains(pidStr)) {
        activePromotion = promo;
        discountPercent =
            int.tryParse(promo['discount']?.toString() ?? '0') ?? 0;
        break;
      }
    }
    final double originalPrice = double.tryParse(price.toString()) ?? 0;
    final double discountedPrice =
        activePromotion != null && discountPercent > 0
        ? originalPrice * (1 - discountPercent / 100)
        : originalPrice;
    // ---------------------------------------------------

    String? productImage;
    if (product['product_images'] != null) {
      try {
        if (product['product_images'] is String) {
          final imagesList =
              jsonDecode(product['product_images']) as List<dynamic>;
          if (imagesList.isNotEmpty) {
            productImage = imagesList[0].toString();
          }
        } else if (product['product_images'] is List) {
          final imagesList = product['product_images'] as List;
          if (imagesList.isNotEmpty) {
            productImage = imagesList[0].toString();
          }
        }
      } catch (e) {}
    }

    productImage ??=
        product['image'] ?? product['image_url'] ?? product['images']?[0];

    final productNumber =
        product['product_number'] ?? productId.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: whiteColor,
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
                  decoration: BoxDecoration(
                    color: brownColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: productImage != null
                        ? _buildImageWidget(
                            productImage,
                            fit: BoxFit.cover,
                            errorWidget: Icon(
                              Icons.shopping_bag,
                              color: brownColor,
                              size: 28,
                            ),
                          )
                        : Icon(Icons.shopping_bag, color: brownColor, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              productName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              category.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Price row — shows promotion pricing if active
                      Row(
                        children: [
                          if (activePromotion != null &&
                              discountPercent > 0) ...[
                            // Strikethrough original price
                            Text(
                              'Rs ${originalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: lightGray,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: lightGray,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Discount badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: brownColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$discountPercent% OFF',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: brownColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // New discounted price
                            Text(
                              'Rs ${discountedPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: brownColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Rs $price',
                              style: TextStyle(
                                fontSize: 14,
                                color: darkText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: lightGray.withOpacity(0.2)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    _showProductDetails(productId.toString());
                  },
                  icon: Icon(Icons.info_outline, size: 16, color: brownColor),
                  label: Text(
                    'Review',
                    style: TextStyle(color: brownColor, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    minimumSize: const Size(0, 56),
                    side: BorderSide(color: brownColor, width: 1),
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

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 32 : 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isMobile ? 64 : 80,
              color: lightGray.withOpacity(0.5),
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                color: lightGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(Icons.add, color: whiteColor, size: 20),
                label: Text(
                  actionLabel,
                  style: TextStyle(
                    color: whiteColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brownColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isMultiline = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: beigeBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightGray.withOpacity(0.1), width: 1),
      ),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: brownColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: brownColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: lightGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: darkText,
                    fontWeight: FontWeight.w600,
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

  Widget _buildStatusChip(String label, String status) {
    String displayStatus = status;
    bool isApproved =
        status.toLowerCase() == 'approved' ||
        status.toLowerCase() == 'verified' ||
        status.toLowerCase() == 'accepted' ||
        status.toLowerCase() == 'delivered' ||
        status.toLowerCase() == 'completed' ||
        status == '1';

    bool isRejected =
        status.toLowerCase() == 'rejected' ||
        status.toLowerCase() == 'cancelled' ||
        status == '-1';

    bool isBlocked = status.toLowerCase() == 'blocked' || status == '-2';

    if (isApproved) {
      if (status == '1' || status.toLowerCase() == 'verified')
        displayStatus = 'Approved';
      else if (status.toLowerCase() == 'accepted')
        displayStatus = 'Accepted';
      else if (status.toLowerCase() == 'delivered')
        displayStatus = 'Delivered';
      else if (status.toLowerCase() == 'completed')
        displayStatus = 'Completed';
    } else if (isRejected) {
      displayStatus = 'Rejected';
    } else if (isBlocked) {
      displayStatus = 'Blocked';
    } else {
      displayStatus = 'Pending';
    }

    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    if (isApproved) {
      statusColor = Colors.green;
      statusBgColor = Colors.green.withOpacity(0.1);
      statusIcon = Icons.check_circle_outline;
    } else if (isBlocked || isRejected) {
      statusColor = Colors.red;
      statusBgColor = Colors.red.withOpacity(0.1);
      statusIcon = isBlocked ? Icons.block : Icons.cancel_outlined;
    } else {
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.withOpacity(0.1);
      statusIcon = Icons.pending_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: beigeBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightGray.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: lightGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    displayStatus,
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: brownColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
      ],
    );
  }

  void _showPromotionDetails(Map<String, dynamic> promotion) {
    _detailsDialogAnimationController.forward(from: 0);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: true,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 768;

        final title = promotion['title'] ?? 'Untitled promotion';
        final discount = promotion['discount'] ?? 0;
        final discountInt = int.tryParse(discount.toString()) ?? 0;
        final startDate = promotion['start_date'] != null
            ? promotion['start_date'].toString().split('T')[0]
            : '';
        final endDate = promotion['end_date'] != null
            ? promotion['end_date'].toString().split('T')[0]
            : '';
        final status = promotion['status'];
        final isCurrentlyActive =
            status == 1 || status == '1' || status == null;

        final productIdsString = promotion['product_ids']?.toString() ?? '';
        final productIds = productIdsString
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .map((s) => int.tryParse(s))
            .whereType<int>()
            .toSet();
        // Only show products that are currently approved (is_verified == 1)
        final appliedProducts = _products.where((p) {
          final iv = p['is_verified'];
          final isApproved = iv == 1 || iv == '1' || iv == true;
          if (!isApproved) return false;
          final pid = p['product_id'];
          final pidInt = pid is int ? pid : int.tryParse(pid.toString());
          return pidInt != null && productIds.contains(pidInt);
        }).toList();

        return AnimatedBuilder(
          animation: _detailsDialogAnimationController,
          builder: (context, child) {
            return Opacity(
              opacity: _detailsDialogFadeAnimation.value,
              child: Transform.scale(
                scale: _detailsDialogScaleAnimation.value,
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: isMobile
                        ? 20
                        : MediaQuery.of(context).size.width * 0.1,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 600,
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: brownColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: whiteColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.campaign,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Promotion Details',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  _detailsDialogAnimationController
                                      .reverse()
                                      .then((_) {
                                        Navigator.pop(context);
                                      });
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  'Basic Information',
                                  Icons.description_outlined,
                                ),
                                const SizedBox(height: 12),
                                Flex(
                                  direction: isMobile
                                      ? Axis.vertical
                                      : Axis.horizontal,
                                  crossAxisAlignment: isMobile
                                      ? CrossAxisAlignment.stretch
                                      : CrossAxisAlignment.center,
                                  children: [
                                    if (isMobile)
                                      _buildDetailRow(
                                        Icons.local_offer_outlined,
                                        'Discount',
                                        '$discount% OFF',
                                      )
                                    else
                                      Expanded(
                                        child: _buildDetailRow(
                                          Icons.local_offer_outlined,
                                          'Discount',
                                          '$discount% OFF',
                                        ),
                                      ),
                                    if (isMobile)
                                      const SizedBox(height: 12)
                                    else
                                      const SizedBox(width: 12),
                                    if (isMobile)
                                      _buildDetailRow(
                                        Icons.date_range,
                                        'Start Date',
                                        startDate,
                                      )
                                    else
                                      Expanded(
                                        child: _buildDetailRow(
                                          Icons.date_range,
                                          'Start Date',
                                          startDate,
                                        ),
                                      ),
                                    if (isMobile)
                                      const SizedBox(height: 12)
                                    else
                                      const SizedBox(width: 12),
                                    if (isMobile)
                                      _buildDetailRow(
                                        Icons.event,
                                        'End Date',
                                        endDate,
                                      )
                                    else
                                      Expanded(
                                        child: _buildDetailRow(
                                          Icons.event,
                                          'End Date',
                                          endDate,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 24),
                                _buildSectionTitle(
                                  'Applied Products',
                                  Icons.inventory_2_outlined,
                                ),
                                const SizedBox(height: 12),
                                ...appliedProducts.map((product) {
                                  final images = _parseProductImages(
                                    product['product_images'],
                                  );
                                  final imageUrl = images.isNotEmpty
                                      ? images.first
                                      : '';
                                  final name =
                                      product['product_name'] ?? 'Unknown';
                                  final originalPrice =
                                      double.tryParse(
                                        product['price']?.toString() ?? '0',
                                      ) ??
                                      0.0;
                                  final discountedPrice =
                                      originalPrice * (1 - (discountInt / 100));

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            color: Colors.grey[200],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: imageUrl.isNotEmpty
                                                ? _buildImageWidget(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    errorWidget: const Icon(
                                                      Icons
                                                          .inventory_2_outlined,
                                                      color: Colors.grey,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.inventory_2_outlined,
                                                    color: Colors.grey,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Text(
                                                    'Rs ${originalPrice.toStringAsFixed(0)}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Rs ${discountedPrice.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: brownColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                if (appliedProducts.isEmpty)
                                  const Text(
                                    'No products applied',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      height: 1.5,
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                _buildSectionTitle(
                                  'Actions',
                                  Icons.settings_outlined,
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _detailsDialogAnimationController
                                            .reverse()
                                            .then((_) {
                                              Navigator.of(context).pop();
                                              _togglePromotionStatus(promotion);
                                            });
                                      },
                                      icon: Icon(
                                        isCurrentlyActive
                                            ? Icons.unpublished_outlined
                                            : Icons.check_circle_outline,
                                        color: whiteColor,
                                        size: 20,
                                      ),
                                      label: Text(
                                        isCurrentlyActive
                                            ? 'Deactivate'
                                            : 'Activate',
                                        style: TextStyle(
                                          color: whiteColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isCurrentlyActive
                                            ? Colors.orange
                                            : Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 18,
                                        ),
                                        minimumSize: const Size(0, 56),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _detailsDialogAnimationController
                                            .reverse()
                                            .then((_) {
                                              Navigator.of(context).pop();
                                              _startEditingPromotion(promotion);
                                            });
                                      },
                                      icon: Icon(
                                        Icons.edit,
                                        color: whiteColor,
                                        size: 20,
                                      ),
                                      label: Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: whiteColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 18,
                                        ),
                                        minimumSize: const Size(0, 56),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _detailsDialogAnimationController
                                            .reverse()
                                            .then((_) {
                                              Navigator.of(context).pop();
                                              _deletePromotion(promotion);
                                            });
                                      },
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: whiteColor,
                                        size: 20,
                                      ),
                                      label: Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: whiteColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 18,
                                        ),
                                        minimumSize: const Size(0, 56),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _detailsDialogAnimationController
                                    .reverse()
                                    .then((_) {
                                      Navigator.pop(context);
                                    });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brownColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
    );
  }

  void _showProductDetails(String productId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    ApiService.getProductById(productId).then((result) {
      Navigator.pop(context);

      if (result['success'] && result['data'] != null) {
        final product = result['data'];
        _detailsDialogAnimationController.forward();

        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.5),
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
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      insetPadding: EdgeInsets.symmetric(
                        horizontal: isMobile
                            ? 20
                            : MediaQuery.of(context).size.width * 0.1,
                      ),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: isMobile ? double.infinity : 800,
                          maxHeight: MediaQuery.of(context).size.height * 0.85,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: brownColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: whiteColor.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.shopping_bag,
                                      color: whiteColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['product_name']?.toString() ??
                                              'Unknown Product',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: whiteColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                    if (product['product_images'] != null) ...[
                                      _buildSectionTitle(
                                        'Product Images',
                                        Icons.image_outlined,
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 120,
                                        child: ListView(
                                          scrollDirection: Axis.horizontal,
                                          children: _buildProductImagesList(
                                            product['product_images'],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                    ],

                                    _buildSectionTitle(
                                      'Basic Information',
                                      Icons.description_outlined,
                                    ),
                                    const SizedBox(height: 12),
                                    Flex(
                                      direction: isMobile
                                          ? Axis.vertical
                                          : Axis.horizontal,
                                      crossAxisAlignment: isMobile
                                          ? CrossAxisAlignment.stretch
                                          : CrossAxisAlignment.center,
                                      children: [
                                        if (isMobile)
                                          _buildDetailRow(
                                            Icons.category_outlined,
                                            'Category',
                                            product['category']?.toString() ??
                                                'N/A',
                                          )
                                        else
                                          Expanded(
                                            child: _buildDetailRow(
                                              Icons.category_outlined,
                                              'Category',
                                              product['category']?.toString() ??
                                                  'N/A',
                                            ),
                                          ),

                                        if (isMobile)
                                          const SizedBox(height: 12)
                                        else
                                          const SizedBox(width: 12),

                                        if (isMobile)
                                          _buildDetailRow(
                                            Icons.person_outline,
                                            'Gender',
                                            product['gender'] != null &&
                                                    product['gender']
                                                        .toString()
                                                        .isNotEmpty
                                                ? "${product['gender'].toString()[0].toUpperCase()}${product['gender'].toString().substring(1).toLowerCase()}"
                                                : 'N/A',
                                          )
                                        else
                                          Expanded(
                                            child: _buildDetailRow(
                                              Icons.person_outline,
                                              'Gender',
                                              product['gender']
                                                      ?.toString()
                                                      .toUpperCase() ??
                                                  'N/A',
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Flex(
                                      direction: isMobile
                                          ? Axis.vertical
                                          : Axis.horizontal,
                                      crossAxisAlignment: isMobile
                                          ? CrossAxisAlignment.stretch
                                          : CrossAxisAlignment.center,
                                      children: [
                                        if (isMobile)
                                          _buildDetailRow(
                                            Icons.attach_money,
                                            'Price',
                                            'Rs ${product['price'] ?? product['minimum_selling_price'] ?? '0'}',
                                          )
                                        else
                                          Expanded(
                                            child: _buildDetailRow(
                                              Icons.attach_money,
                                              'Price',
                                              'Rs ${product['price'] ?? product['minimum_selling_price'] ?? '0'}',
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildDetailRow(
                                      Icons.notes,
                                      'Description',
                                      product['description']?.toString() ??
                                          'No description provided',
                                      isMultiline: true,
                                    ),
                                    const SizedBox(height: 24),

                                    if (true) ...[
                                      _buildSectionTitle(
                                        'Variants',
                                        Icons.layers_outlined,
                                      ),
                                      const SizedBox(height: 12),
                                      FutureBuilder<List<Map<String, dynamic>>>(
                                        future: ApiService.getProductVariants(
                                          int.tryParse(
                                                product['id']?.toString() ??
                                                    product['product_id']
                                                        ?.toString() ??
                                                    '0',
                                              ) ??
                                              0,
                                        ),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Padding(
                                              padding: const EdgeInsets.all(
                                                20.0,
                                              ),
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: brownColor,
                                                    ),
                                              ),
                                            );
                                          }

                                          if (snapshot.hasError ||
                                              !snapshot.hasData ||
                                              snapshot.data!.isEmpty) {
                                            return Text(
                                              'No variants available',
                                              style: TextStyle(
                                                color: lightGray,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            );
                                          }

                                          final variants = snapshot.data!;

                                          return Container(
                                            decoration: BoxDecoration(
                                              color: beigeBackground,
                                              border: Border.all(
                                                color: lightGray.withOpacity(
                                                  0.1,
                                                ),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              children: variants.asMap().entries.map((
                                                entry,
                                              ) {
                                                final index = entry.key;
                                                final variant = entry.value;
                                                final isLast =
                                                    index ==
                                                    variants.length - 1;

                                                return Container(
                                                  decoration: BoxDecoration(
                                                    border: isLast
                                                        ? null
                                                        : Border(
                                                            bottom: BorderSide(
                                                              color: lightGray
                                                                  .withOpacity(
                                                                    0.1,
                                                                  ),
                                                            ),
                                                          ),
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 2,
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Size',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color:
                                                                    lightGray,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            Text(
                                                              '${variant['size']}',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: darkText,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Color',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color:
                                                                    lightGray,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            Text(
                                                              '${variant['color']}',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: darkText,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          children: [
                                                            Text(
                                                              'Price',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color:
                                                                    lightGray,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            Text(
                                                              'Rs ${variant['price_per_variant']}',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    brownColor,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          children: [
                                                            Text(
                                                              'Stock',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color:
                                                                    lightGray,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            Text(
                                                              '${variant['stock_quantity']}',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: darkText,
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
                                    if (product['is_verified'] == 1 ||
                                        product['is_verified'] == '1' ||
                                        product['is_verified'] == -1 ||
                                        product['is_verified'] == '-1') ...[
                                      _buildSectionTitle(
                                        'Actions',
                                        Icons.settings_outlined,
                                      ),
                                      const SizedBox(height: 16),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                _detailsDialogAnimationController
                                                    .reverse()
                                                    .then((_) {
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                      _startEditingProduct(
                                                        product,
                                                      );
                                                    });
                                              },
                                              icon: Icon(
                                                Icons.edit,
                                                color: whiteColor,
                                                size: 20,
                                              ),
                                              label: Text(
                                                'Edit',
                                                style: TextStyle(
                                                  color: whiteColor,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 18,
                                                    ),
                                                minimumSize: const Size(0, 56),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 0,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                _showDeleteConfirmation(
                                                  product,
                                                );
                                              },
                                              icon: Icon(
                                                Icons.delete_outline,
                                                color: whiteColor,
                                                size: 20,
                                              ),
                                              label: Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: whiteColor,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 18,
                                                    ),
                                                minimumSize: const Size(0, 56),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
                                    _detailsDialogAnimationController
                                        .reverse()
                                        .then((_) {
                                          Navigator.of(context).pop();
                                        });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brownColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Close',
                                    style: TextStyle(
                                      color: whiteColor,
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
      } else {
        _showSnackBar(
          result['message'] ?? 'Failed to load product details',
          Colors.red,
        );
      }
    });
  }

  void _startEditingProduct(Map<String, dynamic> product) {
    setState(() {
      _isEditing = true;
      _editingProductId = product['product_id'] is int
          ? product['product_id']
          : int.tryParse(product['product_id'].toString());

      _productNameController.text = product['product_name']?.toString() ?? '';
      _minPriceController.text = product['price']?.toString() ?? '';
      _descriptionController.text = product['description']?.toString() ?? '';

      _selectedCategory = product['category']?.toString();
      _selectedGender = product['gender']?.toString();

      _categoryController.text = _selectedCategory ?? '';
      _genderController.text = _selectedGender ?? '';

      final imagesData = product['product_images'] ?? product['images'];
      if (imagesData is List) {
        _productImages = imagesData.map((e) => e.toString()).toList();
      } else if (imagesData is String) {
        try {
          final List<dynamic> parsed = jsonDecode(imagesData);
          _productImages = parsed.map((e) => e.toString()).toList();
        } catch (e) {
          _productImages = [imagesData];
        }
      } else {
        _productImages = [];
      }

      _variants = [];
      if (_editingProductId != null) {
        ApiService.getProductVariants(_editingProductId!).then((variants) {
          if (mounted) {
            setState(() {
              _variants = variants;
            });
          }
        });
      }

      _selectedTab = 1;
      _productSubTab = 'add';
    });
  }

  void _showDeleteConfirmation(Map<String, dynamic> product) {
    _deleteDialogAnimationController.forward();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: true,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 768;

        return AnimatedBuilder(
          animation: _deleteDialogAnimationController,
          builder: (context, child) {
            return Opacity(
              opacity: _deleteDialogFadeAnimation.value,
              child: Transform.scale(
                scale: _deleteDialogScaleAnimation.value,
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: isMobile
                        ? 24
                        : MediaQuery.of(context).size.width * 0.1,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 500,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Delete Product',
                            style: TextStyle(
                              fontSize: isMobile ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: isMobile ? 8 : 12),

                          Text(
                            'Are you sure you want to delete "${product['product_name'] ?? 'this product'}"? This action cannot be undone.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              color: lightGray,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: isMobile ? 20 : 28),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    _deleteDialogAnimationController.reverse();
                                    Navigator.of(context).pop();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: lightGray.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 20 : 24,
                                      vertical: isMobile ? 14 : 16,
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: darkText,
                                      fontSize: isMobile ? 15 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: isMobile ? 12 : 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _deleteDialogAnimationController.reverse();
                                    Navigator.of(context).pop();
                                    _handleDeleteProduct(product);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brownColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 20 : 24,
                                      vertical: isMobile ? 14 : 16,
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: whiteColor,
                                      fontSize: isMobile ? 15 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
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
    );
  }

  /// Removes [productId] from every active promotion that contains it.
  Future<void> _removeProductFromPromotions(dynamic productId) async {
    final pidInt = productId is int
        ? productId
        : int.tryParse(productId.toString());
    if (pidInt == null) return;

    // Iterate a copy so state changes mid-loop don't cause issues
    for (final promo in List<Map<String, dynamic>>.from(_promotions)) {
      final promoId = promo['promotion_id'] is int
          ? promo['promotion_id'] as int
          : int.tryParse(promo['promotion_id']?.toString() ?? '');
      if (promoId == null) continue;

      // Parse product_ids (comma-separated string from GROUP_CONCAT)
      final idsStr = promo['product_ids']?.toString() ?? '';
      if (idsStr.isEmpty) continue;

      final ids = idsStr
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toList();

      // Only call the API if this product is actually in this promotion
      if (!ids.contains(pidInt)) continue;

      try {
        await ApiService.removeProductFromPromotion(
          promotionId: promoId,
          productId: pidInt,
        );
      } catch (_) {}
    }

    // Refresh promotions list to reflect DB changes
    await _loadPromotions();
  }

  Future<void> _handleDeleteProduct(Map<String, dynamic> product) async {
    final productId = product['id'] ?? product['product_id'];
    if (productId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Strip this product from any active promotion first
      await _removeProductFromPromotions(productId);

      final result = await ApiService.deleteProduct(
        int.parse(productId.toString()),
      );

      if (result['success']) {
        _detailsDialogAnimationController.reverse().then((_) {
          Navigator.of(context).pop();
          _loadProducts();
        });
      } else {
        _showSnackBar(
          result['message'] ?? 'Failed to delete product',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Widget> _buildProductImagesList(dynamic imagesData) {
    List<String> images = [];
    if (imagesData is List) {
      images = imagesData.map((e) => e.toString()).toList();
    } else if (imagesData is String) {
      try {
        final List<dynamic> parsed = jsonDecode(imagesData);
        images = parsed.map((e) => e.toString()).toList();
      } catch (e) {
        images = [imagesData];
      }
    }

    if (images.isEmpty) return [const Text('No images available')];

    return images.map((img) {
      return Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: lightGray.withOpacity(0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildImageWidget(
            img,
            fit: BoxFit.cover,
            errorWidget: const Center(child: Icon(Icons.broken_image)),
          ),
        ),
      );
    }).toList();
  }
}
