import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'cart_screen.dart';
import '../widgets/custom_snackbar.dart';
import '../styles/product_details_styles.dart';
import 'chat_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final int? userId;
  final Map<String, dynamic>? cartItem;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    this.userId,
    this.cartItem,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    bool isError = backgroundColor == ProductDetailsStyles.errorColor;
    CustomSnackBar.show(context, message, isError: isError);
  }

  int _selectedImageIndex = 0;
  String? _selectedSize;
  String? _selectedColor;
  List<String> _availableSizes = [];
  List<String> _availableColors = [];
  bool _isLoadingVariants = true;
  int _quantity = 1;
  int _stockQuantity = 0;
  List<Map<String, dynamic>> _variants = [];
  bool _isDescriptionExpanded = false;
  String _storeRating = '...';

  bool _hasCartItems = false;

  double _tryOnProgress = 0.0;

  List<dynamic> _reviews = [];
  bool _isLoadingReviews = true;
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _checkCartStatus();
    
    final stock = widget.product['stock_quantity'];
    _stockQuantity = stock is int ? stock : int.tryParse(stock.toString()) ?? 0;
    _fetchVariants();
    _fetchStoreRating();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    final productIdVal = widget.product['id'] ?? widget.product['product_id'];
    if (productIdVal == null) {
      if (mounted) setState(() => _isLoadingReviews = false);
      return;
    }

    final productId = productIdVal is int
        ? productIdVal
        : int.tryParse(productIdVal.toString()) ?? 0;

    try {
      final result = await ApiService.getProductReviews(productId);
      if (mounted) {
        setState(() {
          if (result['success']) {
            _reviews = result['data'] ?? [];
            if (_reviews.isNotEmpty) {
              double total = 0;
              for (var review in _reviews) {
                total += (review['rating'] ?? 0);
              }
              _averageRating = total / _reviews.length;
            }
          }
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _fetchStoreRating() async {
    final productIdVal = widget.product['id'] ?? widget.product['product_id'];
    if (productIdVal == null) return;

    final productId = productIdVal is int
        ? productIdVal
        : int.tryParse(productIdVal.toString()) ?? 0;

    try {
      final result = await ApiService.getStoreRating(productId);

      if (mounted) {
        if (result['success']) {
          setState(() {
            _storeRating = result['overall_rating']?.toString() ?? '0.0';
          });
        } else {
          setState(() {
            _storeRating = '0.0';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _storeRating = '0.0';
        });
      }
    }
  }

  Future<void> _fetchVariants() async {
    final productIdVal = widget.product['id'] ?? widget.product['product_id'];
    if (productIdVal == null) {
      setState(() => _isLoadingVariants = false);
      return;
    }

    final productId = productIdVal is int
        ? productIdVal
        : int.tryParse(productIdVal.toString()) ?? 0;

    final variants = widget.product['variants'] as List?;
    if (variants != null && variants.isNotEmpty) {
      _processVariants(List<Map<String, dynamic>>.from(variants));
      return;
    }

    try {
      final fetchedVariants = await ApiService.getProductVariants(productId);
      if (mounted) {
        _processVariants(fetchedVariants);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingVariants = false);
    }
  }

  List<String> _allSizes = [];
  List<String> _allColors = [];

  void _processVariants(List<Map<String, dynamic>> variants) {
    
    _variants = variants;

    final Set<String> allSizes = {};
    final Set<String> allColors = {};

    for (var variant in variants) {
      if (variant['size'] != null && variant['size'].toString().isNotEmpty) {
        allSizes.add(variant['size'].toString());
      }
      if (variant['color'] != null && variant['color'].toString().isNotEmpty) {
        allColors.add(variant['color'].toString());
      }
    }

    setState(() {
      _allSizes = allSizes.toList();
      _allColors = allColors.toList();
      _availableSizes = _allSizes;
      _availableColors = _allColors;

      if (widget.cartItem != null) {
        _selectedSize = widget.cartItem!['size'];
        _selectedColor = widget.cartItem!['color'];

        final qty = widget.cartItem!['quantity'];
        _quantity = qty is int ? qty : int.tryParse(qty.toString()) ?? 1;
      } else if (_allSizes.isNotEmpty) {
        _selectedSize = _allSizes.first;
        _ensureValidColorForSize(_selectedSize!);
      }

      _updateStockAndPrice();
      _isLoadingVariants = false;
    });
  }

  bool _isVariantAvailable(String? size, String? color) {
    if (size == null || color == null) return false;
    return _variants.any(
      (v) => v['size']?.toString() == size && v['color']?.toString() == color,
    );
  }

  void _ensureValidColorForSize(String size) {
    
    if (_selectedColor != null && _isVariantAvailable(size, _selectedColor)) {
      return;
    }
    
    for (var color in _allColors) {
      if (_isVariantAvailable(size, color)) {
        _selectedColor = color;
        return;
      }
    }
    _selectedColor = null;
  }

  void _onSizeSelected(String newSize) {
    setState(() {
      _selectedSize = newSize;
      _ensureValidColorForSize(newSize);
      _updateStockAndPrice();
    });
  }

  void _onColorSelected(String newColor) {
    setState(() {
      _selectedColor = newColor;
      _updateStockAndPrice();
    });
  }

  void _updateStockAndPrice() {
    final variant = _variants.firstWhere(
      (v) =>
          v['size']?.toString() == _selectedSize &&
          v['color']?.toString() == _selectedColor,
      orElse: () => {},
    );

    int newStock = 0;
    if (variant.isNotEmpty) {
      final stockVal = variant['stock_quantity'];
      newStock = stockVal is int
          ? stockVal
          : int.tryParse(stockVal.toString()) ?? 0;
    }

    setState(() {
      _stockQuantity = newStock;

      if (_quantity > _stockQuantity) {
        _quantity = _stockQuantity;
      }

      if (_stockQuantity > 0 && _quantity < 1) {
        _quantity = 1;
      }
    });
  }

  String _getCurrentPrice() {
    if (_variants.isEmpty) {
      return widget.product['price']?.toString() ?? '0';
    }

    final variant = _variants.firstWhere(
      (v) =>
          v['size']?.toString() == _selectedSize &&
          v['color']?.toString() == _selectedColor,
      orElse: () => {},
    );

    if (variant.isNotEmpty &&
        variant['price_per_variant'] != null &&
        variant['price_per_variant'] > 0) {
      return variant['price_per_variant'].toString();
    }

    return widget.product['price']?.toString() ?? '0';
  }

  Future<void> _onTryOnPressed() async {
    showDialog(
      context: context,
      builder: (context) => _buildTryOnIntroDialog(),
    );
  }

  Widget _buildTryOnIntroDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "How to use Virtual Try-On",
              style: ProductDetailsStyles.sectionHeaderStyle,
              textAlign: TextAlign.center,
            ),
            ProductDetailsStyles.sizedBoxHeight16,
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/vton_wrong.png',
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Incorrect',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/vton_correct.png',
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Correct',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ProductDetailsStyles.sizedBoxHeight16,
            const Text(
              "Please upload a clear, full-body image of yourself (not just your face) for the best results.",
              style: ProductDetailsStyles.descriptionStyle,
              textAlign: TextAlign.center,
            ),
            ProductDetailsStyles.sizedBoxHeight24,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ProductDetailsStyles.outlinedButtonStyle,
                    child: Text(
                      "Cancel",
                      style: ProductDetailsStyles.cancelButtonTextStyle,
                    ),
                  ),
                ),
                ProductDetailsStyles.sizedBoxWidth12,
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showImageSourceDialog();
                    },
                    style: ProductDetailsStyles.primaryButtonStyle,
                    child: const Text(
                      "Next",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Image Source",
              style: ProductDetailsStyles.sectionHeaderStyle,
            ),
            ProductDetailsStyles.sizedBoxHeight24,
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: ProductDetailsStyles.primaryColor,
              ),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickAndProcessImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: ProductDetailsStyles.primaryColor,
              ),
              title: const Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickAndProcessImage(ImageSource.camera);
              },
            ),
            ProductDetailsStyles.sizedBoxHeight12,
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() {
      _tryOnProgress = 0.0;
    });

    _showProgressDialog();

    try {
      final modelBytes = await pickedFile.readAsBytes();

      final images = widget.product['product_images'] as List? ?? [];
      if (images.isEmpty) {
        _handleTryOnFailure("No product images available.");
        return;
      }

      final clothImageUrl = images[_selectedImageIndex].toString();
      List<int> clothBytes;

      if (clothImageUrl.startsWith('http')) {
        final res = await http.get(Uri.parse(clothImageUrl));
        clothBytes = res.bodyBytes;
      } else if (clothImageUrl.startsWith('assets/')) {
        final data = await rootBundle.load(clothImageUrl);
        clothBytes = data.buffer.asUint8List();
      } else {
        clothBytes = base64Decode(clothImageUrl.split(',').last);
      }

      String clothType = _inferClothType();

      final result = await ApiService.createTryOnTask(
        modelImageBytes: modelBytes,
        clothImageBytes: clothBytes,
        clothType: clothType,
      );

      if (result['success']) {
        final taskId = result['task_id'];
        _pollTaskStatus(taskId);
      } else {
        _handleTryOnFailure(result['message'] ?? "Failed to initiate try-on.");
      }
    } catch (e) {
      _handleTryOnFailure(e.toString());
    }
  }

  String _inferClothType() {
    final category = (widget.product['category'] ?? '')
        .toString()
        .toLowerCase();
    if (category.contains('top') ||
        category.contains('shirt') ||
        category.contains('jacket'))
      return 'upper';
    if (category.contains('bottom') ||
        category.contains('pant') ||
        category.contains('skirt'))
      return 'lower';
    if (category.contains('dress') || category.contains('suit')) return 'full';
    if (category.contains('set')) return 'combo';
    return 'upper'; 
  }

  void _pollTaskStatus(String taskId) async {
    bool isCompleted = false;
    int retryCount = 0;
    const maxRetries = 60; 

    while (!isCompleted && retryCount < maxRetries && mounted) {
      await Future.delayed(const Duration(seconds: 2));
      retryCount++;

      final statusResult = await ApiService.getTryOnTaskStatus(taskId);

      if (statusResult['success']) {
        final status = statusResult['status'];
        final progress = (statusResult['progress'] ?? 0).toDouble();

        if (mounted) {
          setState(() {
            _tryOnProgress = progress / 100.0;
          });
        }

        if (status == 'COMPLETED') {
          isCompleted = true;
          if (mounted) {
            Navigator.pop(context); 
            _showResultDialog(statusResult['download_signed_url']);
          }
        } else if (status == 'FAILED') {
          isCompleted = true;
          _handleTryOnFailure(statusResult['error'] ?? "Try-on task failed.");
        }
      } else {
        isCompleted = true;
        _handleTryOnFailure(
          statusResult['message'] ?? "Failed to check task status.",
        );
      }
    }

    if (!isCompleted && mounted) {
      _handleTryOnFailure("Try-on timed out. Please try again later.");
    }
  }

  void _handleTryOnFailure(String message) {
    if (mounted) {
      if (Navigator.canPop(context))
        Navigator.pop(context); 
      _showSnackBar(message, ProductDetailsStyles.errorColor);
    }
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Creating Your Look...",
                    style: ProductDetailsStyles.sectionHeaderStyle,
                  ),
                  ProductDetailsStyles.sizedBoxHeight24,
                  CircularProgressIndicator(
                    value: _tryOnProgress > 0 ? _tryOnProgress : null,
                    color: ProductDetailsStyles.primaryColor,
                  ),
                  ProductDetailsStyles.sizedBoxHeight16,
                  Text(
                    "${(_tryOnProgress * 100).toInt()}%",
                    style: ProductDetailsStyles.ratingStyle,
                  ),
                  ProductDetailsStyles.sizedBoxHeight16,
                  const Text(
                    "Our AI is virtually fitting the clothes. This usually takes 10-20 seconds.",
                    style: ProductDetailsStyles.descriptionStyle,
                    textAlign: TextAlign.center,
                  ),
                  ProductDetailsStyles.sizedBoxHeight24,
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Cancel Process",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showResultDialog(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          color: ProductDetailsStyles.whiteColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Magic Try-On",
                      style: ProductDetailsStyles.sectionHeaderStyle,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: ProductDetailsStyles.lightGrayColor,
                      ),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            ProductDetailsStyles.beigeBackgroundColor,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: ProductDetailsStyles.beigeBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: ProductDetailsStyles.dividerColor,
                      width: 0.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        height: 350,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: ProductDetailsStyles.primaryColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "How do you look?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ProductDetailsStyles.darkTextColor,
                      ),
                    ),
                    ProductDetailsStyles.sizedBoxHeight20,
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ProductDetailsStyles.primaryButtonStyle.copyWith(
                        minimumSize: WidgetStateProperty.all(
                          const Size(double.infinity, 56),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      child: const Text(
                        "Looks Great!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final name =
        widget.product['product_name'] ?? widget.product['name'] ?? 'Product';
    final storeName = widget.product['store_name']?.toString() ?? 'Store';
    final description =
        widget.product['description'] ?? 'No description available.';
    final images = widget.product['product_images'] as List? ?? [];

    return Scaffold(
      backgroundColor: ProductDetailsStyles.whiteColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    _buildHeader(images),

                    Padding(
                      padding: ProductDetailsStyles.padding24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitleSection(name, storeName),
                          ProductDetailsStyles.sizedBoxHeight24,
                          _buildDetailsSection(description),
                          ProductDetailsStyles.sizedBoxHeight24,
                          if (!_isLoadingVariants &&
                              (_availableSizes.isNotEmpty ||
                                  _availableColors.isNotEmpty)) ...[
                            const Divider(
                              height: 1,
                              color: ProductDetailsStyles.dividerColor,
                            ),
                            ProductDetailsStyles.sizedBoxHeight24,
                            if (_availableSizes.isNotEmpty)
                              _buildSizeSelector(),
                            if (_availableSizes.isNotEmpty &&
                                _availableColors.isNotEmpty) ...[
                              ProductDetailsStyles.sizedBoxHeight24,
                              const Divider(
                                height: 1,
                                color: ProductDetailsStyles.dividerColor,
                              ),
                              ProductDetailsStyles.sizedBoxHeight24,
                            ],
                            if (_availableColors.isNotEmpty)
                              _buildColorSelector(),
                            ProductDetailsStyles.sizedBoxHeight24,
                          ],
                          const Divider(
                            height: 1,
                            color: ProductDetailsStyles.dividerColor,
                          ),
                          ProductDetailsStyles.sizedBoxHeight24,
                          _buildQuantitySelector(),
                          ProductDetailsStyles.sizedBoxHeight24,
                          const Divider(
                            height: 1,
                            color: ProductDetailsStyles.dividerColor,
                          ),
                          ProductDetailsStyles.sizedBoxHeight24,
                          _buildReviewsSection(),
                          ProductDetailsStyles.sizedBoxHeight70,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomBar(_getCurrentPrice()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(List images) {
    return Stack(
      children: [
        Container(
          height: 450,
          width: double.infinity,
          decoration: ProductDetailsStyles.mainImageContainerDecoration,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            child: images.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 100,
                      color: ProductDetailsStyles.lightGrayColor,
                    ),
                  )
                : _buildMainImage(images[_selectedImageIndex].toString()),
          ),
        ),

        Positioned(
          top: 20,
          left: 20,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: ProductDetailsStyles.primaryColor,
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: ProductDetailsStyles.transparentColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        Positioned(
          top: 20,
          right: 20,
          child: Column(
            children: [
              if (_hasCartItems) ...[
                _buildRoundButton(
                  icon: Icons.shopping_bag_outlined,
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
                  showBadge: true,
                ),
                ProductDetailsStyles.sizedBoxHeight12,
              ],
              _buildRoundButton(icon: Icons.favorite_border, onPressed: () {}),
              ProductDetailsStyles.sizedBoxHeight12,
              _buildRoundButton(
                icon: Icons.chat_bubble_outline,
                onPressed: () async {
                  if (widget.userId == null) {
                    _showSnackBar(
                      'Please log in to chat with the seller',
                      ProductDetailsStyles.errorColor,
                    );
                    return;
                  }

                  int? otherUserId;
                  String storeName =
                      widget.product['store_name']?.toString() ?? 'Seller';

                  String? storeLogo = widget.product['logo']?.toString();

                  final sellerIdVal = widget.product['seller_id'];
                  if (sellerIdVal != null) {
                    otherUserId = sellerIdVal is int
                        ? sellerIdVal
                        : int.tryParse(sellerIdVal.toString());
                  } else {
                    
                    final productIdVal =
                        widget.product['id'] ?? widget.product['product_id'];
                    if (productIdVal != null) {
                      final res = await ApiService.getProductById(
                        productIdVal.toString(),
                      );
                      if (res['success'] && res['data'] != null) {
                        final fetchedSellerId = res['data']['seller_id'];
                        if (fetchedSellerId != null) {
                          otherUserId = fetchedSellerId is int
                              ? fetchedSellerId
                              : int.tryParse(fetchedSellerId.toString());
                          storeName =
                              res['data']['store_name']?.toString() ??
                              storeName;
                          storeLogo =
                              res['data']['logo']?.toString() ??
                              storeLogo; 
                        }
                      }
                    }
                  }

                  if (otherUserId == null || otherUserId == 0) {
                    _showSnackBar(
                      'Seller information is currently unavailable',
                      ProductDetailsStyles.errorColor,
                    );
                    return;
                  }

                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        currentUserId: widget.userId!,
                        otherUserId: otherUserId!,
                        otherUserName: storeName,
                        storeLogo: storeLogo,
                      ),
                    ),
                  );
                },
              ),
              ProductDetailsStyles.sizedBoxHeight12,
              _buildRoundButton(
                icon: Icons.face_retouching_natural,
                onPressed: _onTryOnPressed,
              ),
            ],
          ),
        ),

        if (images.isNotEmpty)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 70,
              child: ListView.builder(
                padding: ProductDetailsStyles.paddingSymmetricHorizontal20,
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return _buildThumbnail(images[index].toString(), index);
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainImage(String source) {
    if (source.startsWith('assets/')) {
      return Image.asset(source, fit: BoxFit.cover);
    } else if (source.startsWith('http')) {
      return Image.network(source, fit: BoxFit.cover);
    } else {
      return Image.memory(
        base64Decode(source.split(',').last),
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildThumbnail(String source, int index) {
    bool isSelected = _selectedImageIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedImageIndex = index),
      child: Container(
        width: 70,
        margin: ProductDetailsStyles.paddingOnlyRight12,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ProductDetailsStyles.primaryColor
                : ProductDetailsStyles.whiteColor,
            width: 2,
          ),
          color: ProductDetailsStyles.whiteColor,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _buildMainImage(source),
        ),
      ),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool showBadge = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: ProductDetailsStyles.roundButtonDecoration,
          child: IconButton(
            icon: Icon(
              icon,
              color: ProductDetailsStyles.primaryColor,
              size: 20,
            ),
            onPressed: onPressed,
          ),
        ),
        if (showBadge)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: ProductDetailsStyles.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitleSection(String name, String storeName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(storeName, style: ProductDetailsStyles.storeNameStyle),
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: ProductDetailsStyles.starColor,
                  size: 18,
                ),
                ProductDetailsStyles.sizedBoxWidth4,
                Text(_storeRating, style: ProductDetailsStyles.ratingStyle),
              ],
            ),
          ],
        ),
        ProductDetailsStyles.sizedBoxHeight8,
        Text(name, style: ProductDetailsStyles.productTitleStyle),
      ],
    );
  }

  Widget _buildDetailsSection(String description) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final TextSpan span = TextSpan(
          text: description,
          style: ProductDetailsStyles.descriptionStyle,
        );
        final TextPainter tp = TextPainter(
          text: span,
          maxLines: 3,
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: constraints.maxWidth);
        final bool isLongDescription = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Product Details",
              style: ProductDetailsStyles.sectionHeaderStyle,
            ),
            ProductDetailsStyles.sizedBoxHeight12,
            Text(
              description,
              maxLines: _isDescriptionExpanded ? null : 3,
              overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
              style: ProductDetailsStyles.descriptionStyle,
            ),
            if (isLongDescription)
              GestureDetector(
                onTap: () => setState(
                  () => _isDescriptionExpanded = !_isDescriptionExpanded,
                ),
                child: Padding(
                  padding: ProductDetailsStyles.paddingOnlyTop8,
                  child: Text(
                    _isDescriptionExpanded ? "Read less" : "Read more",
                    style: ProductDetailsStyles.readMoreStyle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Size",
          style: ProductDetailsStyles.selectorHeaderStyle,
        ),
        ProductDetailsStyles.sizedBoxHeight12,
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _availableSizes.map((size) {
            final isSelected = _selectedSize == size;

            return GestureDetector(
              onTap: () => _onSizeSelected(size),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ProductDetailsStyles.primaryColor
                      : ProductDetailsStyles.whiteColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? ProductDetailsStyles.primaryColor
                        : ProductDetailsStyles.greyBorderColor,
                  ),
                ),
                child: Text(
                  size,
                  style: TextStyle(
                    color: isSelected
                        ? ProductDetailsStyles.whiteColor
                        : ProductDetailsStyles.darkTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Select Color",
              style: ProductDetailsStyles.selectorHeaderStyle,
            ),
            if (_selectedColor != null) ...[
              const Text(
                " : ",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ProductDetailsStyles.darkTextColor,
                ),
              ),
              Text(_selectedColor!, style: ProductDetailsStyles.colorNameStyle),
            ],
          ],
        ),
        ProductDetailsStyles.sizedBoxHeight12,
        Wrap(
          spacing: 12,
          children: _availableColors.map((colorName) {
            final isSelected = _selectedColor == colorName;
            final isCompatible =
                _selectedSize == null ||
                _isVariantAvailable(_selectedSize, colorName);

            Color displayColor;
            switch (colorName.toLowerCase()) {
              case 'black':
                displayColor = Colors.black;
                break;
              case 'white':
                displayColor = ProductDetailsStyles.whiteColor;
                break;
              case 'red':
                displayColor = Colors.red;
                break;
              case 'blue':
                displayColor = Colors.blue;
                break;
              case 'green':
                displayColor = Colors.green;
                break;
              case 'brown':
                displayColor = ProductDetailsStyles.primaryColor;
                break;
              case 'yellow':
                displayColor = Colors.yellow;
                break;
              case 'pink':
                displayColor = Colors.pink;
                break;
              case 'purple':
                displayColor = Colors.purple;
                break;
              case 'orange':
                displayColor = Colors.orange;
                break;
              default:
                displayColor = Colors.grey;
            }

            return GestureDetector(
              onTap: isCompatible ? () => _onColorSelected(colorName) : null,
              child: Opacity(
                opacity: isCompatible ? 1.0 : 0.3,
                child: Container(
                  padding: ProductDetailsStyles.paddingAll4,
                  decoration: ProductDetailsStyles.colorOptionOuterDecoration(
                    isSelected,
                  ),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: ProductDetailsStyles.colorOptionInnerDecoration(
                      displayColor,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quantity",
              style: ProductDetailsStyles.quantityTextStyle,
            ),
            if (_stockQuantity > 0)
              Text(
                'Max: $_stockQuantity',
                style: ProductDetailsStyles.maxQuantityStyle,
              ),
          ],
        ),
        const Spacer(),
        _buildQtyButton(Icons.remove, () {
          if (_quantity > 1) {
            setState(() {
              _quantity--;
            });
          }
        }),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text(
            '$_quantity',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ProductDetailsStyles.darkTextColor,
            ),
          ),
        ),
        _buildQtyButton(Icons.add, () {
          if (_quantity < _stockQuantity) {
            setState(() {
              _quantity++;
            });
          } else {
            _showSnackBar(
              'Max stock quantity reached',
              ProductDetailsStyles.errorColor,
            );
          }
        }, isAdd: true),
      ],
    );
  }

  Widget _buildQtyButton(
    IconData icon,
    VoidCallback onTap, {
    bool isAdd = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isAdd
              ? ProductDetailsStyles.primaryColor
              : ProductDetailsStyles.whiteColor,
          borderRadius: BorderRadius.circular(8),
          border: isAdd
              ? null
              : Border.all(color: ProductDetailsStyles.greyBorderColor),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isAdd
              ? ProductDetailsStyles.whiteColor
              : ProductDetailsStyles.darkTextColor,
        ),
      ),
    );
  }

  Widget _buildBottomBar(String price) {
    return Container(
      padding: ProductDetailsStyles.paddingSymmetricHorizontal24Vertical12,
      decoration: ProductDetailsStyles.bottomBarDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Price",
                style: ProductDetailsStyles.totalPriceLabelStyle,
              ),
              ProductDetailsStyles.sizedBoxHeight4,
              Text(
                "Rs $price",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ProductDetailsStyles.darkTextColor,
                ),
              ),
            ],
          ),

          if (widget.cartItem != null)
            Row(
              children: [
                
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ProductDetailsStyles.outlinedButtonStyle,
                  child: Text(
                    "Cancel",
                    style: ProductDetailsStyles.cancelButtonTextStyle,
                  ),
                ),
                ProductDetailsStyles.sizedBoxWidth12,
                
                ElevatedButton(
                  onPressed: () async {
                    if (widget.userId == null) return;

                    final cartItemId = widget.cartItem!['cartItemId'];
                    final id = cartItemId is int
                        ? cartItemId
                        : int.tryParse(cartItemId.toString()) ?? 0;

                    final result = await ApiService.updateCartItem(
                      cartItemId: id,
                      quantity: _quantity,
                      size: _selectedSize,
                      color: _selectedColor,
                    );

                    if (mounted) {
                      if (result['success']) {
                        Navigator.pop(context, true);
                      } else {
                        _showSnackBar(
                          result['message'] ?? 'Failed to update item',
                          ProductDetailsStyles.errorColor,
                        );
                      }
                    }
                  },
                  style: ProductDetailsStyles.primaryButtonStyle,
                  child: Text(
                    "Update",
                    style: ProductDetailsStyles.updateButtonTextStyle,
                  ),
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: () async {
                if (widget.userId == null) {
                  _showSnackBar(
                    'Please log in to add items to cart',
                    ProductDetailsStyles.errorColor,
                  );
                  return;
                }

                final productIdVal =
                    widget.product['id'] ?? widget.product['product_id'];
                if (productIdVal == null) return;

                final productId = productIdVal is int
                    ? productIdVal
                    : int.tryParse(productIdVal.toString()) ?? 0;

                final result = await ApiService.addToCart(
                  userId: widget.userId!,
                  productId: productId,
                  quantity: _quantity,
                  size: _selectedSize ?? 'N/A',
                  color: _selectedColor ?? 'N/A',
                );

                if (mounted) {
                  if (result['success']) {
                    _checkCartStatus();
                  } else {
                    _showSnackBar(
                      result['message'] ?? 'Failed to add to cart',
                      ProductDetailsStyles.errorColor,
                    );
                  }
                }
              },
              style: ProductDetailsStyles.primaryButtonStyle,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    color: ProductDetailsStyles.whiteColor,
                    size: 20,
                  ),
                  ProductDetailsStyles.sizedBoxWidth8,
                  Text(
                    "Add to Cart",
                    style: ProductDetailsStyles.addToCartButtonStyle,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    if (_isLoadingReviews) {
      return const Center(
        child: CircularProgressIndicator(
          color: ProductDetailsStyles.primaryColor,
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Reviews", style: ProductDetailsStyles.sectionHeaderStyle),
          ProductDetailsStyles.sizedBoxHeight12,
          const Text(
            "No reviews yet. Be the first to review this product!",
            style: ProductDetailsStyles.descriptionStyle,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Reviews",
              style: ProductDetailsStyles.sectionHeaderStyle,
            ),
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: ProductDetailsStyles.starColor,
                  size: 20,
                ),
                ProductDetailsStyles.sizedBoxWidth4,
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ProductDetailsStyles.darkTextColor,
                  ),
                ),
                Text(
                  " (${_reviews.length})",
                  style: const TextStyle(
                    fontSize: 14,
                    color: ProductDetailsStyles.lightGrayColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        ProductDetailsStyles.sizedBoxHeight16,
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _reviews.length,
          itemBuilder: (context, index) {
            final review = _reviews[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ProductDetailsStyles.beigeBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ProductDetailsStyles.greyBorderColor.withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        review['customer_name'] ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: ProductDetailsStyles.darkTextColor,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < (review['rating'] ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            color: ProductDetailsStyles.starColor,
                            size: 16,
                          );
                        }),
                      ),
                    ],
                  ),
                  if (review['comment'] != null &&
                      review['comment'].toString().isNotEmpty) ...[
                    ProductDetailsStyles.sizedBoxHeight8,
                    Text(
                      review['comment'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: ProductDetailsStyles.darkTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
