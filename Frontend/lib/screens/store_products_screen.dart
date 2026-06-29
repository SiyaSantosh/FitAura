import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../styles/app_colors.dart';
import '../styles/store_products_styles.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';

class StoreProductsScreen extends StatefulWidget {
  final int storeId;
  final String storeName;
  final int? userId; 

  const StoreProductsScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    this.userId,
  });

  @override
  State<StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<StoreProductsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _hasCartItems = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _selectedGender = 'All';
  String _selectedCategory = 'All';
  String _sortBy = 'Newest';
  List<String> _selectedColors = [];
  List<String> _selectedSizes = [];
  RangeValues _priceRange = const RangeValues(0, 10000);

  @override
  void initState() {
    super.initState();
    _fetchStoreProducts();
    _checkCartStatus();
  }

  Future<void> _fetchStoreProducts() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getStoreProducts(
        widget.storeId,
        role: 'customer',
        userId: widget.userId,
      );
      if (result['success']) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(result['data']);
          _filterProducts();
        });
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterProducts() {
    setState(() {
      List<Map<String, dynamic>> results = List.from(_products);

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        results = results.where((product) {
          final name = (product['product_name'] ?? '').toString().toLowerCase();
          final description = (product['description'] ?? '')
              .toString()
              .toLowerCase();
          return name.contains(query) || description.contains(query);
        }).toList();
      }

      if (_selectedCategory != 'All') {
        results = results.where((product) {
          return (product['category'] ?? '').toString() == _selectedCategory;
        }).toList();
      }

      if (_selectedGender != 'All') {
        results = results.where((product) {
          final gender = (product['gender'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          return gender == _selectedGender.trim().toLowerCase();
        }).toList();
      }

      results = results.where((product) {
        final price =
            double.tryParse((product['price'] ?? '0').toString()) ?? 0.0;
        return price >= _priceRange.start && price <= _priceRange.end;
      }).toList();

      if (_selectedColors.isNotEmpty) {
        results = results.where((product) {
          final productColors =
              (product['colors'] as List?)
                  ?.map((c) => c.toString().trim().toLowerCase())
                  .toList() ??
              [];
          return _selectedColors.any(
            (selected) => productColors.contains(selected.trim().toLowerCase()),
          );
        }).toList();
      }

      if (_selectedSizes.isNotEmpty) {
        results = results.where((product) {
          final productSizes =
              (product['sizes'] as List?)
                  ?.map((s) => s.toString().trim().toLowerCase())
                  .toList() ??
              [];
          return _selectedSizes.any(
            (selected) => productSizes.contains(selected.trim().toLowerCase()),
          );
        }).toList();
      }

      if (_sortBy == 'Price: Low to High') {
        results.sort((a, b) {
          final pa = double.tryParse((a['price'] ?? '0').toString()) ?? 0.0;
          final pb = double.tryParse((b['price'] ?? '0').toString()) ?? 0.0;
          return pa.compareTo(pb);
        });
      } else if (_sortBy == 'Price: High to Low') {
        results.sort((a, b) {
          final pa = double.tryParse((a['price'] ?? '0').toString()) ?? 0.0;
          final pb = double.tryParse((b['price'] ?? '0').toString()) ?? 0.0;
          return pb.compareTo(pa);
        });
      } else {
        
        results.sort((a, b) {
          final idA = int.tryParse((a['product_id'] ?? '0').toString()) ?? 0;
          final idB = int.tryParse((b['product_id'] ?? '0').toString()) ?? 0;
          return idB.compareTo(idA);
        });
      }

      _filteredProducts = results;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.black}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _toggleWishlistItem(Map<String, dynamic> product) async {
    if (widget.userId == null) {
      _showSnackBar('Please log in to save favorites', backgroundColor: Colors.red);
      return;
    }

    final productIdVal = product['product_id'] ?? product['id'];
    if (productIdVal == null) return;
    final productId = productIdVal is int ? productIdVal : int.tryParse(productIdVal.toString());
    if (productId == null) return;

    final isFavorited = product['is_favorited'] == 1 || product['is_favorited'] == true;
    final result = await ApiService.toggleWishlistItem(
      userId: widget.userId!,
      productId: productId,
      isFavorited: isFavorited,
    );
    if (result['success']) {
      setState(() {
        product['is_favorited'] = isFavorited ? 0 : 1;
      });
    } else {
      _showSnackBar('Failed to update saved items', backgroundColor: Colors.red);
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: StoreProductsStyles.transparentColor,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height:
                  MediaQuery.of(context).size.height *
                  StoreProductsStyles.filterBottomSheetHeightFactor,
              decoration: StoreProductsStyles.filterBottomSheetDecoration,
              child: Column(
                children: [
                  StoreProductsStyles.vSpaceDragHandle,
                  Container(
                    width: StoreProductsStyles.dragHandleWidth,
                    height: StoreProductsStyles.dragHandleHeight,
                    decoration: StoreProductsStyles.dragHandleDecoration,
                  ),
                  StoreProductsStyles.vSpaceExtraLarge,
                  Expanded(
                    child: SingleChildScrollView(
                      padding: StoreProductsStyles.filterContentPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Filter',
                                style: StoreProductsStyles.headerStyle,
                              ),
                              IconButton(
                                icon: const Icon(StoreProductsStyles.closeIcon),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          StoreProductsStyles.vSpaceExtraLarge,

                          const Text(
                            'Sort By',
                            style: StoreProductsStyles.sectionTitleStyle,
                          ),
                          StoreProductsStyles.vSpaceLarge,
                          Wrap(
                            spacing: StoreProductsStyles.wrapSpacing,
                            runSpacing: StoreProductsStyles.wrapRunSpacing,
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
                                      if (selected)
                                        setSheetState(() => _sortBy = option);
                                    },
                                    backgroundColor:
                                        StoreProductsStyles.chipBackgroundColor(
                                          false,
                                        ),
                                    selectedColor:
                                        StoreProductsStyles.chipBackgroundColor(
                                          true,
                                        ),
                                    labelStyle: StoreProductsStyles
                                        .chipLabelStyle
                                        .copyWith(
                                          color:
                                              StoreProductsStyles.chipLabelColor(
                                                isSelected,
                                              ),
                                          fontWeight:
                                              StoreProductsStyles.chipLabelWeight(
                                                isSelected,
                                              ),
                                        ),
                                    shape: StoreProductsStyles.chipShape(
                                      isSelected,
                                    ),
                                  );
                                }).toList(),
                          ),
                          StoreProductsStyles.vSpaceSection,

                          const Text(
                            'Gender',
                            style: StoreProductsStyles.sectionTitleStyle,
                          ),
                          StoreProductsStyles.vSpaceLarge,
                          Wrap(
                            spacing: StoreProductsStyles.wrapSpacing,
                            runSpacing: StoreProductsStyles.wrapRunSpacing,
                            children: ['All', 'Male', 'Female'].map((gender) {
                              final isSelected = _selectedGender == gender;
                              return ChoiceChip(
                                label: Text(gender),
                                selected: isSelected,
                                showCheckmark: false,
                                pressElevation: 0,
                                onSelected: (selected) {
                                  if (selected)
                                    setSheetState(
                                      () => _selectedGender = gender,
                                    );
                                },
                                backgroundColor:
                                    StoreProductsStyles.chipBackgroundColor(
                                      false,
                                    ),
                                selectedColor:
                                    StoreProductsStyles.chipBackgroundColor(
                                      true,
                                    ),
                                labelStyle: StoreProductsStyles.chipLabelStyle
                                    .copyWith(
                                      color: StoreProductsStyles.chipLabelColor(
                                        isSelected,
                                      ),
                                      fontWeight:
                                          StoreProductsStyles.chipLabelWeight(
                                            isSelected,
                                          ),
                                    ),
                                shape: StoreProductsStyles.chipShape(
                                  isSelected,
                                ),
                              );
                            }).toList(),
                          ),
                          StoreProductsStyles.vSpaceSection,

                          const Text(
                            'Category',
                            style: StoreProductsStyles.sectionTitleStyle,
                          ),
                          StoreProductsStyles.vSpaceLarge,
                          Wrap(
                            spacing: StoreProductsStyles.wrapSpacing,
                            runSpacing: StoreProductsStyles.wrapRunSpacing,
                            children:
                                [
                                  'All',
                                  'Tops',
                                  'Bottoms',
                                  'Dresses',
                                  'Sets',
                                  'Activewear',
                                  'Sleepwear',
                                ].map((cat) {
                                  final isSelected = _selectedCategory == cat;
                                  return ChoiceChip(
                                    label: Text(cat),
                                    selected: isSelected,
                                    showCheckmark: false,
                                    pressElevation: 0,
                                    onSelected: (selected) {
                                      if (selected)
                                        setSheetState(
                                          () => _selectedCategory = cat,
                                        );
                                    },
                                    backgroundColor:
                                        StoreProductsStyles.chipBackgroundColor(
                                          false,
                                        ),
                                    selectedColor:
                                        StoreProductsStyles.chipBackgroundColor(
                                          true,
                                        ),
                                    labelStyle: StoreProductsStyles
                                        .chipLabelStyle
                                        .copyWith(
                                          color:
                                              StoreProductsStyles.chipLabelColor(
                                                isSelected,
                                              ),
                                          fontWeight:
                                              StoreProductsStyles.chipLabelWeight(
                                                isSelected,
                                              ),
                                        ),
                                    shape: StoreProductsStyles.chipShape(
                                      isSelected,
                                    ),
                                  );
                                }).toList(),
                          ),
                          StoreProductsStyles.vSpaceSection,

                          const Text(
                            'Color',
                            style: StoreProductsStyles.sectionTitleStyle,
                          ),
                          StoreProductsStyles.vSpaceLarge,
                          Wrap(
                            spacing: StoreProductsStyles.wrapSpacing,
                            runSpacing: StoreProductsStyles.wrapRunSpacing,
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
                                    backgroundColor:
                                        StoreProductsStyles.chipBackgroundColor(
                                          false,
                                        ),
                                    selectedColor:
                                        StoreProductsStyles.chipBackgroundColor(
                                          true,
                                        ),
                                    labelStyle: StoreProductsStyles
                                        .chipLabelStyle
                                        .copyWith(
                                          color:
                                              StoreProductsStyles.chipLabelColor(
                                                isSelected,
                                              ),
                                          fontWeight:
                                              StoreProductsStyles.chipLabelWeight(
                                                isSelected,
                                              ),
                                        ),
                                    shape: StoreProductsStyles.chipShape(
                                      isSelected,
                                    ),
                                  );
                                }).toList(),
                          ),
                          StoreProductsStyles.vSpaceSection,

                          const Text(
                            'Size',
                            style: StoreProductsStyles.sectionTitleStyle,
                          ),
                          StoreProductsStyles.vSpaceLarge,
                          Wrap(
                            spacing: StoreProductsStyles.wrapSpacing,
                            runSpacing: StoreProductsStyles.wrapRunSpacing,
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
                                    backgroundColor:
                                        StoreProductsStyles.chipBackgroundColor(
                                          false,
                                        ),
                                    selectedColor:
                                        StoreProductsStyles.chipBackgroundColor(
                                          true,
                                        ),
                                    labelStyle: StoreProductsStyles
                                        .chipLabelStyle
                                        .copyWith(
                                          color:
                                              StoreProductsStyles.chipLabelColor(
                                                isSelected,
                                              ),
                                          fontWeight:
                                              StoreProductsStyles.chipLabelWeight(
                                                isSelected,
                                              ),
                                        ),
                                    shape: StoreProductsStyles.chipShape(
                                      isSelected,
                                    ),
                                  );
                                }).toList(),
                          ),
                          StoreProductsStyles.vSpaceSection,

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Price Range',
                                style: StoreProductsStyles.sectionTitleStyle,
                              ),
                              Text(
                                'Rs ${_priceRange.start.round()} - Rs ${_priceRange.end.round()}',
                                style: StoreProductsStyles.priceRangeLabelStyle,
                              ),
                            ],
                          ),
                          StoreProductsStyles.vSpaceLarge,
                          RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 10000,
                            divisions: 100,
                            activeColor: StoreProductsStyles.primaryColor,
                            inactiveColor: StoreProductsStyles.secondaryColor,
                            onChanged: (values) {
                              setSheetState(() => _priceRange = values);
                            },
                          ),
                          StoreProductsStyles.vSpaceXXL,
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: StoreProductsStyles.filterFooterPadding,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                _selectedGender = 'All';
                                _selectedCategory = 'All';
                                _sortBy = 'Newest';
                                _selectedColors.clear();
                                _selectedSizes.clear();
                                _priceRange = const RangeValues(0, 10000);
                              });
                            },
                            style: StoreProductsStyles.actionButtonStyle(
                              isPrimary: false,
                            ),
                            child: Text(
                              'Reset',
                              style: StoreProductsStyles.actionButtonTextStyle(
                                isPrimary: false,
                              ),
                            ),
                          ),
                        ),
                        StoreProductsStyles.hSpaceSection,
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _filterProducts();
                              Navigator.pop(context);
                            },
                            style: StoreProductsStyles.actionButtonStyle(
                              isPrimary: true,
                            ),
                            child: Text(
                              'Apply',
                              style: StoreProductsStyles.actionButtonTextStyle(
                                isPrimary: true,
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
          },
        );
      },
    );
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
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StoreProductsStyles.whiteColor,
      appBar: AppBar(
        backgroundColor: StoreProductsStyles.whiteColor,
        elevation: 0,
        surfaceTintColor: StoreProductsStyles.transparentColor,
        leading: IconButton(
          icon: const Icon(
            StoreProductsStyles.backIcon,
            color: StoreProductsStyles.primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.storeName,
          style: StoreProductsStyles.appBarTitleStyle,
        ),
        centerTitle: true,
        actions: [
          if (_hasCartItems)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: StoreProductsStyles.secondaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.shopping_bag_outlined,
                        color: StoreProductsStyles.primaryColor,
                        size: 20,
                      ),
                      onPressed: () async {
                        if (widget.userId == null) return;
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CartScreen(userId: widget.userId!),
                          ),
                        );
                        _checkCartStatus();
                      },
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: StoreProductsStyles.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: StoreProductsStyles.primaryColor,
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickySearchDelegate(
                    child: Container(
                      color: StoreProductsStyles.whiteColor,
                      padding: StoreProductsStyles.searchBarPadding,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: StoreProductsStyles.searchFieldHeight,
                              decoration:
                                  StoreProductsStyles.searchBarDecoration,
                              child: Row(
                                children: [
                                  StoreProductsStyles.hSpaceMedium,
                                  const Icon(
                                    StoreProductsStyles.searchIcon,
                                    color: StoreProductsStyles.lightGrayColor,
                                    size: StoreProductsStyles.iconSizeSmall,
                                  ),
                                  StoreProductsStyles.hSpaceSmall,
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: (value) {
                                        setState(() {
                                          _searchQuery = value;
                                          _filterProducts();
                                        });
                                      },
                                      decoration: StoreProductsStyles
                                          .searchInputDecoration,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          StoreProductsStyles.hSpaceMedium,
                          Container(
                            height: StoreProductsStyles.filterButtonSize,
                            width: StoreProductsStyles.filterButtonSize,
                            decoration:
                                StoreProductsStyles.filterIconDecoration,
                            child: IconButton(
                              icon: const Icon(
                                StoreProductsStyles.filterIcon,
                                color: StoreProductsStyles.whiteColor,
                                size: StoreProductsStyles.iconSizeSmall,
                              ),
                              onPressed: () => _showFilterBottomSheet(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _filteredProducts.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No products found',
                            style: StoreProductsStyles.noProductsFoundStyle,
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: StoreProductsStyles.screenPadding,
                        sliver: SliverGrid(
                          gridDelegate: StoreProductsStyles.productGridDelegate,
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            return _buildProductCard(_filteredProducts[index]);
                          }, childCount: _filteredProducts.length),
                        ),
                      ),
              ],
            ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    
    List<String> images = [];
    if (product['product_images'] != null) {
      if (product['product_images'] is String) {
        try {
          images = List<String>.from(jsonDecode(product['product_images']));
        } catch (e) {
          images = [];
        }
      } else if (product['product_images'] is List) {
        images = List<String>.from(product['product_images']);
      }
    }

    final String imageSource = images.isNotEmpty ? images.first : '';
    final String name = product['product_name'] ?? 'Product';
    final double rawPrice = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;

    // Promotion discount
    final discountRaw = product['promotion_discount'];
    final discount = discountRaw != null
        ? (discountRaw is num ? discountRaw.toDouble() : double.tryParse(discountRaw.toString()))
        : null;
    final hasDiscount = discount != null && discount > 0;
    final discountedPrice = hasDiscount ? rawPrice * (1 - discount / 100) : null;

    product['store_name'] = widget.storeName;
    product['product_images'] = images;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductDetailsScreen(product: product, userId: widget.userId),
          ),
        );
      },
      child: Container(
        decoration: StoreProductsStyles.productCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: StoreProductsStyles.cardTopRadius,
                      child: Container(
                        color: StoreProductsStyles.secondaryColor,
                        child: imageSource.isNotEmpty
                            ? (imageSource.startsWith('http')
                                  ? Image.network(
                                      imageSource,
                                      fit: StoreProductsStyles.imageFit,
                                    )
                                  : Image.memory(
                                      base64Decode(imageSource.split(',').last),
                                      fit: StoreProductsStyles.imageFit,
                                    ))
                            : const Icon(
                                StoreProductsStyles.errorIcon,
                                color: StoreProductsStyles.lightGrayColor,
                              ),
                      ),
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
                          '-${discount.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async => await _toggleWishlistItem(product),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: StoreProductsStyles.favoriteIconDecoration,
                        child: Icon(
                          product['is_favorited'] == 1 || product['is_favorited'] == true
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: StoreProductsStyles.primaryColor,
                          size: StoreProductsStyles.favoriteIconSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: StoreProductsStyles.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StoreProductsStyles.cardTitleStyle,
                  ),
                  StoreProductsStyles.vSpaceTiny,
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
                    Text('Rs ${rawPrice.toStringAsFixed(0)}', style: StoreProductsStyles.cardPriceStyle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickySearchDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => StoreProductsStyles.stickyHeaderHeight;

  @override
  double get minExtent => StoreProductsStyles.stickyHeaderHeight;

  @override
  bool shouldRebuild(covariant _StickySearchDelegate oldDelegate) {
    return false;
  }
}
