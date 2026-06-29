import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api_service.dart';
import 'product_details_screen.dart';
import 'store_products_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import '../widgets/custom_snackbar.dart';
import '../styles/customer_home_styles.dart';
import 'chats_list_screen.dart';
import 'my_orders_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final int? userId;

  const CustomerHomeScreen({super.key, this.userId});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  
  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    bool isError =
        backgroundColor == CustomerHomeStyles.errorColor ||
        backgroundColor == Colors.redAccent ||
        backgroundColor == const Color(0xFFE53935);
    CustomSnackBar.show(context, message, isError: isError);
  }

  static const categories = [
    {'icon': 'assets/images/tops_icon.png', 'label': 'Tops'},
    {'icon': 'assets/images/bottoms_icon.png', 'label': 'Bottoms'},
    {'icon': 'assets/images/dresses_icon.png', 'label': 'Dresses'},
    {'icon': 'assets/images/sets_icon.png', 'label': 'Sets'},
    {'icon': 'assets/images/activewear_icon.png', 'label': 'Activewear'},
    {'icon': 'assets/images/sleepwear_icon.png', 'label': 'Sleepwear'},
  ];

  int _selectedIndex = 0;
  List<Map<String, dynamic>> _stores = [];
  bool _isStoresLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _recommendationKey = 0;

  String _selectedGender = 'All';
  String _selectedCategory = 'All';
  String _selectedBrand = 'All';
  String _sortBy = '';
  List<String> _selectedSizes = [];
  List<String> _selectedColors = [];
  RangeValues _priceRange = const RangeValues(0, 10000);

  List<Map<String, dynamic>> _products = [];
  bool _isProductsLoading = false;
  List<Map<String, dynamic>> _wishlistItems = [];
  bool _isWishlistLoading = false;

  bool _hasCartItems = false;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _notifications = [];
  bool _isNotificationsLoading = false;

  bool get _hasUnreadNotifications {
    return _notifications.any((notification) {
      final value = notification['is_read'];
      return value == 0 || value == '0' || value == false || value == 'false';
    });
  }

  int _chatRefreshKey = 0;

  bool get _isSearchingOrFiltering {
    return _searchQuery.isNotEmpty ||
        _selectedCategory != 'All' ||
        _selectedGender != 'All' ||
        _selectedBrand != 'All' ||
        _selectedSizes.isNotEmpty ||
        _selectedColors.isNotEmpty ||
        _priceRange.start != 0 ||
        _priceRange.end != 10000 ||
        _sortBy.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _fetchStores();
    _checkCartStatus();
    _fetchUserData();
    if (widget.userId != null) {
      _loadWishlistItems();
      _loadNotifications();
    }
  }

  Future<void> _fetchUserData() async {
    if (widget.userId == null) return;

    try {
      final result = await ApiService.getUserById(widget.userId!);
      if (result['success'] && result['data'] != null) {
        if (mounted) {
          setState(() {
            _userData = result['data'];
          });
        }
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStores() async {
    setState(() => _isStoresLoading = true);

    try {
      final result = await ApiService.getAllStores();
      if (result['success']) {
        setState(() {
          _stores = List<Map<String, dynamic>>.from(result['data']);
        });
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() => _isStoresLoading = false);
      }
    }
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() => _isProductsLoading = true);

    try {
      final result = await ApiService.getAllProducts(
        search: _searchQuery,
        userId: widget.userId,
        category: _selectedCategory,
        gender: _selectedGender,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
        sortBy: _sortBy,
        sizes: _selectedSizes,
        colors: _selectedColors,
        brand: _selectedBrand,
      );

      if (result['success']) {
        if (mounted) {
          setState(() {
            _products = List<Map<String, dynamic>>.from(result['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    } finally {
      if (mounted) {
        setState(() => _isProductsLoading = false);
      }
    }
  }

  Future<void> _checkCartStatus() async {
    if (widget.userId != null) {
      try {
        final result = await ApiService.getCartItems(widget.userId!);
        if (result['success']) {
          final List items = result['data'];
          if (mounted) {
            setState(() {
              _hasCartItems = items.isNotEmpty;
            });
          }
        }
      } catch (e) {
        
      }
    }
  }

  Future<void> _loadWishlistItems() async {
    if (widget.userId == null) return;
    setState(() => _isWishlistLoading = true);
    try {
      final result = await ApiService.getWishlistItems(widget.userId!);
      if (mounted && result['success']) {
        setState(() {
          _wishlistItems = List<Map<String, dynamic>>.from(result['data']);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isWishlistLoading = false);
    }
  }

  Future<void> _toggleWishlistItem(Map<String, dynamic> product) async {
    if (widget.userId == null) {
      _showSnackBar('Please log in to save favorites', CustomerHomeStyles.errorColor);
      return;
    }

    final productIdValue = product['product_id'] ?? product['id'];
    if (productIdValue == null) return;
    final productId = productIdValue is int ? productIdValue : int.tryParse(productIdValue.toString());
    if (productId == null) return;

    final isFavorited = (product['is_favorited'] == 1 || product['is_favorited'] == true);
    final result = await ApiService.toggleWishlistItem(
      userId: widget.userId!,
      productId: productId,
      isFavorited: isFavorited,
    );

    if (result['success']) {
      setState(() {
        product['is_favorited'] = isFavorited ? 0 : 1;

        if (isFavorited) {
          _wishlistItems.removeWhere((item) {
            final itemId = item['product_id'] ?? item['id'];
            return itemId != null && itemId.toString() == productId.toString();
          });
        } else {
          final alreadySaved = _wishlistItems.any((item) {
            final itemId = item['product_id'] ?? item['id'];
            return itemId != null && itemId.toString() == productId.toString();
          });
          if (!alreadySaved) {
            _wishlistItems.add(Map<String, dynamic>.from(product));
          }
        }

        if (_selectedIndex == 0) {
          _recommendationKey++;
        }
      });
    } else {
      _showSnackBar('Failed to update saved items', CustomerHomeStyles.errorColor);
    }
  }

  Future<void> _loadNotifications() async {
    if (widget.userId == null) return;

    setState(() => _isNotificationsLoading = true);
    try {
      final result = await ApiService.getUserNotifications(widget.userId!);
      if (!mounted) return;

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
          _isNotificationsLoading = false;
        });
      } else {
        _showSnackBar(
          result['message'] ?? 'Failed to load notifications',
          CustomerHomeStyles.errorColor,
        );
        setState(() => _isNotificationsLoading = false);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Failed to load notifications', CustomerHomeStyles.errorColor);
      setState(() => _isNotificationsLoading = false);
    }
  }

  Future<void> _showNotificationsSheet() async {
    await _loadNotifications();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CustomerHomeStyles.transparentColor,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: CustomerHomeStyles.filterSheetDecoration,
              child: Column(
                children: [
                  CustomerHomeStyles.sizedBoxHeight12,
                  Container(
                    width: CustomerHomeStyles.dragHandleWidth,
                    height: CustomerHomeStyles.dragHandleHeight,
                    decoration: CustomerHomeStyles.dragHandleDecoration,
                  ),
                  CustomerHomeStyles.sizedBoxHeight24,
                  const Text(
                    'Notifications',
                    style: CustomerHomeStyles.filterTitleStyle,
                  ),
                  CustomerHomeStyles.sizedBoxHeight24,
                  Expanded(
                    child: _isNotificationsLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: CustomerHomeStyles.primaryColor,
                            ),
                          )
                        : _notifications.isEmpty
                        ? const Center(child: Text('No notifications'))
                        : ListView.builder(
                            padding: CustomerHomeStyles.paddingH24,
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final notification = _notifications[index];
                              return _buildNotificationItem(
                                notification,
                                setSheetState,
                              );
                            },
                          ),
                  ),
                  CustomerHomeStyles.sizedBoxHeight32,
                ],
              ),
            );
          },
        );
      },
    );
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> _extractNotificationMeta(Map<String, dynamic> notification) {
    const possibleKeys = ['metadata', 'data', 'payload', 'extra_data'];
    for (final key in possibleKeys) {
      final value = notification[key];
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      if (value is String && value.trim().isNotEmpty) {
        try {
          final parsed = jsonDecode(value);
          if (parsed is Map<String, dynamic>) return parsed;
          if (parsed is Map) return Map<String, dynamic>.from(parsed);
        } catch (_) {
          // Ignore invalid JSON in notification metadata fields.
        }
      }
    }
    return <String, dynamic>{};
  }

  Future<void> _handleNotificationNavigation(Map<String, dynamic> notification) async {
    if (widget.userId == null || !mounted) return;

    final meta = _extractNotificationMeta(notification);
    final title = (notification['title'] ?? '').toString().toLowerCase();
    final message = (notification['message'] ?? '').toString().toLowerCase();
    final notificationType = (notification['type'] ?? meta['type'] ?? '')
        .toString()
        .toLowerCase();

    final productId = _toInt(
      notification['product_id'] ??
          meta['product_id'] ??
          meta['productId'] ??
          meta['id'],
    );
    final storeId = _toInt(
      notification['store_id'] ?? meta['store_id'] ?? meta['storeId'],
    );
    final orderId = _toInt(
      notification['order_id'] ?? meta['order_id'] ?? meta['orderId'],
    );
    final shouldOpenChat = notificationType.contains('chat') ||
        title.contains('chat') ||
        message.contains('chat') ||
        meta.containsKey('other_user_id') ||
        meta.containsKey('sender_id');

    Navigator.pop(context);

    if (productId != null) {
      final result = await ApiService.getProductById(productId.toString());
      if (result['success'] && result['data'] != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductDetailsScreen(product: result['data'], userId: widget.userId),
          ),
        );
        return;
      }
    }

    if (storeId != null && mounted) {
      final storeName = (notification['store_name'] ??
              meta['store_name'] ??
              meta['storeName'] ??
              'Store')
          .toString();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoreProductsScreen(
            storeId: storeId,
            storeName: storeName,
            userId: widget.userId,
          ),
        ),
      );
      return;
    }

    if (orderId != null ||
        notificationType.contains('order') ||
        title.contains('order') ||
        message.contains('order')) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyOrdersScreen(userId: widget.userId!),
        ),
      );
      return;
    }

    if (shouldOpenChat && mounted) {
      setState(() {
        _selectedIndex = 3;
        _chatRefreshKey++;
      });
      return;
    }

    _showSnackBar('No page linked to this notification yet', Colors.orangeAccent);
  }

  Widget _buildNotificationItem(
    Map<String, dynamic> notification,
    StateSetter setSheetState,
  ) {
    final message = notification['message']?.toString() ?? '';
    final title = notification['title']?.toString() ?? 'Notification';
    final isRead =
        (notification['is_read'] == 1 || notification['is_read'] == '1');
    final notificationId = notification['notification_id'];
    final timeAgo = _formatTimeAgo(notification['created_at']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          if (!isRead && notificationId != null) {
            final result = await ApiService.markUserNotificationRead(
              notificationId is int
                  ? notificationId
                  : int.parse(notificationId.toString()),
            );
            if (result['success']) {
              await _loadNotifications();
              if (mounted) setSheetState(() {});
            }
          }
          await _handleNotificationNavigation(notification);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: CustomerHomeStyles.notificationCardDecoration(isRead),
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
                      color: CustomerHomeStyles.primaryColor.withOpacity(0.1),
                      border: Border.all(
                        color: CustomerHomeStyles.primaryColor.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: CustomerHomeStyles.primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                  if (!isRead)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration:
                            CustomerHomeStyles.unreadIndicatorDecoration,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: CustomerHomeStyles.notificationTitleStyle,
                          ),
                        ),
                      ],
                    ),
                    CustomerHomeStyles.sizedBoxHeight4,
                    Text(
                      message,
                      style: CustomerHomeStyles.notificationMessageStyle(
                        isRead,
                      ),
                    ),
                    CustomerHomeStyles.sizedBoxHeight8,
                    Text(
                      timeAgo,
                      style: CustomerHomeStyles.notificationTimeStyle,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () async {
                  if (notificationId != null) {
                    final result = await ApiService.deleteUserNotification(
                      notificationId is int
                          ? notificationId
                          : int.parse(notificationId.toString()),
                    );
                    if (result['success']) {
                      await _loadNotifications();
                      if (mounted) setSheetState(() {});
                    }
                  }
                },
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
    if (difference.inDays > 7)
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    if (difference.inDays >= 1) return '${difference.inDays}d ago';
    if (difference.inHours >= 1) return '${difference.inHours}h ago';
    if (difference.inMinutes >= 1) return '${difference.inMinutes}m ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomerHomeStyles.whiteColor,
      extendBody: !kIsWeb,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_selectedIndex == 0 || _selectedIndex == 1)
              Padding(
                padding: CustomerHomeStyles.paddingSymmetricH24V16,
                child: Column(
                  children: [
                    if (_selectedIndex == 0) ...[
                      _buildHeader(),
                      CustomerHomeStyles.sizedBoxHeight24,
                    ],
                    _buildSearchBar(),
                  ],
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildHomeTab(),
                  _buildProductsTab(),
                  _buildFavoritesTab(),
                  ChatsListScreen(
                    key: ValueKey(_chatRefreshKey),
                    userId: widget.userId,
                    onBackPressed: () {
                      setState(() {
                        _selectedIndex = 0; 
                        _recommendationKey++;
                      });
                    },
                  ),
                  ProfileScreen(userId: widget.userId),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: kIsWeb ? null : _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeTab() {
      return SingleChildScrollView(
        padding: CustomerHomeStyles.paddingH24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBanner(),
            CustomerHomeStyles.sizedBoxHeight24,
            _buildCategories(),
            CustomerHomeStyles.sizedBoxHeight24,
            _buildRecommendations(),
            if (!kIsWeb) CustomerHomeStyles.sizedBoxHeight110,
          ],
        ),
      );
    }

    Widget _buildRecommendations() {
        if (widget.userId == null) return const SizedBox();

        return FutureBuilder<List<dynamic>>(
          key: ValueKey(_recommendationKey),
          future: Future.wait([
            ApiService.getRecommendations(widget.userId!),
            ApiService.getActivePromotionDiscounts(),
          ]),
          builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: CustomerHomeStyles.primaryColor,
              ),
            );
          }

          final results = snapshot.data;
          final recommendations = (results != null ? results[0] : <Map<String, dynamic>>[]) as List<Map<String, dynamic>>;
          final discounts = (results != null ? results[1] : <int, double>{}) as Map<int, double>;

          if (recommendations.isEmpty) return const SizedBox();

          final savedProductIds = _wishlistItems
              .map((item) => _toInt(item['product_id'] ?? item['id']))
              .whereType<int>()
              .toSet();
          for (final product in recommendations) {
            final productId = _toInt(product['product_id'] ?? product['id']);
            if (productId != null && savedProductIds.contains(productId)) {
              product['is_favorited'] = 1;
            }
            // Attach promotion discount for recommendation cards
            if (productId != null && discounts.containsKey(productId)) {
              product['promotion_discount'] = discounts[productId];
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recommended For You',
                style: CustomerHomeStyles.sectionHeaderStyle,
              ),
              CustomerHomeStyles.sizedBoxHeight16,
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) {
                    final product = recommendations[index];
                    return Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 12),
                      child: _buildProductCard(product),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    }
    
  Widget _buildFavoritesTab() {
    final title = 'Saved Items';
    if (widget.userId == null) {
      return Column(
        children: [
          _buildWishlistHeader(title),
          const Expanded(
            child: Center(
              child: Text('Please log in to view your saved products'),
            ),
          ),
        ],
      );
    }

    if (_isWishlistLoading) {
      return Column(
        children: [
          _buildWishlistHeader(title),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: CustomerHomeStyles.primaryColor,
              ),
            ),
          ),
        ],
      );
    }

    if (_wishlistItems.isEmpty) {
      return Column(
        children: [
          _buildWishlistHeader(title),
          const Expanded(
            child: Center(child: Text('No saved products yet')),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWishlistHeader(title),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
              return GridView.builder(
                padding: CustomerHomeStyles.paddingH24,
                itemCount: _wishlistItems.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) => _buildProductCard(_wishlistItems[index]),
              );
            },
          ),
        ),
        if (!kIsWeb) CustomerHomeStyles.sizedBoxHeight110,
      ],
    );
  }

  Widget _buildWishlistHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF704F38), size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _selectedIndex = 0;
              });
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_isSearchingOrFiltering) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _isProductsLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: CustomerHomeStyles.primaryColor,
                    ),
                  )
                : _products.isEmpty
                ? const Center(child: Text('No products found'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                      return GridView.builder(
                        padding: CustomerHomeStyles.paddingH24,
                        itemCount: _products.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemBuilder: (context, index) {
                          return _buildProductCard(_products[index]);
                        },
                      );
                    },
                  ),
          ),
          if (!kIsWeb) CustomerHomeStyles.sizedBoxHeight110,
        ],
      );
    }

    List<Map<String, dynamic>> displayedStores = _stores;
    if (_searchQuery.isNotEmpty) {
      displayedStores = _stores.where((store) {
        final name = (store['store_name'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _isStoresLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: CustomerHomeStyles.primaryColor,
                  ),
                )
              : displayedStores.isEmpty
              ? const Center(child: Text('No stores found'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                    return GridView.builder(
                      padding: CustomerHomeStyles.paddingH24,
                      itemCount: displayedStores.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.9,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemBuilder: (context, index) {
                        return _buildStoreCard(displayedStores[index]);
                      },
                    );
                  },
                ),
        ),
        if (!kIsWeb) CustomerHomeStyles.sizedBoxHeight110,
      ],
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    final String name = store['store_name'] ?? 'Store';
    final String logo = store['logo'] ?? '';
    final String rating = store['overall_rating']?.toString() ?? '0.0';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreProductsScreen(
              storeId: store['store_id'],
              storeName: name,
              userId: widget.userId,
            ),
          ),
        );
      },
      child: Container(
        decoration: CustomerHomeStyles.storeCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  color: CustomerHomeStyles.beigeBackgroundColor,
                  child: logo.isNotEmpty
                      ? (logo.startsWith('http')
                            ? Image.network(logo, fit: BoxFit.cover)
                            : Image.memory(
                                base64Decode(logo.split(',').last),
                                fit: BoxFit.cover,
                              ))
                      : const Center(
                          child: Icon(
                            Icons.store,
                            size: CustomerHomeStyles.storeIconSize,
                            color: CustomerHomeStyles.lightBrownColor,
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: CustomerHomeStyles.paddingAll12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CustomerHomeStyles.storeNameStyle,
                  ),
                  CustomerHomeStyles.sizedBoxHeight4,
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: CustomerHomeStyles.ratingColor,
                        size: 16,
                      ),
                      CustomerHomeStyles.sizedBoxWidth4,
                      Text(rating, style: CustomerHomeStyles.storeRatingStyle),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final String name = _userData?['name'] ?? _userData?['full_name'] ?? 'User';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hi,', style: CustomerHomeStyles.greetingLabelStyle),
            CustomerHomeStyles.sizedBoxHeight4,
            Text(name, style: CustomerHomeStyles.userNameStyle),
          ],
        ),
        Row(
          children: [
            if (_hasCartItems) ...[
              _buildHeaderActionButton(
                icon: Icons.shopping_bag_outlined,
                onPressed: () async {
                  if (widget.userId == null) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(userId: widget.userId!),
                    ),
                  );
                  _checkCartStatus();
                  _fetchStores();
                },
                showBadge: true,
              ),
              CustomerHomeStyles.sizedBoxWidth8,
            ],
            _buildHeaderActionButton(
              icon: Icons.notifications_outlined,
              onPressed: _showNotificationsSheet,
              showBadge: _hasUnreadNotifications,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool showBadge = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: CustomerHomeStyles.notificationIconDecoration,
          child: IconButton(
            icon: Icon(icon, color: CustomerHomeStyles.darkTextColor),
            onPressed: onPressed,
            splashColor: CustomerHomeStyles.transparentColor,
            highlightColor: CustomerHomeStyles.transparentColor,
            hoverColor: CustomerHomeStyles.transparentColor,
          ),
        ),
        if (showBadge)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: CustomerHomeStyles.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: CustomerHomeStyles.searchBarDecoration,
            child: Row(
              children: [
                CustomerHomeStyles.sizedBoxWidth16,
                const Icon(
                  Icons.search,
                  color: CustomerHomeStyles.lightGrayColor,
                  size: CustomerHomeStyles.searchIconSize,
                ),
                CustomerHomeStyles.sizedBoxWidth12,
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                    onSubmitted: (value) {
                        setState(() {
                            _searchQuery = value.trim();
                            if (_selectedIndex == 0) {
                                _selectedIndex = 1;
                            }
                        });
                        _fetchProducts();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      hintStyle: CustomerHomeStyles.searchHintStyle,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        CustomerHomeStyles.sizedBoxWidth16,
        Container(
          height: 52,
          width: 52,
          decoration: CustomerHomeStyles.filterIconDecoration,
          child: IconButton(
            icon: const Icon(Icons.tune, color: CustomerHomeStyles.whiteColor),
            onPressed: () => _showFilterBottomSheet(),
          ),
        ),
      ],
    );
  }

  Widget _buildBanner() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    return Container(
      width: double.infinity,
      height: isWeb
          ? CustomerHomeStyles.bannerHeightWeb
          : CustomerHomeStyles.bannerHeightApp,
      decoration: CustomerHomeStyles.bannerDecoration,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            top: isWeb ? 20 : 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: Image.asset(
                'assets/images/dashboard.png',
                height: isWeb
                    ? CustomerHomeStyles.bannerImageHeightWeb
                    : CustomerHomeStyles.bannerImageHeightApp,
                width: isWeb
                    ? CustomerHomeStyles.bannerImageWidthWeb
                    : CustomerHomeStyles.bannerImageWidthApp,
                fit: isWeb ? BoxFit.contain : BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: isWeb
                      ? CustomerHomeStyles.bannerImageHeightWeb
                      : CustomerHomeStyles.bannerImageHeightApp,
                  width: isWeb
                      ? CustomerHomeStyles.bannerImageWidthWeb
                      : CustomerHomeStyles.bannerImageWidthApp,
                  color: Colors.grey[300],
                  child: isWeb
                      ? const Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isWeb ? 48.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'New Collection',
                  style: isWeb
                      ? CustomerHomeStyles.bannerTitleWebStyle
                      : CustomerHomeStyles.bannerTitleStyle,
                ),
                SizedBox(height: isWeb ? 16 : 8),
                Text(
                  'Discount 50% for\nthe first transaction',
                  style: isWeb
                      ? CustomerHomeStyles.bannerSubtitleWebStyle
                      : CustomerHomeStyles.bannerSubtitleStyle,
                ),
                SizedBox(height: isWeb ? 32 : 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                      _sortBy = 'Newest';
                    });
                    _fetchProducts();
                  },
                  style: CustomerHomeStyles.bannerButtonStyle(isWeb: isWeb),
                  child: Text(
                    'Shop Now',
                    style: isWeb
                        ? CustomerHomeStyles.bannerButtonWebTextStyle
                        : CustomerHomeStyles.bannerButtonTextStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Category',
              style: CustomerHomeStyles.sectionHeaderStyle,
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.5),
                  barrierDismissible: true,
                  builder: (BuildContext dialogContext) {
                    return AllCategoriesDialog(
                      categories: categories,
                      onCategorySelected: (category) {
                        setState(() {
                          _selectedIndex = 1;
                          _selectedCategory = category;
                        });
                        _fetchProducts();
                      },
                    );
                  },
                );
              },
              child: const Text(
                'See All',
                style: CustomerHomeStyles.seeAllButtonStyle,
              ),
            ),
          ],
        ),
        CustomerHomeStyles.sizedBoxHeight16,
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isWeb = screenWidth > 600;

            if (isWeb) {
              return Wrap(
                spacing: 60,
                runSpacing: 24,
                alignment: WrapAlignment.start,
                children: List.generate(categories.length, (index) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                        _selectedCategory =
                            categories[index]['label'] as String;
                      });
                      _fetchProducts();
                    },
                    splashColor: CustomerHomeStyles.transparentColor,
                    highlightColor: CustomerHomeStyles.transparentColor,
                    child: Column(
                      children: [
                        Container(
                          height: 80,
                          width: 80,
                          decoration: CustomerHomeStyles.categoryIconDecoration,
                          alignment: Alignment.center,
                          child: Image.asset(
                            categories[index]['icon'] as String,
                            key: ValueKey('cat_web_$index'),
                            width: CustomerHomeStyles.categoryIconSizeWeb,
                            height: CustomerHomeStyles.categoryIconSizeWeb,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.category,
                                color: CustomerHomeStyles.primaryColor,
                                size: 40,
                              );
                            },
                          ),
                        ),
                        CustomerHomeStyles.sizedBoxHeight12,
                        Text(
                          categories[index]['label'] as String,
                          style: CustomerHomeStyles.categoryWebLabelStyle,
                        ),
                      ],
                    ),
                  );
                }),
              );
            } else {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                        _selectedCategory =
                            categories[index]['label'] as String;
                      });
                      _fetchProducts();
                    },
                    splashColor: CustomerHomeStyles.transparentColor,
                    highlightColor: CustomerHomeStyles.transparentColor,
                    child: Column(
                      children: [
                        Container(
                          height: 60,
                          width: 60,
                          decoration: CustomerHomeStyles.categoryIconDecoration,
                          alignment: Alignment.center,
                          child: Image.asset(
                            categories[index]['icon'] as String,
                            key: ValueKey('cat_app_$index'),
                            width: CustomerHomeStyles.categoryIconSizeApp,
                            height: CustomerHomeStyles.categoryIconSizeApp,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.category,
                                color: CustomerHomeStyles.primaryColor,
                                size: 30,
                              );
                            },
                          ),
                        ),
                        CustomerHomeStyles.sizedBoxHeight8,
                        Text(
                          categories[index]['label'] as String,
                          style: CustomerHomeStyles.categoryLabelStyle,
                        ),
                      ],
                    ),
                  );
                }),
              );
            }
          },
        ),
      ],
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CustomerHomeStyles.transparentColor,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: CustomerHomeStyles.filterSheetDecoration,
              child: Column(
                children: [
                  CustomerHomeStyles.sizedBoxHeight12,
                  Container(
                    width: CustomerHomeStyles.dragHandleWidth,
                    height: CustomerHomeStyles.dragHandleHeight,
                    decoration: CustomerHomeStyles.dragHandleDecoration,
                  ),
                  CustomerHomeStyles.sizedBoxHeight24,
                  Expanded(
                    child: ListView(
                      padding: CustomerHomeStyles.paddingH24,
                      children: [
                        const Center(
                          child: Text(
                            'Filter',
                            style: CustomerHomeStyles.filterTitleStyle,
                          ),
                        ),
                        CustomerHomeStyles.sizedBoxHeight32,

                        const Text(
                          'Sort By',
                          style: CustomerHomeStyles.filterSectionTitleStyle,
                        ),
                        CustomerHomeStyles.sizedBoxHeight16,
                        Wrap(
                          spacing: 12,
                          children:
                              [
                                'Newest',
                                'Price: Low to High',
                                'Price: High to Low',
                              ].map((option) {
                                final isSelected = _sortBy == option;
                                return ChoiceChip(
                                  label: Text(option),
                                  selected: isSelected,
                                  showCheckmark: false,
                                  pressElevation: 0,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setSheetState(() => _sortBy = option);
                                    }
                                  },
                                  backgroundColor: CustomerHomeStyles
                                      .lightBrownColor
                                      .withOpacity(0.15),
                                  selectedColor:
                                      CustomerHomeStyles.primaryColor,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? CustomerHomeStyles.whiteColor
                                        : CustomerHomeStyles.darkTextColor,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected
                                          ? CustomerHomeStyles.primaryColor
                                          : CustomerHomeStyles.transparentColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),

                        CustomerHomeStyles.sizedBoxHeight32,

                        const Text(
                          'Gender',
                          style: CustomerHomeStyles.filterSectionTitleStyle,
                        ),
                        CustomerHomeStyles.sizedBoxHeight16,
                        Wrap(
                          spacing: 12,
                          children: ['All', 'Male', 'Female'].map((gender) {
                            final isSelected = _selectedGender == gender;
                            return ChoiceChip(
                              label: Text(gender),
                              selected: isSelected,
                              showCheckmark: false,
                              pressElevation: 0,
                              onSelected: (selected) {
                                if (selected) {
                                  setSheetState(() => _selectedGender = gender);
                                }
                              },
                              backgroundColor: CustomerHomeStyles
                                  .lightBrownColor
                                  .withOpacity(0.15),
                              selectedColor: CustomerHomeStyles.primaryColor,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? CustomerHomeStyles.whiteColor
                                    : CustomerHomeStyles.darkTextColor,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? CustomerHomeStyles.primaryColor
                                      : CustomerHomeStyles.transparentColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        CustomerHomeStyles.sizedBoxHeight32,

                        const Text(
                          'Category',
                          style: CustomerHomeStyles.filterSectionTitleStyle,
                        ),
                        CustomerHomeStyles.sizedBoxHeight16,
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children:
                              [
                                'All',
                                'Tops',
                                'Bottoms',
                                'Dresses',
                                'Sets',
                                'Activewear',
                                'Sleepwear',
                              ].map((category) {
                                final isSelected =
                                    _selectedCategory == category;
                                return ChoiceChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  showCheckmark: false,
                                  pressElevation: 0,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setSheetState(
                                        () => _selectedCategory = category,
                                      );
                                    }
                                  },
                                  backgroundColor: CustomerHomeStyles
                                      .lightBrownColor
                                      .withOpacity(0.15),
                                  selectedColor:
                                      CustomerHomeStyles.primaryColor,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? CustomerHomeStyles.whiteColor
                                        : CustomerHomeStyles.darkTextColor,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected
                                          ? CustomerHomeStyles.primaryColor
                                          : CustomerHomeStyles.transparentColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        CustomerHomeStyles.sizedBoxHeight32,

                        const Text(
                          'Size',
                          style: CustomerHomeStyles.filterSectionTitleStyle,
                        ),
                        CustomerHomeStyles.sizedBoxHeight16,
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children:
                              [
                                'X Small',
                                'Small',
                                'Medium',
                                'Large',
                                'XL',
                                'XXL',
                                'XXXL',
                              ].map((size) {
                                final isSelected = _selectedSizes.contains(
                                  size,
                                );
                                return FilterChip(
                                  label: Text(size),
                                  selected: isSelected,
                                  showCheckmark: false,
                                  pressElevation: 0,
                                  onSelected: (selected) {
                                    setSheetState(() {
                                      if (selected) {
                                        _selectedSizes.add(size);
                                      } else {
                                        _selectedSizes.remove(size);
                                      }
                                    });
                                  },
                                  backgroundColor: CustomerHomeStyles
                                      .lightBrownColor
                                      .withOpacity(0.15),
                                  selectedColor:
                                      CustomerHomeStyles.primaryColor,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? CustomerHomeStyles.whiteColor
                                        : CustomerHomeStyles.darkTextColor,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected
                                          ? CustomerHomeStyles.primaryColor
                                          : CustomerHomeStyles.transparentColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),

                        CustomerHomeStyles.sizedBoxHeight32,

                        const Text(
                          'Color',
                          style: CustomerHomeStyles.filterSectionTitleStyle,
                        ),
                        CustomerHomeStyles.sizedBoxHeight16,
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children:
                              [
                                'Black',
                                'White',
                                'Red',
                                'Blue',
                                'Green',
                                'Brown',
                                'Yellow',
                                'Pink',
                                'Purple',
                                'Orange',
                              ].map((color) {
                                final isSelected = _selectedColors.contains(
                                  color,
                                );
                                return FilterChip(
                                  label: Text(color),
                                  selected: isSelected,
                                  showCheckmark: false,
                                  pressElevation: 0,
                                  onSelected: (selected) {
                                    setSheetState(() {
                                      if (selected) {
                                        _selectedColors.add(color);
                                      } else {
                                        _selectedColors.remove(color);
                                      }
                                    });
                                  },
                                  backgroundColor: CustomerHomeStyles
                                      .lightBrownColor
                                      .withOpacity(0.15),
                                  selectedColor:
                                      CustomerHomeStyles.primaryColor,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? CustomerHomeStyles.whiteColor
                                        : CustomerHomeStyles.darkTextColor,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected
                                          ? CustomerHomeStyles.primaryColor
                                          : CustomerHomeStyles.transparentColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),

                        CustomerHomeStyles.sizedBoxHeight32,

                        const Text(
                          'Brands',
                          style: CustomerHomeStyles.filterSectionTitleStyle,
                        ),
                        CustomerHomeStyles.sizedBoxHeight16,
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: (() {
                            final brands = [
                              'All',
                              ..._stores
                                  .map((s) => s['store_name']?.toString() ?? '')
                                  .where((s) => s.isNotEmpty)
                                  .toSet()
                                  .toList(),
                            ];
                            return brands.map((brand) {
                              final isSelected = _selectedBrand == brand;
                              return ChoiceChip(
                                label: Text(brand),
                                selected: isSelected,
                                showCheckmark: false,
                                pressElevation: 0,
                                onSelected: (selected) {
                                  if (selected) {
                                    setSheetState(() => _selectedBrand = brand);
                                  }
                                },
                                backgroundColor: CustomerHomeStyles
                                    .lightBrownColor
                                    .withOpacity(0.15),
                                selectedColor: CustomerHomeStyles.primaryColor,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? CustomerHomeStyles.whiteColor
                                      : CustomerHomeStyles.darkTextColor,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? CustomerHomeStyles.primaryColor
                                        : CustomerHomeStyles.transparentColor,
                                  ),
                                ),
                              );
                            }).toList();
                          })(),
                        ),

                        CustomerHomeStyles.sizedBoxHeight32,

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Price Range',
                              style: CustomerHomeStyles.filterSectionTitleStyle,
                            ),
                            Text(
                              'Rs ${_priceRange.start.round()} - Rs ${_priceRange.end.round()}',
                              style: CustomerHomeStyles.priceRangeLabelStyle,
                            ),
                          ],
                        ),
                        CustomerHomeStyles.sizedBoxHeight16,
                        RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: 10000,
                          divisions: 100,
                          activeColor: CustomerHomeStyles.primaryColor,
                          inactiveColor:
                              CustomerHomeStyles.beigeBackgroundColor,
                          labels: RangeLabels(
                            'Rs ${_priceRange.start.round()}',
                            'Rs ${_priceRange.end.round()}',
                          ),
                          onChanged: (values) {
                            setSheetState(() {
                              _priceRange = values;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: CustomerHomeStyles.paddingAll24,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                _sortBy = '';
                                _selectedGender = 'All';
                                _selectedCategory = 'All';
                                _selectedBrand = 'All';
                                _selectedSizes.clear();
                                _selectedColors.clear();
                                _priceRange = const RangeValues(0, 10000);
                              });
                              setState(() {});
                            },
                            style: CustomerHomeStyles.resetButtonStyle,
                            child: const Text(
                              'Reset',
                              style: CustomerHomeStyles.resetButtonTextStyle,
                            ),
                          ),
                        ),
                        CustomerHomeStyles.sizedBoxWidth16,
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                if (_selectedIndex == 0) _selectedIndex = 1;
                              });
                              _fetchProducts();
                              Navigator.pop(context);
                            },
                            style: CustomerHomeStyles.applyButtonStyle,
                            child: const Text(
                              'Apply',
                              style: CustomerHomeStyles.applyButtonTextStyle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['product_name'] ?? product['name'] ?? 'Product';
    final rawPrice = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
    final storeName = product['store_name']?.toString() ?? 'Verified Store';
    final images = product['product_images'] as List?;
    final imageSource = (images != null && images.isNotEmpty)
        ? images[0].toString()
        : '';
    final isFavorited = product['is_favorited'] == 1 || product['is_favorited'] == true;

    // Promotion discount
    final discountRaw = product['promotion_discount'];
    final discount = discountRaw != null
        ? (discountRaw is num ? discountRaw.toDouble() : double.tryParse(discountRaw.toString()))
        : null;
    final hasDiscount = discount != null && discount > 0;
    final discountedPrice = hasDiscount ? rawPrice * (1 - discount! / 100) : null;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductDetailsScreen(product: product, userId: widget.userId),
          ),
        );
        if (!mounted) return;
        if (_selectedIndex == 2) {
          await _loadWishlistItems();
        }
        setState(() {});
        _fetchStores();
        _checkCartStatus();
      },
      child: Container(
        decoration: CustomerHomeStyles.productCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      color: CustomerHomeStyles.beigeBackgroundColor
                          .withOpacity(0.5),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: imageSource.isEmpty
                          ? const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: CustomerHomeStyles.lightGrayColor,
                              ),
                            )
                          : (imageSource.startsWith('assets/')
                                ? Image.asset(
                                    imageSource,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: CustomerHomeStyles
                                                    .lightGrayColor,
                                              ),
                                            ),
                                  )
                                : (imageSource.startsWith('http')
                                      ? Image.network(
                                          imageSource,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          alignment: Alignment.topCenter,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Center(
                                                    child: Icon(
                                                      Icons.image_not_supported,
                                                      color: CustomerHomeStyles
                                                          .lightGrayColor,
                                                    ),
                                                  ),
                                        )
                                      : Image.memory(
                                          base64Decode(
                                            imageSource.split(',').last,
                                          ),
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          alignment: Alignment.topCenter,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Center(
                                                    child: Icon(
                                                      Icons.image_not_supported,
                                                      color: CustomerHomeStyles
                                                          .lightGrayColor,
                                                    ),
                                                  ),
                                        ))),
                    ),
                  ),
                  // Discount badge (top-left)
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4845A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${discount!.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  // Favourite button (top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        await _toggleWishlistItem(product);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: CustomerHomeStyles.favoriteIconDecoration,
                        child: Icon(
                          isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: CustomerHomeStyles.primaryColor,
                          size: CustomerHomeStyles.favoriteIconSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: CustomerHomeStyles.paddingAll12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeName,
                    style: CustomerHomeStyles.productStoreNameStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  CustomerHomeStyles.sizedBoxHeight4,
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CustomerHomeStyles.productNameStyle,
                  ),
                  CustomerHomeStyles.sizedBoxHeight8,
                  if (hasDiscount)
                    Row(
                      children: [
                        Text(
                          'Rs ${rawPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Rs ${discountedPrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD4845A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Rs ${rawPrice.toStringAsFixed(0)}',
                      style: CustomerHomeStyles.productPriceStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: CustomerHomeStyles.paddingV20H24,
      decoration: const BoxDecoration(
        color: CustomerHomeStyles.transparentColor,
      ),
      child: Container(
        height: CustomerHomeStyles.navBarHeight,
        decoration: CustomerHomeStyles.bottomNavBarContainerDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home, 0),
            _buildNavItem(Icons.shopping_bag_outlined, 1),
            _buildNavItem(Icons.favorite_border, 2),
            _buildNavItem(Icons.chat_bubble_outline, 3),
            _buildNavItem(Icons.person_outline, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (index == 0 || index == 1) {
          _fetchStores();
          _checkCartStatus();
          _fetchUserData();
          if (index == 0) _recommendationKey++;
          if (index == 1) {
            _fetchProducts();
          }
        }
        if (index == 2) {
          _loadWishlistItems();
        }
        if (index == 3) {
          setState(() => _chatRefreshKey++);
        }
      },
      child: Container(
        padding: CustomerHomeStyles.paddingNavContainer,
        decoration: CustomerHomeStyles.navItemActiveDecoration(isSelected),
        child: Icon(
          icon,
          color: isSelected
              ? CustomerHomeStyles.primaryColor
              : CustomerHomeStyles.whiteColor.withOpacity(0.5),
          size: CustomerHomeStyles.navIconSize,
        ),
      ),
    );
  }
}

class AllCategoriesDialog extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final Function(String) onCategorySelected;

  const AllCategoriesDialog({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  State<AllCategoriesDialog> createState() => _AllCategoriesDialogState();
}

class _AllCategoriesDialogState extends State<AllCategoriesDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
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
              backgroundColor: CustomerHomeStyles.transparentColor,
              elevation: 0,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile
                    ? screenWidth * 0.1
                    : MediaQuery.of(context).size.width * 0.2,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 600,
                ),
                decoration: CustomerHomeStyles.dialogDecoration,
                child: Padding(
                  padding: CustomerHomeStyles.paddingAll24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'All Categories',
                        style: CustomerHomeStyles.dialogTitleStyle,
                      ),
                      CustomerHomeStyles.sizedBoxHeight8,
                      const Text(
                        'Browse products by category',
                        textAlign: TextAlign.center,
                        style: CustomerHomeStyles.dialogSubtitleStyle,
                      ),
                      CustomerHomeStyles.sizedBoxHeight24,
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            alignment: WrapAlignment.center,
                            children: widget.categories.asMap().entries.map((
                              entry,
                            ) {
                              final index = entry.key;
                              final category = entry.value;
                              return InkWell(
                                onTap: () {
                                  widget.onCategorySelected(
                                    category['label'] as String,
                                  );
                                  Navigator.of(context).pop();
                                },
                                splashColor:
                                    CustomerHomeStyles.transparentColor,
                                highlightColor:
                                    CustomerHomeStyles.transparentColor,
                                child: Column(
                                  children: [
                                    Container(
                                      height: 60,
                                      width: 60,
                                      decoration: CustomerHomeStyles
                                          .categoryIconDecoration,
                                      alignment: Alignment.center,
                                      child: Image.asset(
                                        category['icon'] as String,
                                        key: ValueKey('cat_dialog_$index'),
                                        width: CustomerHomeStyles
                                            .categoryIconSizeApp,
                                        height: CustomerHomeStyles
                                            .categoryIconSizeApp,
                                        fit: BoxFit.contain,
                                        gaplessPlayback: true,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.category,
                                                color: CustomerHomeStyles
                                                    .primaryColor,
                                                size: 30,
                                              );
                                            },
                                      ),
                                    ),
                                    CustomerHomeStyles.sizedBoxHeight8,
                                    Text(
                                      category['label'] as String,
                                      style:
                                          CustomerHomeStyles.categoryLabelStyle,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
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
}
