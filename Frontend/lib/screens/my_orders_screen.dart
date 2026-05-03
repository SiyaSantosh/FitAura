import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../styles/help_center_styles.dart';
import 'package:intl/intl.dart';

class MyOrdersScreen extends StatefulWidget {
  final int userId;

  const MyOrdersScreen({super.key, required this.userId});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getCustomerOrders(widget.userId);
      if (res['success']) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(res['data']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _filterOrders(List<String> statuses) {
    return _orders.where((order) {
      final status = (order['order_status'] ?? '').toString().toLowerCase();
      return statuses.contains(status);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HelpCenterStyles.whiteColor,
      appBar: AppBar(
        backgroundColor: HelpCenterStyles.whiteColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: HelpCenterStyles.primaryColor, size: HelpCenterStyles.backIconSize),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Orders',
          style: HelpCenterStyles.appBarTitleStyle,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          HelpCenterStyles.sizedBoxHeight16,
          TabBar(
            controller: _tabController,
            indicatorColor: HelpCenterStyles.primaryColor,
            indicatorWeight: HelpCenterStyles.tabIndicatorWeight,
            labelColor: HelpCenterStyles.primaryColor,
            unselectedLabelColor: HelpCenterStyles.lightGrayColor,
            labelStyle: HelpCenterStyles.tabLabelStyle,
            unselectedLabelStyle: HelpCenterStyles.tabUnselectedLabelStyle,
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Completed'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: HelpCenterStyles.primaryColor))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrdersList(['pending', 'accepted', 'shipped', 'delivered']),
                      _buildOrdersList(['completed', 'rejected']),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<String> statuses) {
    final filteredOrders = _filterOrders(statuses);

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: HelpCenterStyles.lightGrayColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: TextStyle(color: HelpCenterStyles.lightGrayColor, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: HelpCenterStyles.primaryColor,
      child: ListView.builder(
        padding: HelpCenterStyles.paddingAll24,
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(filteredOrders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['order_id'];
    final date = order['created_at'];
    final totalPrice = order['total_price'];
    final status = order['order_status'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: HelpCenterStyles.faqCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOrderDetails(orderId),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: HelpCenterStyles.paddingAll20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #$orderId',
                      style: HelpCenterStyles.faqQuestionStyle,
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                HelpCenterStyles.sizedBoxHeight12,
                const Divider(height: 1, thickness: 0.5),
                HelpCenterStyles.sizedBoxHeight12,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: TextStyle(fontSize: 12, color: HelpCenterStyles.lightGrayColor),
                        ),
                        Text(
                          _formatDate(date),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Price',
                          style: TextStyle(fontSize: 12, color: HelpCenterStyles.lightGrayColor),
                        ),
                        Text(
                          'Rs. $totalPrice',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: HelpCenterStyles.primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showOrderDetails(int orderId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: ApiService.getOrderDetails(orderId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: HelpCenterStyles.primaryColor));
              }
              if (!snapshot.hasData || !snapshot.data!['success']) {
                return const Center(child: Text('Failed to load order details'));
              }

              final data = snapshot.data!['data'];
              final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order Details',
                        style: HelpCenterStyles.appBarTitleStyle,
                      ),
                      _buildStatusBadge(data['order_status'] ?? 'pending'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Order #$orderId',
                    style: TextStyle(color: HelpCenterStyles.lightGrayColor, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...items.map((item) => _buildItemRow(item, data['order_status'] ?? 'pending', orderId)),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  _buildDetailSection('Shipping Information', [
                    _buildDetailRow('Address', data['shipping_address'] ?? 'N/A'),
                    _buildDetailRow('Contact', data['contact_number'] ?? 'N/A'),
                    _buildDetailRow('Type', data['shipping_type'] ?? 'N/A'),
                  ]),
                  const SizedBox(height: 24),
                  _buildDetailSection('Payment Information', [
                    _buildDetailRow('Method', data['payment_method'] ?? 'N/A'),
                    _buildDetailRow('Total Price', 'Rs. ${data['total_price']}', isBold: true),
                  ]),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item, String orderStatus, int orderId) {
    bool isCompleted = orderStatus.toLowerCase() == 'completed';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: HelpCenterStyles.beigeBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item['image'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(item['image'].toString().contains(',') ? item['image'].toString().split(',').last : item['image'].toString()),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.inventory_2_outlined, color: HelpCenterStyles.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['product_name'] ?? 'Product',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      '${item['size']} | ${item['color']} | x${item['quantity']}',
                      style: TextStyle(color: HelpCenterStyles.lightGrayColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                'Rs. ${item['price']}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          if (isCompleted) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showReviewDialog(orderId, item['product_id'], item['product_name'] ?? 'Product'),
                icon: const Icon(Icons.star_outline, size: 16, color: HelpCenterStyles.primaryColor),
                label: const Text('Rate & Review', style: TextStyle(color: HelpCenterStyles.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: HelpCenterStyles.primaryColor, width: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReviewDialog(int orderId, int productId, String productName) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: HelpCenterStyles.beigeBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Center(
            child: Text(
              'Review',
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: HelpCenterStyles.primaryColor,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'How was your experience?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: HelpCenterStyles.darkTextColor),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts about the product...',
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: HelpCenterStyles.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Rate your product',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => setDialogState(() => rating = index + 1),
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                  );
                }),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final res = await ApiService.submitReview(
                        orderId: orderId,
                        productId: productId,
                        customerId: widget.userId,
                        rating: rating,
                        comment: commentController.text,
                      );
                      if (res['success']) {
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'] ?? 'Failed to submit review'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HelpCenterStyles.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: HelpCenterStyles.lightGrayColor, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
                color: isBold ? HelpCenterStyles.primaryColor : HelpCenterStyles.darkTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status.toLowerCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.green;
      case 'shipped': return Colors.blue;
      case 'delivered': return Colors.green;
      case 'completed': return const Color(0xFF2E7D32);
      case 'rejected': return Colors.red;
      default: return HelpCenterStyles.lightGrayColor;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return date.toString();
    }
  }
}
