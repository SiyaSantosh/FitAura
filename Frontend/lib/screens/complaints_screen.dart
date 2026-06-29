import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../styles/help_center_styles.dart';

class ComplaintsScreen extends StatefulWidget {
  final int userId;

  const ComplaintsScreen({super.key, required this.userId});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadComplaints();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getCustomerComplaints(widget.userId);
      print('Complaints API Response: $res');
      if (res['success']) {
        setState(() {
          _complaints = List<Map<String, dynamic>>.from(res['data'] ?? []);
          print('Loaded ${_complaints.length} complaints');
          _complaints.forEach((c) => print('Complaint #${c['complaint_id']}: status=${c['status']}'));
          _isLoading = false;
        });
      } else {
        print('API Error: ${res['message']}');
        print('Full error response: ${res}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Exception loading complaints: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _filterComplaints(bool isActive) {
    return _complaints.where((c) {
      final status = (c['status'] ?? '').toString().toLowerCase();
      if (isActive) {
        return status == 'review' || status == 'active';
      } else {
        return status == 'completed' || status == 'rejected';
      }
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
          'Complaints',
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
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: HelpCenterStyles.primaryColor))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildComplaintsList(true),
                      _buildComplaintsList(false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsList(bool isActive) {
    final filtered = _filterComplaints(isActive);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feedback_outlined,
              size: 64,
              color: HelpCenterStyles.lightGrayColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active complaints' : 'No completed complaints',
              style: const TextStyle(color: HelpCenterStyles.lightGrayColor, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComplaints,
      color: HelpCenterStyles.primaryColor,
      child: ListView.builder(
        padding: HelpCenterStyles.paddingAll24,
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return _buildComplaintCard(filtered[index]);
        },
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> c) {
    final complaintId = c['complaint_id'];
    final orderId = c['order_id'];
    final date = c['created_at'];
    final type = c['type'] ?? 'return';
    final issue = c['issue'] ?? 'torn';
    final desc = c['description'] ?? '';
    final productName = c['product_name'] ?? 'Product';
    final status = (c['status'] ?? 'review').toString().toUpperCase();

    // Parse product_image - it's a JSON array now
    String? productImage;
    if (c['product_image'] != null && c['product_image'].toString().isNotEmpty) {
      try {
        List<dynamic> images = jsonDecode(c['product_image'].toString());
        if (images.isNotEmpty) {
          productImage = images[0].toString();
        }
      } catch (_) {
        // Fallback - treat as single string or comma-separated
        productImage = c['product_image'].toString().contains(',') 
            ? c['product_image'].toString().split(',').first 
            : c['product_image'].toString();
      }
    }

    // Admin response details
    final adminDecision = c['admin_decision'];
    final adminVerification = c['admin_verification'];
    final adminComment = c['admin_comment'];
    final refundAmount = c['refund_amount'];

    // Decoded uploaded images
    List<dynamic> images = [];
    if (c['images'] != null && c['images'].toString().isNotEmpty) {
      try {
        images = jsonDecode(c['images'].toString());
      } catch (_) {
        // Simple comma separated or single string
        images = c['images'].toString().split(',');
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: HelpCenterStyles.faqCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showComplaintDetails(c),
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
                      'Complaint #$complaintId',
                      style: HelpCenterStyles.faqQuestionStyle,
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                HelpCenterStyles.sizedBoxHeight12,
                const Divider(height: 1, thickness: 0.5),
                HelpCenterStyles.sizedBoxHeight12,

                // Product Row
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: HelpCenterStyles.beigeBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: productImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(_cleanBase64(productImage)),
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(Icons.inventory_2_outlined, color: HelpCenterStyles.primaryColor),
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
                            productName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: HelpCenterStyles.darkTextColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Order #$orderId  •  $issue',
                            style: const TextStyle(fontSize: 12, color: HelpCenterStyles.lightGrayColor),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: HelpCenterStyles.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: const TextStyle(color: HelpCenterStyles.primaryColor, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                ),

                HelpCenterStyles.sizedBoxHeight12,
                Text(
                  desc,
                  style: const TextStyle(fontSize: 13, color: HelpCenterStyles.darkTextColor, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filed on ${_formatDate(date)}',
                      style: const TextStyle(fontSize: 11, color: HelpCenterStyles.lightGrayColor),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: HelpCenterStyles.lightGrayColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'COMPLETED') color = Colors.green;
    if (status == 'REJECTED') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showComplaintDetails(Map<String, dynamic> complaint) {
    final complaintId = complaint['complaint_id'];
    final orderId = complaint['order_id'];
    final type = complaint['type'] ?? 'return';
    final issue = complaint['issue'] ?? 'torn';
    final desc = complaint['description'] ?? '';
    final productName = complaint['product_name'] ?? 'Product';
    final status = (complaint['status'] ?? 'review').toString().toUpperCase();
    final date = complaint['created_at'];

    // Parse product_image
    String? productImage;
    if (complaint['product_image'] != null && complaint['product_image'].toString().isNotEmpty) {
      try {
        List<dynamic> images = jsonDecode(complaint['product_image'].toString());
        if (images.isNotEmpty) {
          productImage = images[0].toString();
        }
      } catch (_) {
        productImage = complaint['product_image'].toString().contains(',') 
            ? complaint['product_image'].toString().split(',').first 
            : complaint['product_image'].toString();
      }
    }

    // Admin response details
    final adminDecision = complaint['admin_decision'];
    final adminVerification = complaint['admin_verification'];
    final adminComment = complaint['admin_comment'];
    final refundAmount = complaint['refund_amount'];

    // Decoded uploaded images
    List<dynamic> images = [];
    if (complaint['images'] != null && complaint['images'].toString().isNotEmpty) {
      try {
        images = jsonDecode(complaint['images'].toString());
      } catch (_) {
        images = complaint['images'].toString().split(',');
      }
    }

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
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Drag handle
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
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Complaint #$complaintId',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 16),

              // Product Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Product Information',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: HelpCenterStyles.primaryColor),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: HelpCenterStyles.beigeBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: productImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    base64Decode(_cleanBase64(productImage)),
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.inventory_2_outlined, color: HelpCenterStyles.primaryColor),
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
                                productName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                'Order #$orderId',
                                style: const TextStyle(fontSize: 12, color: HelpCenterStyles.lightGrayColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Complaint Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complaint Details',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: HelpCenterStyles.primaryColor),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Type',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            Text(
                              type.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Issue',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            Text(
                              issue,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filed On',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            Text(
                              _formatDate(date),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Description',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Complaint Images
              if (images.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attached Images',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: HelpCenterStyles.primaryColor),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          itemBuilder: (context, idx) {
                            final imgStr = images[idx].toString();
                            if (imgStr.isEmpty) return const SizedBox.shrink();
                            return Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(_cleanBase64(imgStr)),
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 24),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Admin Feedback
              if (adminComment != null || adminDecision != null || adminVerification != null || (refundAmount != null && double.tryParse(refundAmount.toString()) != 0.0)) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.admin_panel_settings, size: 18, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Admin Response',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          const Spacer(),
                          if (adminVerification != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                adminVerification.toString(),
                                style: TextStyle(color: Colors.green.shade800, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (adminDecision != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Decision',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                              ),
                              Text(
                                adminDecision.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      if (adminComment != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Comment',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                              ),
                              Text(
                                adminComment.toString(),
                                style: const TextStyle(fontSize: 12, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      if (refundAmount != null && double.tryParse(refundAmount.toString()) != 0.0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Refund Amount',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                            Text(
                              'Rs. $refundAmount',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return date.toString();
    }
  }

  // Helper to strip data URL prefix and get pure base64
  String _cleanBase64(String encoded) {
    if (encoded.startsWith('data:')) {
      // Format: data:image/jpeg;base64,xxxxx
      final parts = encoded.split(',');
      return parts.length > 1 ? parts[1] : encoded;
    }
    return encoded;
  }
}
