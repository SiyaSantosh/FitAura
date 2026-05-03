import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  final int? userId;
  final VoidCallback? onBackPressed;

  const ChatsListScreen({super.key, required this.userId, this.onBackPressed});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  List<dynamic> _chats = [];
  bool _isLoading = true;

  static const Color _navBg = Color(0xFF704F38);
  static const Color _beige  = Color(0xFFF5F1EB);

  @override
  void initState() {
    super.initState();
    _fetchInbox();
  }

  Future<void> _fetchInbox() async {
    if (widget.userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await ApiService.getChatInbox(widget.userId!);

    if (mounted) {
      if (result['success']) {
        setState(() {
          _chats = result['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
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
    if (difference.inDays > 7) return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    if (difference.inDays >= 1) return '${difference.inDays}d ago';
    if (difference.inHours >= 1) return '${difference.inHours}h ago';
    if (difference.inMinutes >= 1) return '${difference.inMinutes}m ago';
    return 'just now';
  }

  String? _extractChatAvatar(dynamic chat) {
    if (chat is! Map) return null;

    const imageKeys = [
      'store_logo',
      'logo',
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

  Widget _buildLogo(String? logo) {
    if (logo != null && logo.isNotEmpty) {
      try {
        ImageProvider imageProvider;
        if (logo.startsWith('http')) {
          imageProvider = NetworkImage(logo);
        } else {
          
          final bytes = base64Decode(logo.split(',').last);
          imageProvider = MemoryImage(bytes);
        }
        return CircleAvatar(
          radius: 26,
          backgroundImage: imageProvider,
          backgroundColor: const Color(0xFFF5F1EB),
        );
      } catch (_) {}
    }
    
    return const CircleAvatar(
      radius: 26,
      backgroundColor: Color(0xFF9E896A),
      child: Icon(Icons.store, color: Colors.white, size: 26),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null) {
      return const Center(child: Text('Please log in to view messages'));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF704F38), size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    if (widget.onBackPressed != null) {
                      widget.onBackPressed!();
                    } else if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Messages',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xff9E896A)))
                : _chats.isEmpty
                    ? const Center(child: Text('No active chats yet'))
                    : RefreshIndicator(
                        color: const Color(0xff9E896A),
                        onRefresh: _fetchInbox,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _chats.length,
                          itemBuilder: (context, index) {
                            final chat = _chats[index];
                            final otherUserId = chat['other_user_id'];
                            final otherUserName = chat['other_user_name'] ?? 'Unknown';
                            final lastMessage = chat['last_message'] ?? '';
                            final timeAgo = _formatTimeAgo(chat['last_message_time']);
                            final isMe = chat['last_message_sender_id'] == widget.userId;
                            final storeLogo = _extractChatAvatar(chat);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ChatTile(
                                logo: storeLogo,
                                name: otherUserName,
                                lastMessage: isMe ? 'You: $lastMessage' : lastMessage,
                                timeAgo: timeAgo,
                                navBg: _navBg,
                                tileColor: _beige,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        currentUserId: widget.userId!,
                                        otherUserId: otherUserId,
                                        otherUserName: otherUserName,
                                        storeLogo: storeLogo,
                                      ),
                                    ),
                                  );
                                  _fetchInbox();
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String? logo;
  final String name;
  final String lastMessage;
  final String timeAgo;
  final Color navBg;
  final Color tileColor;
  final VoidCallback onTap;

  const _ChatTile({
    required this.logo,
    required this.name,
    required this.lastMessage,
    required this.timeAgo,
    required this.navBg,
    required this.tileColor,
    required this.onTap,
  });

  Widget _buildLogo() {
    if (logo != null && logo!.isNotEmpty) {
      try {
        ImageProvider img;
        if (logo!.startsWith('http')) {
          img = NetworkImage(logo!);
        } else {
          img = MemoryImage(base64Decode(logo!.split(',').last));
        }
        return CircleAvatar(radius: 24, backgroundImage: img, backgroundColor: Colors.white24);
      } catch (_) {}
    }
    
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.white24,
      child: Icon(
        
        logo != null && logo!.contains('logo') ? Icons.store : Icons.person, 
        color: Colors.white, 
        size: 24
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildLogo(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1F2029),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          color: Color(0xFF797979),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: const TextStyle(
                      color: Color(0xFF704F38),
                      fontSize: 13,
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
    );
  }
}
