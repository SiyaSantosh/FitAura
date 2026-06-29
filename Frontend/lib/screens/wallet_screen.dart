import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../styles/help_center_styles.dart';

class WalletScreen extends StatefulWidget {
  final int userId;

  const WalletScreen({super.key, required this.userId});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _walletBalance = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _storeBalances = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);

    final res = await ApiService.getWalletData(widget.userId);
    if (!mounted) return;

    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>;
      setState(() {
        _walletBalance =
            double.tryParse(data['wallet']?['balance']?.toString() ?? '0') ??
            0.0;
        _transactions =
            (data['transactions'] as List<dynamic>?)?.map((tx) {
              final item = tx as Map<String, dynamic>;
              return {
                'type': item['type'] ?? 'debit',
                'amount':
                    double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0,
                'description': item['description'] ?? 'Transaction',
                'method': item['method'] ?? '',
                'timestamp':
                    item['timestamp'] ?? DateTime.now().toIso8601String(),
              };
            }).toList() ??
            [];
        _storeBalances =
            ((data['store_credits'] ?? data['store_balances'])
                    as List<dynamic>?)
                ?.map((store) {
                  final item = store as Map<String, dynamic>;
                  return {
                    'store_id': item['store_id'],
                    'store_name': item['store_name'] ?? 'Store',
                    'balance':
                        double.tryParse(item['balance']?.toString() ?? '0') ??
                        0.0,
                  };
                })
                .toList() ??
            [];
      });
    } else {
      setState(() {
        _walletBalance = 0.0;
        _transactions = [];
        _storeBalances = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Unable to load wallet data')),
      );
    }

    setState(() => _isLoading = false);
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
          icon: const Icon(
            Icons.arrow_back,
            color: HelpCenterStyles.primaryColor,
            size: HelpCenterStyles.backIconSize,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Wallet', style: HelpCenterStyles.appBarTitleStyle),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: HelpCenterStyles.primaryColor,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadWalletData,
              color: HelpCenterStyles.primaryColor,
              child: ListView(
                padding: HelpCenterStyles.paddingAll24,
                children: [
                  // Wallet Balance Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          HelpCenterStyles.primaryColor,
                          HelpCenterStyles.primaryColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: HelpCenterStyles.primaryColor.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wallet Balance',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Rs. ${_walletBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_storeBalances.isNotEmpty) ...[
                    const Text(
                      'Store Credits',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: HelpCenterStyles.darkTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._storeBalances.map(
                      (store) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: HelpCenterStyles.primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.storefront_outlined,
                                color: HelpCenterStyles.primaryColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    store['store_name'] ?? 'Store',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: HelpCenterStyles.darkTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Available credit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: HelpCenterStyles.lightGrayColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Rs. ${(store['balance'] as double).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: HelpCenterStyles.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Transactions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaction History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: HelpCenterStyles.darkTextColor,
                        ),
                      ),
                      Text(
                        '${_transactions.length} transactions',
                        style: const TextStyle(
                          fontSize: 12,
                          color: HelpCenterStyles.lightGrayColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Transaction Cards
                  if (_transactions.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: HelpCenterStyles.lightGrayColor.withOpacity(
                              0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No transactions yet',
                            style: TextStyle(
                              color: HelpCenterStyles.lightGrayColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(_transactions[index]);
                      },
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
    final timestamp = transaction['timestamp'];
    final isCredit = type == 'credit';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCredit ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isCredit ? Colors.green : Colors.red,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: HelpCenterStyles.darkTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if ((transaction['method'] as String?)?.isNotEmpty == true)
                  Text(
                    transaction['method'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: HelpCenterStyles.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if ((transaction['method'] as String?)?.isNotEmpty == true)
                  const SizedBox(height: 4),
                Text(
                  _formatDate(timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: HelpCenterStyles.lightGrayColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
        ],
      ),
    );
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
