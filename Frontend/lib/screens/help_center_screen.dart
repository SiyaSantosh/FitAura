import 'package:flutter/material.dart';
import '../styles/help_center_styles.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEmailExpanded = false;
  bool _isWhatsAppExpanded = false;
  
  final List<bool> _faqExpandedStates = [];

  final List<Map<String, String>> _faqItems = [
    {
      'question': 'How can I start selling my products?',
      'answer': 'To start selling, sign up as a Seller and complete your store information. Once your profile and store details are verified by our admin, you can start adding products to your dashboard.'
    },
    {
      'question': 'How do I add items to my cart?',
      'answer': 'Browse through the products on the home screen, select an item to see its details, and tap the \'Add to Cart\' button to save it for purchase.'
    },
    {
      'question': 'How do I contact support?',
      'answer': 'If you need help, you can find our contact details in the \'Contact Us\' tab. We are available via WhatsApp and Email.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _faqExpandedStates.clear();
    _faqExpandedStates.addAll(List.generate(_faqItems.length, (_) => false));
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HelpCenterStyles.whiteColor,
      appBar: AppBar(
        backgroundColor: HelpCenterStyles.whiteColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: HelpCenterStyles.paddingOnlyLeft8,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: HelpCenterStyles.primaryColor, size: HelpCenterStyles.backIconSize),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Help Center',
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
              Tab(text: 'FAQ'),
              Tab(text: 'Contact Us'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                
                _buildFaqTab(),
                
                _buildContactUsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTab() {
    return ListView.builder(
      padding: HelpCenterStyles.paddingAll24,
      itemCount: _faqItems.length,
      itemBuilder: (context, index) {
        return _buildFaqCard(
          question: _faqItems[index]['question']!,
          answer: _faqItems[index]['answer']!,
          isExpanded: _faqExpandedStates[index],
          onTap: () {
            setState(() {
              _faqExpandedStates[index] = !_faqExpandedStates[index];
            });
          },
        );
      },
    );
  }

  Widget _buildFaqCard({
    required String question,
    required String answer,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: HelpCenterStyles.paddingFaqMargin,
      decoration: HelpCenterStyles.faqCardDecoration,
      child: Material(
        color: HelpCenterStyles.transparentColor,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: HelpCenterStyles.paddingAll20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        question,
                        style: HelpCenterStyles.faqQuestionStyle,
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: HelpCenterStyles.primaryColor,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  HelpCenterStyles.sizedBoxHeight12,
                  const Divider(height: 1, thickness: 0.5),
                  HelpCenterStyles.sizedBoxHeight12,
                  Text(
                    answer,
                    style: HelpCenterStyles.faqAnswerStyle,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactUsTab() {
    return SingleChildScrollView(
      padding: HelpCenterStyles.paddingAll24,
      child: Column(
        children: [
          
          _buildContactCard(
            icon: Icons.phone_outlined,
            title: 'WhatsApp',
            isExpanded: _isWhatsAppExpanded,
            onTap: () {
              setState(() {
                _isWhatsAppExpanded = !_isWhatsAppExpanded;
              });
            },
            expandedContent: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HelpCenterStyles.sizedBoxHeight12,
                const Divider(height: 1, thickness: 0.5),
                HelpCenterStyles.sizedBoxHeight12,
                Row(
                  children: [
                    Container(
                      width: HelpCenterStyles.bulletSize,
                      height: HelpCenterStyles.bulletSize,
                      decoration: HelpCenterStyles.bulletDecoration,
                    ),
                    HelpCenterStyles.sizedBoxWidth12,
                    const Text(
                      '0336 0565053',
                      style: HelpCenterStyles.contactDetailStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          _buildContactCard(
            icon: Icons.email_outlined,
            title: 'Email',
            isExpanded: _isEmailExpanded,
            onTap: () {
              setState(() {
                _isEmailExpanded = !_isEmailExpanded;
              });
            },
            expandedContent: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HelpCenterStyles.sizedBoxHeight12,
                const Divider(height: 1, thickness: 0.5),
                HelpCenterStyles.sizedBoxHeight12,
                Row(
                  children: [
                    Container(
                      width: HelpCenterStyles.bulletSize,
                      height: HelpCenterStyles.bulletSize,
                      decoration: HelpCenterStyles.bulletDecoration,
                    ),
                    HelpCenterStyles.sizedBoxWidth12,
                    const Text(
                      'siya.santosh.kumar@gmail.com',
                      style: HelpCenterStyles.contactDetailStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    bool isExpanded = false,
    Widget? expandedContent,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: HelpCenterStyles.paddingContactMargin,
      decoration: HelpCenterStyles.contactCardDecoration,
      child: Material(
        color: HelpCenterStyles.transparentColor,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: HelpCenterStyles.paddingAll16,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: HelpCenterStyles.paddingAll10,
                      decoration: HelpCenterStyles.contactIconDecoration,
                      child: Icon(icon, color: HelpCenterStyles.primaryColor, size: HelpCenterStyles.contactIconSize),
                    ),
                    HelpCenterStyles.sizedBoxWidth16,
                    Expanded(
                      child: Text(
                        title,
                        style: HelpCenterStyles.contactTitleStyle,
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: HelpCenterStyles.lightGrayColor.withOpacity(0.5),
                    ),
                  ],
                ),
                if (isExpanded && expandedContent != null) expandedContent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
