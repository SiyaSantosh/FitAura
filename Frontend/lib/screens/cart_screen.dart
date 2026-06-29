import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'checkout_screen.dart';
import 'product_details_screen.dart';
import '../widgets/custom_snackbar.dart';
import '../styles/cart_styles.dart';

class CartScreen extends StatefulWidget {
  final int userId;

  const CartScreen({super.key, required this.userId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  double _subTotal = 0.0;
  final double _platformFee = 10.0;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getCartItems(widget.userId);
      if (result['success']) {
        setState(() {
          _cartItems = List<Map<String, dynamic>>.from(result['data']);
          _calculateTotals();
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load cart items';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateTotals() {
    double tempSubTotal = 0.0;
    for (var item in _cartItems) {
      double pricePerVariant = double.tryParse(item['price_per_variant']?.toString() ?? '0') ?? 0.0;
      double basePrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
      double price = (pricePerVariant > 0) ? pricePerVariant : basePrice;
      
      final discountRaw = item['promotion_discount'];
      final discount = discountRaw != null
          ? (discountRaw is num ? discountRaw.toDouble() : double.tryParse(discountRaw.toString()))
          : null;
      if (discount != null && discount > 0) {
        price = price * (1 - discount / 100);
      }
      
      int quantity = item['quantity'] is int ? item['quantity'] : int.tryParse(item['quantity'].toString()) ?? 1;
      tempSubTotal += price * quantity;
    }
    setState(() {
      _subTotal = tempSubTotal;
    });
  }

  Future<void> _updateQuantity(int index, int change) async {
    final item = _cartItems[index];
    final cartItemId = item['cartItemId'];
    final int currentQty = item['quantity'] is int ? item['quantity'] : int.tryParse(item['quantity'].toString()) ?? 1;
    final int newQty = currentQty + change;

    if (newQty < 1) return;
    if (cartItemId == null) return;

    final stockQuantity = item['stock_quantity'] is int 
        ? item['stock_quantity'] 
        : int.tryParse(item['stock_quantity']?.toString() ?? '0') ?? 0;
    
    if (change > 0 && newQty > stockQuantity) {
      _showSnackBar('Only $stockQuantity items left in stock', CartStyles.errorColor);
      return;
    }

    setState(() {
      _cartItems[index]['quantity'] = newQty;
      _calculateTotals();
    });

    try {
      final int id = cartItemId is int ? cartItemId : int.tryParse(cartItemId.toString()) ?? 0;
      final result = await ApiService.updateCartItemQuantity(id, newQty);

      if (!result['success']) {
        
        _showSnackBar(result['message'] ?? 'Failed to update quantity', CartStyles.errorColor);
        setState(() {
          _cartItems[index]['quantity'] = currentQty;
          _calculateTotals();
        });
      }
    } catch (e) {
      _showSnackBar('Error updating quantity', CartStyles.errorColor);
      setState(() {
        _cartItems[index]['quantity'] = currentQty;
        _calculateTotals();
      });
    }
  }

  Future<void> _removeItem(int index) async {
      final item = _cartItems[index];
      
      final cartItemId = item['cartItemId']; 
      
      setState(() {
          _cartItems.removeAt(index);
          _calculateTotals();
      });

      if (cartItemId == null) {
          _showSnackBar('Error: Invalid item ID', CartStyles.errorColor);
          
          setState(() {
             _cartItems.insert(index, item);
             _calculateTotals();
          });
          return;
      }

      try {
        
        final int id = cartItemId is int ? cartItemId : int.tryParse(cartItemId.toString()) ?? 0;
        
        final result = await ApiService.deleteCartItem(id);
        
        if (result['success']) {
             
        } else {
             
             _showSnackBar(result['message'] ?? 'Failed to remove item', CartStyles.errorColor);
             setState(() {
                 _cartItems.insert(index, item);
                 _calculateTotals();
             });
        }
      } catch (e) {
         _showSnackBar('An error occurred while removing item', CartStyles.errorColor);
         setState(() {
             _cartItems.insert(index, item);
             _calculateTotals();
         });
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CartStyles.whiteColor,
      appBar: AppBar(
        backgroundColor: CartStyles.whiteColor,
        surfaceTintColor: CartStyles.transparentColor, 
        scrolledUnderElevation: 0, 
        elevation: 0,
        automaticallyImplyLeading: false, 
        leading: Padding(
          padding: CartStyles.paddingOnlyLeft8Top4,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: CartStyles.primaryColor, size: CartStyles.backIconSize),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'My Cart',
          style: CartStyles.appBarTitleStyle,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: CartStyles.primaryColor))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _cartItems.isEmpty
                  ? const Center(child: Text('Your cart is empty'))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: CartStyles.paddingAll20,
                            itemCount: _cartItems.length,
                            separatorBuilder: (context, index) => const Divider(height: CartStyles.separatorHeight30),
                            itemBuilder: (context, index) {
                              final item = _cartItems[index];
                              return _buildCartItem(item, index);
                            },
                          ),
                        ),
                        _buildBottomSection(),
                      ],
                    ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    final images = item['product_images'] as List<dynamic>?;
    final imageSource = (images != null && images.isNotEmpty) ? images.first.toString() : '';
    final name = item['product_name'] ?? 'Unknown product';
    final size = item['size'] ?? 'M';
    final color = item['color'] ?? 'N/A';
    final double pricePerVariant = double.tryParse(item['price_per_variant']?.toString() ?? '0') ?? 0.0;
    final double basePrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final double displayPrice = (pricePerVariant > 0) ? pricePerVariant : basePrice;
    
    final discountRaw = item['promotion_discount'];
    final discount = discountRaw != null
        ? (discountRaw is num ? discountRaw.toDouble() : double.tryParse(discountRaw.toString()))
        : null;
    final hasDiscount = discount != null && discount > 0;
    final double discountedPrice = hasDiscount ? displayPrice * (1 - discount / 100) : displayPrice;
    
    final quantity = item['quantity'] ?? 1;

    return Dismissible(
      key: Key(item['cartItemId'].toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _removeItem(index);
      },
      background: Container(
        padding: CartStyles.paddingDismissibleRight20,
        alignment: Alignment.centerRight,
        color: CartStyles.dismissibleBgColor,
        child: Container(
             padding: CartStyles.paddingIconAll10,
             decoration: CartStyles.dismissibleIconDecoration,
             child: const Icon(Icons.delete_outline, color: CartStyles.whiteColor, size: CartStyles.dismissibleIconSize),
        ),
      ),
      child: InkWell(
        onTap: () async {
            final productMap = {
                'id': item['productId'],
                'product_id': item['productId'],
                'product_name': item['product_name'],
                'price': item['price'],
                'product_images': item['product_images'],
                'store_name': item['store_name'],
                'description': '', 
                'promotion_discount': item['promotion_discount'],
            };

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(
                    product: productMap,
                    userId: widget.userId,
                    cartItem: item, 
                ),
              ),
            );
            _fetchCartItems(); 
        },
        child: Row(
          children: [
            
            ClipRRect(
              borderRadius: BorderRadius.circular(CartStyles.borderRadiusMedium),
              child: Container(
                width: CartStyles.productImageSize,
                height: CartStyles.productImageSize,
                decoration: CartStyles.productImageDecoration,
                child: (imageSource.isNotEmpty)
                    ? (imageSource.startsWith('http')
                        ? Image.network(imageSource, fit: BoxFit.cover)
                        : Image.memory(base64Decode(imageSource.split(',').last), fit: BoxFit.cover))
                    : const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
            CartStyles.sizedBoxWidth16,
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: CartStyles.productNameStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  CartStyles.sizedBoxHeight4,
                  Text(
                    'Size: $size',
                    style: CartStyles.productAttributeStyle,
                  ),
                  Text(
                    'Color: $color',
                    style: CartStyles.productAttributeStyle,
                  ),
                  CartStyles.sizedBoxHeight8,
                  if (hasDiscount)
                    Row(
                      children: [
                        Text(
                          'Rs ${displayPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Rs ${discountedPrice.toStringAsFixed(0)}',
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
                      'Rs ${displayPrice.toStringAsFixed(0)}',
                      style: CartStyles.productPriceStyle,
                    ),
                ],
              ),
            ),
            
            Row(
              children: [
                _buildQtyButton(Icons.remove, () => _updateQuantity(index, -1)),
                SizedBox(
                    width: CartStyles.quantityValueWidth30,
                    child: Text(
                        '$quantity',
                        textAlign: TextAlign.center,
                        style: CartStyles.quantityTextStyle
                    )
                ),
                _buildQtyButton(
                  Icons.add, 
                  () => _updateQuantity(index, 1), 
                  isAdd: true,
                  isDisabled: quantity >= (item['stock_quantity'] is int 
                                  ? item['stock_quantity'] 
                                  : int.tryParse(item['stock_quantity']?.toString() ?? '0') ?? 0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap, {bool isAdd = false, bool isDisabled = false}) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: CartStyles.paddingQuantityButton,
        decoration: CartStyles.quantityButtonDecoration(isAdd: isAdd, isDisabled: isDisabled),
        child: Icon(
          icon,
          size: CartStyles.quantityIconSize,
          color: isDisabled ? Colors.grey.shade500 : (isAdd ? CartStyles.whiteColor : Colors.black),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: CartStyles.paddingAll24,
      decoration: CartStyles.bottomSectionDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CartStyles.sizedBoxHeight24,
          
          _buildSummaryRow('Sub-Total', _subTotal),
          CartStyles.sizedBoxHeight12,
          _buildSummaryRow('Platform Fee', _platformFee),
          CartStyles.sizedBoxHeight12,
          const Divider(),
          CartStyles.sizedBoxHeight12,
          _buildSummaryRow('Total Cost', _subTotal + _platformFee, isTotal: true),
          CartStyles.sizedBoxHeight24,
          
          SizedBox(
            width: double.infinity,
            height: CartStyles.checkoutButtonHeight,
            child: ElevatedButton(
              onPressed: () {
                if (_cartItems.isEmpty) {
                  _showSnackBar('Your cart is empty', CartStyles.errorColor);
                  return;
                }

                final Map<String, int> variantQuantities = {};
                for (var item in _cartItems) {
                  final productId = item['productId']?.toString() ?? item['product_id']?.toString() ?? 'unknown_p';
                  final size = item['size'] ?? 'M';
                  final color = item['color'] ?? 'N/A';
                  final key = '${productId}_${size}_$color';

                  final int qty = item['quantity'] is int 
                      ? item['quantity'] 
                      : int.tryParse(item['quantity'].toString()) ?? 1;

                  variantQuantities[key] = (variantQuantities[key] ?? 0) + qty;
                }

                for (var item in _cartItems) {
                   final productId = item['productId']?.toString() ?? item['product_id']?.toString() ?? 'unknown_p';
                   final size = item['size'] ?? 'M';
                   final color = item['color'] ?? 'N/A';
                   final key = '${productId}_${size}_$color';
                   
                   final totalRequested = variantQuantities[key] ?? 0;
                   
                   final int stockQuantity = item['stock_quantity'] is int 
                        ? item['stock_quantity'] 
                        : int.tryParse(item['stock_quantity']?.toString() ?? '0') ?? 0;

                   if (totalRequested > stockQuantity) {
                     final productName = item['product_name'] ?? 'Item';
                     _showSnackBar('$productName ($size, $color): Stock not available', CartStyles.errorColor);
                     return; 
                   }
                }
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(
                      userId: widget.userId,
                      cartItems: _cartItems,
                      subTotal: _subTotal,
                      platformFee: _platformFee,
                    ),
                  ),
                ).then((_) => _fetchCartItems()); 
              },
              style: CartStyles.checkoutButtonStyle,
              child: const Text(
                'Proceed to Checkout',
                style: CartStyles.checkoutButtonTextStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal ? CartStyles.summaryTotalLabelStyle : CartStyles.summaryLabelStyle,
        ),
        Text(
          'Rs ${amount.toStringAsFixed(2)}',
          style: isTotal ? CartStyles.summaryTotalValueStyle : CartStyles.summaryValueStyle,
        ),
      ],
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    bool isError = backgroundColor == CartStyles.errorColor || 
                  backgroundColor == Colors.redAccent || 
                  backgroundColor == const Color(0xFFE53935);
    CustomSnackBar.show(context, message, isError: isError);
  }
}
