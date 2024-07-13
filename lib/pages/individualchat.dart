import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:first_chat_app/models/usermodel.dart';
import 'package:first_chat_app/widgets/chatbox.dart';
import 'package:first_chat_app/widgets/chatbubble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class IndividualChat extends StatefulWidget {
  const IndividualChat({
    required this.user,
    Key? key,
  }) : super(key: key);

  final UserModel user;

  @override
  State<IndividualChat> createState() => _IndividualChatState();
}

class _IndividualChatState extends State<IndividualChat> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  static const int _messageLimit = 50;

  int _unreadMessageCount = 0;
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _isMounted = false;
    _scrollController.removeListener(_onScroll);
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  void _onScroll() {
    if (_isScrolledToBottom()) {
      setState(() {
        // This will trigger a rebuild, which will hide the button
        // since we check !_isScrolledToBottom() in the build method
      });
    }
  }

  bool _isScrolledToBottom() {
    if (!_scrollController.hasClients) return true;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >=
        (maxScroll * 0.9); // Consider "bottom" if within 10% of the end
  }

  Future<void> _sendMessage(String imageUrl) async {
    final messageContent = _messageController.text.trim();
    if (messageContent.isNotEmpty || imageUrl.isNotEmpty) {
      final user = _auth.currentUser;
      if (user == null) {
        _logError("User is not authenticated.");
        return;
      }

      try {
        await _firestore.collection('chats').add({
          'content': messageContent,
          'senderId': user.uid,
          'receiverId': widget.user.userId,
          'timestamp': FieldValue.serverTimestamp(),
          'imageUrl': imageUrl,
          'isRead': false,
        });

        if (_isMounted) {
          _messageController.clear();
          _scrollToBottom();
          await _markMessagesAsRead(widget.user.userId, user.uid);
        }
      } catch (e) {
        _logError("Error sending message: $e");
      }
    }
  }

  Future<void> _markMessagesAsRead(String senderId, String receiverId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      _logError("Error marking messages as read: $e");
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    if (mounted) {
      setState(() {
        _unreadMessageCount = 0;
      });
    }
  }

  void _logError(String message) {
    print(message);
    // Consider using a proper logging framework in production
  }

  void _updateUnreadMessageCount(List<QueryDocumentSnapshot> messages) {
    final currentUserId = _auth.currentUser!.uid;
    int count = 0;
    for (var message in messages) {
      if (message['senderId'] != currentUserId &&
          !(message['isRead'] as bool? ?? false)) {
        count++;
      } else {
        break;
      }
    }
  }

  Future<void> _clearMessages() async {
    final currentUserId = _auth.currentUser!.uid;
    final otherUserId = widget.user.userId;

    try {
      // First query: messages sent by currentUser to otherUser
      final querySent = await _firestore
          .collection('chats')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: otherUserId)
          .get();

      // Second query: messages received by currentUser from otherUser
      final queryReceived = await _firestore
          .collection('chats')
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: currentUserId)
          .get();

      // Combine the results
      final allDocs = [...querySent.docs, ...queryReceived.docs];

      // Delete all retrieved messages
      final batch = _firestore.batch();
      for (var doc in allDocs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Messages cleared successfully'),
            backgroundColor: Colors.indigo,
          ),
        );
      }
    } catch (e) {
      _logError("Error clearing messages: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to clear messages')),
        );
      }
    }
  }

  Widget _buildScrollToBottomButton(int unreadCount) {
    return FloatingActionButton(
      mini: true,
      child: Stack(
        children: [
          const Icon(Icons.arrow_downward),
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: _scrollToBottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: _buildMessageList(),
          ),
          ChatBox(
            onSend: _sendMessage,
            controller: _messageController,
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.indigo[900],
      automaticallyImplyLeading: true,
      leadingWidth: 25,
      title: Row(
        children: [
          _buildProfileAvatar(),
          const SizedBox(width: 10),
          _buildUserInfo(),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            // Show a confirmation dialog before clearing messages
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Clear Messages'),
                  content: const Text(
                      'Are you sure you want to clear all messages? This action cannot be undone.'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: const Text('Clear'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _clearMessages();
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return CircleAvatar(
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: widget.user.profilePhotoUrl,
          placeholder: (context, url) =>
              Image.asset('images/profileplaceholder.jpg'),
          errorWidget: (context, url, error) => const Icon(Icons.error),
          fit: BoxFit.cover,
          width: 50,
          height: 50,
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Text(
      widget.user.name,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<MessageData>(
      stream: _getCombinedMessageStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final messageData = snapshot.data!;
        final allMessages = messageData.messages;
        final unreadCount = messageData.unreadCount;

        return Stack(
          children: [
            ListView.builder(
              reverse: true,
              controller: _scrollController,
              itemCount: allMessages.length,
              itemBuilder: (context, index) =>
                  _buildMessageItem(allMessages[index]),
            ),
            if (unreadCount > 0 && !_isScrolledToBottom())
              Positioned(
                bottom: 20,
                right: 20,
                child: _buildScrollToBottomButton(unreadCount),
              ),
          ],
        );
      },
    );
  }

  Stream<MessageData> _getCombinedMessageStream() {
    final currentUserId = _auth.currentUser!.uid;
    final otherUserId = widget.user.userId;

    return Rx.combineLatest2(
      _firestore
          .collection('chats')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: otherUserId)
          .orderBy('timestamp', descending: true)
          .limit(_messageLimit)
          .snapshots(),
      _firestore
          .collection('chats')
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .limit(_messageLimit)
          .snapshots(),
      (QuerySnapshot a, QuerySnapshot b) {
        final allMessages = _combineAndSortMessages([a, b]);
        final unreadCount = _calculateUnreadCount(allMessages);
        return MessageData(allMessages, unreadCount);
      },
    );
  }

  int _calculateUnreadCount(List<QueryDocumentSnapshot> messages) {
    final currentUserId = _auth.currentUser!.uid;
    int count = 0;
    for (var message in messages) {
      if (message['senderId'] != currentUserId &&
          !(message['isRead'] as bool? ?? false)) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  List<QueryDocumentSnapshot> _combineAndSortMessages(
      List<QuerySnapshot> snapshots) {
    final allMessages = [...snapshots[0].docs, ...snapshots[1].docs];
    allMessages.sort((a, b) {
      final aTimestamp = a['timestamp'] as Timestamp?;
      final bTimestamp = b['timestamp'] as Timestamp?;
      return (bTimestamp ?? Timestamp.now())
          .compareTo(aTimestamp ?? Timestamp.now());
    });
    return allMessages;
  }

  Widget _buildMessageItem(QueryDocumentSnapshot message) {
    final isMe = message['senderId'] == _auth.currentUser!.uid;
    final timestamp = message['timestamp'] as Timestamp?;
    final formattedTime =
        timestamp != null ? DateFormat.jm().format(timestamp.toDate()) : '';

    if (!message['isRead'] && !isMe) {
      Future.microtask(() {
        _firestore.collection('chats').doc(message.id).update({'isRead': true});
      });
    }

    return ChatBubble(
      iscoming: isMe,
      status: Icons.done_all,
      message: message['content'],
      time: formattedTime,
      isMe: isMe,
      imageurl: message['imageUrl'] ?? '',
      isRead: message['isRead'] as bool? ?? false,
    );
  }
}

class MessageData {
  final List<QueryDocumentSnapshot> messages;
  final int unreadCount;

  MessageData(this.messages, this.unreadCount);
}
