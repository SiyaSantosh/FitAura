import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int currentUserId;
  final int otherUserId;
  final String otherUserName;
  final String? storeLogo;
  final bool showCloseButton;

  const ChatScreen({
    Key? key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    this.storeLogo,
    this.showCloseButton = false,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late IO.Socket socket;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _hasPositionedInitialMessages = false;

  static const Color _primary = Color(0xFF704F38);
  static const Color _beige  = Color(0xFFF5F1EB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus) {
        _scrollToBottom(forceJump: true);
      }
    });
    _fetchHistory();
    _initSocket();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    await ApiService.markMessagesAsRead(widget.currentUserId, widget.otherUserId);
  }

  Future<void> _fetchHistory() async {
    final result = await ApiService.getChatHistory(widget.currentUserId, widget.otherUserId);
    if (mounted) {
      if (result['success']) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(result['data']);
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initSocket() {
    socket = IO.io(ApiService.baseUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build());
    socket.connect();
    socket.onConnect((_) {
      socket.emit('register', widget.currentUserId);
    });

    socket.on('receive_message', (data) {
      if (mounted) {
        final senderId = data['sender_id'];
        final receiverId = data['receiver_id'];
        if ((senderId == widget.otherUserId && receiverId == widget.currentUserId) ||
            (senderId == widget.currentUserId && receiverId == widget.otherUserId)) {
          setState(() {
            _messages.add(Map<String, dynamic>.from(data));
          });
          _scrollToBottom();
        }
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    socket.emit('send_message', {
      'senderId': widget.currentUserId,
      'receiverId': widget.otherUserId,
      'message': text,
    });

    _messageController.clear();
  }

  void _scrollToBottom({bool forceJump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final maxExtent = _scrollController.position.maxScrollExtent;
      final shouldJumpOnly = forceJump || !_hasPositionedInitialMessages;

      if (shouldJumpOnly) {
        _scrollController.jumpTo(maxExtent);
        _hasPositionedInitialMessages = true;
      } else {
        _scrollController.animateTo(
          maxExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }

      Future.delayed(const Duration(milliseconds: 80), () {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    socket.disconnect();
    socket.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    
    _scrollToBottom();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime;
    if (timestamp is DateTime) {
      dateTime = timestamp.toLocal();
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp)?.toLocal() ?? DateTime.now();
    } else {
      return '';
    }
    
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    
    return '$hour:$minute $period';
  }

  Widget _buildLogoAvatar(double radius) {
    final logo = widget.storeLogo;
    if (logo != null && logo.isNotEmpty) {
      try {
        ImageProvider img;
        if (logo.startsWith('http')) {
          img = NetworkImage(logo);
        } else {
          img = MemoryImage(base64Decode(logo.split(',').last));
        }
        return CircleAvatar(radius: radius, backgroundImage: img, backgroundColor: _beige);
      } catch (_) {}
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _beige,
      child: Icon(
        logo != null && logo.contains('logo') ? Icons.store : Icons.person,
        color: _primary, 
        size: radius
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.18),
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF7F5B42),
                Color(0xFF704F38),
                Color(0xFF5F422E),
              ],
            ),
          ),
        ),
        leading: widget.showCloseButton
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                splashRadius: 20,
                onPressed: () => Navigator.pop(context),
              ),
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
              ),
              child: _buildLogoAvatar(18),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Active now',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: widget.showCloseButton
            ? [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 22),
                  splashRadius: 20,
                  onPressed: () => Navigator.pop(context),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _primary))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender_id'] == widget.currentUserId;
                      final isLast = index == _messages.length - 1;
                      return _buildBubble(
                        msg['message'] ?? '', 
                        isMe, 
                        timestamp: isLast ? _formatTimestamp(msg['created_at'] ?? msg['last_message_time']) : null
                      );
                    },
                  ),
          ),

          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isMe, {String? timestamp}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(
              bottom: timestamp != null ? 4 : 8,
              left: isMe ? 60 : 0,
              right: isMe ? 0 : 60,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? _primary : _beige,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(20),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF1F2029),
                fontSize: 15,
              ),
            ),
          ),
          if (timestamp != null)
            Padding(
              padding: EdgeInsets.only(
                bottom: 8,
                left: isMe ? 0 : 4,
                right: isMe ? 4 : 0,
              ),
              child: Text(
                timestamp,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final bottomInset = math.max(
      12.0,
      MediaQuery.of(context).viewPadding.bottom,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: _beige,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Color(0xFFA68470), fontSize: 15),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 15, color: Color(0xFF1F2029)),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
