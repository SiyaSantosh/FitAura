import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';

import 'order_success_screen.dart';
import '../widgets/custom_snackbar.dart';
import '../styles/checkout_styles.dart';

class CheckoutScreen extends StatefulWidget {
  final int userId;
  final List<dynamic> cartItems;
  final double subTotal;
  final double platformFee;

  const CheckoutScreen({
    super.key,
    required this.userId,
    required this.cartItems,
    required this.subTotal,
    required this.platformFee,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _shippingType = 'Economy';
  String _paymentMethod = 'Cash On Delivery';
  String? _address;
  String? _contactNumber;
  String? _userName;
  bool _isLoading = true;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final result = await ApiService.getUserById(widget.userId);
      if (mounted && result['success']) {
        final data = result['data'];
        setState(() {
          _userName = data['name'];
          _address = data['address'] ?? 'No address provided';
          _addressController.text = _address!;
          _contactNumber = data['contact_number'] ?? '';
          _contactNumberController.text = _contactNumber!;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  String _getArrivalDate(bool isEconomy) {
    final now = DateTime.now();
    final arrivalDate = now.add(Duration(days: isEconomy ? 7 : 3));
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return "${arrivalDate.day} ${months[arrivalDate.month - 1]} ${arrivalDate.year}";
  }

  double get _shippingFee => _shippingType == 'Economy' ? 100.0 : 250.0;
  double get _totalCost => widget.subTotal + _shippingFee + widget.platformFee;

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    bool isError = backgroundColor == CheckoutStyles.errorColor || 
                  backgroundColor == Colors.redAccent || 
                  backgroundColor == const Color(0xFFE53935);
    CustomSnackBar.show(context, message, isError: isError);
  }

  Future<void> _placeOrder() async {
    
    if (_contactNumber == null || _contactNumber!.isEmpty) {
      _showSnackBar('Please provide a contact number', CheckoutStyles.errorColor);
      return;
    }
    
    if (_contactNumber!.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(_contactNumber!)) {
      _showSnackBar('Contact number must be exactly 11 digits', CheckoutStyles.errorColor);
      return;
    }

    setState(() => _isLoading = true);

    final List<Map<String, dynamic>> items = widget.cartItems.map((item) {
      final double pricePerVariant = double.tryParse(item['price_per_variant']?.toString() ?? '0') ?? 0.0;
      final double basePrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
      final double itemPrice = (pricePerVariant > 0) ? pricePerVariant : basePrice;

      return {
        'product_id': item['productId'],
        'variant_id': item['variant_id'],
        'product_name': item['product_name'],
        'price': itemPrice,
        'quantity': item['quantity'],
        'size': item['size'],
        'color': item['color'],
      };
    }).toList();

    final result = await ApiService.placeOrder(
      customer_id: widget.userId,
      shipping_address: _address ?? 'N/A',
      contact_number: _contactNumber!,
      shipping_type: _shippingType.toLowerCase(),
      payment_method: _paymentMethod,
      total_price: _totalCost,
      items: items,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(userId: widget.userId),
          ),
          (route) => false,
        );
      } else {
        _showSnackBar(result['message'] ?? 'Failed to place order', CheckoutStyles.errorColor);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CheckoutStyles.whiteColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(CheckoutStyles.shelfIndicatorHeight),
        child: SafeArea(
          child: Padding(
            padding: CheckoutStyles.paddingSymmetricHorizontal20Vertical10,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: CheckoutStyles.primaryColor, size: CheckoutStyles.backIconSize),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Text(
                  'Checkout',
                  style: CheckoutStyles.appBarTitleStyle,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading && _address == null
          ? const Center(child: CircularProgressIndicator(color: CheckoutStyles.primaryColor))
          : SingleChildScrollView(
              padding: CheckoutStyles.paddingAll24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   
                  _sectionHeader("Shipping Address"),
                  CheckoutStyles.sizedBoxHeight16,
                  _buildAddressCard(),
                  CheckoutStyles.sizedBoxHeight32,

                  _sectionHeader("Contact Number"),
                  CheckoutStyles.sizedBoxHeight16,
                  _buildContactNumberCard(),
                  CheckoutStyles.sizedBoxHeight32,

                  _sectionHeader("Choose Shipping Type"),
                  CheckoutStyles.sizedBoxHeight16,
                  _buildShippingTypeCard(),
                  CheckoutStyles.sizedBoxHeight32,

                  _sectionHeader("Payment Method"),
                  CheckoutStyles.sizedBoxHeight16,
                  _buildPaymentMethodCard(),
                  CheckoutStyles.sizedBoxHeight32,

                  _sectionHeader("Order List"),
                  CheckoutStyles.sizedBoxHeight16,
                  
                  ..._groupItemsByStore(widget.cartItems).map((storeGroup) {
                    final storeName = storeGroup['storeName'];
                    final items = storeGroup['items'] as List<dynamic>;
                    final storeTotal = _calculateStoreTotal(items);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        Container(
                          padding: CheckoutStyles.paddingStoreHeader,
                          decoration: CheckoutStyles.storeHeaderDecoration,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.store, color: CheckoutStyles.primaryColor, size: CheckoutStyles.storeIconSize),
                              CheckoutStyles.sizedBoxWidth8,
                              Text(
                                storeName,
                                style: CheckoutStyles.storeHeaderStyle,
                              ),
                            ],
                          ),
                        ),
                        CheckoutStyles.sizedBoxHeight12,

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            return _buildOrderItem(items[index]);
                          },
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "$storeName Total:",
                                style: CheckoutStyles.storeTotalLabelStyle,
                              ),
                              Text(
                                "Rs ${storeTotal.toStringAsFixed(2)}",
                                style: CheckoutStyles.storeTotalValueStyle,
                              ),
                            ],
                          ),
                        ),
                        const Divider(thickness: 1, color: CheckoutStyles.dividerColor),
                        CheckoutStyles.sizedBoxHeight16,
                      ],
                    );
                  }).toList(),
                  CheckoutStyles.sizedBoxHeight32, 
                ],
              ),
            ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: CheckoutStyles.sectionHeaderStyle,
    );
  }

  Widget _buildAddressCard() {
    return Row(
      children: [
        Container(
          padding: CheckoutStyles.paddingAll12,
          decoration: CheckoutStyles.iconContainerDecoration,
          child: const Icon(Icons.location_on_outlined, color: CheckoutStyles.primaryColor, size: CheckoutStyles.cardIconSize),
        ),
        CheckoutStyles.sizedBoxWidth16,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Home",
                style: CheckoutStyles.cardTitleStyle,
              ),
              CheckoutStyles.sizedBoxHeight4,
              Text(
                _address ?? "Loading address...",
                style: CheckoutStyles.cardSubtitleStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _showAddressEditDialog,
          child: const Text(
            "CHANGE",
            style: CheckoutStyles.changeButtonStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildShippingTypeCard() {
    return Row(
      children: [
        Container(
          padding: CheckoutStyles.paddingAll12,
          decoration: CheckoutStyles.iconContainerDecoration,
          child: const Icon(Icons.inventory_2_outlined, color: CheckoutStyles.primaryColor, size: CheckoutStyles.cardIconSize),
        ),
        CheckoutStyles.sizedBoxWidth16,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _shippingType,
                style: CheckoutStyles.cardTitleStyle,
              ),
              CheckoutStyles.sizedBoxHeight4,
              Text(
                "Estimated Arrival ${_getArrivalDate(_shippingType == 'Economy')}",
                style: CheckoutStyles.cardSubtitleStyle,
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _showShippingTypeSelector,
          child: const Text(
            "CHANGE",
            style: CheckoutStyles.changeButtonStyle,
          ),
        ),
      ],
    );
  }

  void _showShippingTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CheckoutStyles.whiteColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: CheckoutStyles.paddingAll24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Shipping Type",
                style: CheckoutStyles.dialogTitleStyle,
              ),
              CheckoutStyles.sizedBoxHeight24,
              _buildShippingOption("Economy", "Rs 100.0", "5-7 business days"),
              CheckoutStyles.sizedBoxHeight12,
              _buildShippingOption("Regular", "Rs 250.0", "2-3 business days"),
            ],
          ),
        );
      },
    );
  }

  void _showAddressEditDialog() {
    String? localError;
    showModalBottomSheet(
      context: context,
      backgroundColor: CheckoutStyles.whiteColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Update Shipping Address",
                    style: CheckoutStyles.dialogTitleStyle,
                  ),
                  CheckoutStyles.sizedBoxHeight24,
                  TextField(
                    controller: _addressController,
                    maxLines: 3,
                    onChanged: (val) {
                      if (localError != null) {
                        setModalState(() => localError = null);
                      }
                    },
                    decoration: CheckoutStyles.textFieldDecoration(
                      "Enter full address...",
                      errorText: localError,
                    ),
                  ),
                  CheckoutStyles.sizedBoxHeight24,
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final input = _addressController.text.trim();
                        final error = _validateAddressString(input);
                        if (error == null) {
                          setState(() {
                            _address = input;
                          });
                          Navigator.pop(context);
                        } else {
                          setModalState(() => localError = error);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CheckoutStyles.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text("Save Address", style: TextStyle(color: CheckoutStyles.whiteColor, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  CheckoutStyles.sizedBoxHeight24,
                ],
              ),
            );
          },
        );
      },
    );
  }

  String? _validateAddressString(String value) {
    if (value.isEmpty) {
      return 'Please enter an address';
    }
    if (value.length < 10) {
      return 'Address is too short (min 10 characters)';
    }
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    
    if (!hasLetter) {
      return 'Address must contain letters';
    }
    if (!hasNumber) {
      return 'Address must contain numbers (house/flat/etc.)';
    }
    return null;
  }

  String? _validateContactNumber(String value) {
    if (value.isEmpty) {
      return 'Please enter a contact number';
    }
    if (value.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Must be exactly 11 digits';
    }
    return null;
  }

  void _showContactEditDialog() {
    String? localError;
    _contactNumberController.text = _contactNumber ?? '';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: CheckoutStyles.whiteColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Update Contact Number",
                    style: CheckoutStyles.dialogTitleStyle,
                  ),
                  CheckoutStyles.sizedBoxHeight24,
                  TextField(
                    controller: _contactNumberController,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    onChanged: (val) {
                      if (localError != null) {
                        setModalState(() => localError = null);
                      }
                    },
                    decoration: CheckoutStyles.textFieldDecoration(
                      "Enter 11-digit mobile number",
                      errorText: localError,
                    ),
                  ),
                  CheckoutStyles.sizedBoxHeight24,
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final input = _contactNumberController.text.trim();
                        final error = _validateContactNumber(input);
                        if (error == null) {
                          setState(() {
                            _contactNumber = input;
                          });
                          Navigator.pop(context);
                        } else {
                          setModalState(() => localError = error);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CheckoutStyles.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text("Save Number", style: TextStyle(color: CheckoutStyles.whiteColor, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  CheckoutStyles.sizedBoxHeight24,
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContactNumberCard() {
    return Row(
      children: [
        Container(
          padding: CheckoutStyles.paddingAll12,
          decoration: CheckoutStyles.iconContainerDecoration,
          child: const Icon(Icons.phone_outlined, color: CheckoutStyles.primaryColor, size: CheckoutStyles.cardIconSize),
        ),
        CheckoutStyles.sizedBoxWidth16,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Contact Number",
                style: CheckoutStyles.cardTitleStyle,
              ),
              CheckoutStyles.sizedBoxHeight4,
              Text(
                _contactNumber != null && _contactNumber!.isNotEmpty ? _contactNumber! : "Add contact number",
                style: CheckoutStyles.cardSubtitleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _showContactEditDialog,
          child: const Text(
            "CHANGE",
            style: CheckoutStyles.changeButtonStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard() {
    return Row(
      children: [
        Container(
          padding: CheckoutStyles.paddingAll12,
          decoration: CheckoutStyles.iconContainerDecoration,
          child: const Icon(Icons.payment_outlined, color: CheckoutStyles.primaryColor, size: CheckoutStyles.cardIconSize),
        ),
        CheckoutStyles.sizedBoxWidth16,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Cash On Delivery",
                style: CheckoutStyles.cardTitleStyle,
              ),
              CheckoutStyles.sizedBoxHeight4,
              const Text(
                "Pay when you receive",
                style: CheckoutStyles.cardSubtitleStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShippingOption(String type, String price, String delivery) {
    return ListTile(
      leading: Radio<String>(
        value: type,
        groupValue: _shippingType,
        onChanged: (val) {
          setState(() => _shippingType = val!);
          Navigator.pop(context);
        },
        activeColor: CheckoutStyles.primaryColor,
      ),
      title: Text(type, style: CheckoutStyles.cardTitleStyle),
      subtitle: Text(delivery),
      trailing: Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: CheckoutStyles.primaryColor)),
      onTap: () {
        setState(() => _shippingType = type);
        Navigator.pop(context);
      },
    );
  }

  List<Map<String, dynamic>> _groupItemsByStore(List<dynamic> items) {
    final Map<String, List<dynamic>> groupedItems = {};
    for (var item in items) {
      final storeName = item['store_name'] ?? 'Unknown Store';
      if (!groupedItems.containsKey(storeName)) {
        groupedItems[storeName] = [];
      }
      groupedItems[storeName]!.add(item);
    }

    return groupedItems.entries.map((entry) {
      return {
        'storeName': entry.key,
        'items': entry.value,
      };
    }).toList();
  }

  double _calculateStoreTotal(List<dynamic> items) {
    double total = 0.0;
    for (var item in items) {
      final double pricePerVariant = double.tryParse(item['price_per_variant']?.toString() ?? '0') ?? 0.0;
      final double basePrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
      final double itemPrice = (pricePerVariant > 0) ? pricePerVariant : basePrice;
      
      final int quantity = item['quantity'] is int 
          ? item['quantity'] 
          : int.tryParse(item['quantity'].toString()) ?? 1;
          
      total += itemPrice * quantity;
    }
    return total;
  }

  Widget _buildOrderItem(dynamic item) {
    final images = item['product_images'] as List? ?? [];
    final imageSource = images.isNotEmpty ? images[0].toString() : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: CheckoutStyles.itemImageSize,
            height: CheckoutStyles.itemImageSize,
            decoration: CheckoutStyles.itemImageDecoration,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(CheckoutStyles.borderRadiusMedium),
              child: _buildOrderItemImage(imageSource),
            ),
          ),
          CheckoutStyles.sizedBoxWidth12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name'] ?? 'Product',
                  style: CheckoutStyles.itemNameStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                CheckoutStyles.sizedBoxHeight4,
                Text(
                  "Size : ${item['size'] ?? 'N/A'}",
                  style: CheckoutStyles.itemAttrStyle,
                ),
                CheckoutStyles.sizedBoxHeight8,
                Text(
                  "Rs ${_getOrderItemPrice(item)}",
                  style: CheckoutStyles.itemPriceStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getOrderItemPrice(dynamic item) {
    final double pricePerVariant = double.tryParse(item['price_per_variant']?.toString() ?? '0') ?? 0.0;
    final double basePrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final double itemPrice = (pricePerVariant > 0) ? pricePerVariant : basePrice;
    return itemPrice.toString();
  }

  Widget _buildOrderItemImage(String source) {
    if (source.isEmpty) return const Icon(Icons.image_not_supported);
    if (source.startsWith('assets/')) return Image.asset(source, fit: BoxFit.cover);
    if (source.startsWith('http')) return Image.network(source, fit: BoxFit.cover);
    try {
      return Image.memory(base64Decode(source.split(',').last), fit: BoxFit.cover);
    } catch (e) {
      return const Icon(Icons.image_not_supported);
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: CheckoutStyles.paddingAll24,
      decoration: CheckoutStyles.bottomBarDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Text("Order Total", style: CheckoutStyles.bottomBarLabelStyle),
               Text("Rs ${_totalCost.toStringAsFixed(2)}", style: CheckoutStyles.bottomBarValueStyle),
            ],
          ),
          CheckoutStyles.sizedBoxHeight16,
          SizedBox(
            width: double.infinity,
            height: CheckoutStyles.buttonHeight,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _placeOrder,
              style: CheckoutStyles.primaryButtonStyle,
              child: _isLoading 
                ? const CircularProgressIndicator(color: CheckoutStyles.whiteColor)
                : const Text(
                    'Place Order',
                    style: CheckoutStyles.buttonTextStyle,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
