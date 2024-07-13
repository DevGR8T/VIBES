import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_chat_app/models/usermodel.dart';
import 'package:first_chat_app/pages/individualchat.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllChatsPage extends StatefulWidget {
  const AllChatsPage({required this.user, super.key});
  final User user;

  @override
  State<AllChatsPage> createState() => _AllChatsPageState();
}

class _AllChatsPageState extends State<AllChatsPage> {
  bool isLoading = true;
  bool isSearched = false;
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  UserModel? userModel;
  List<UserModel> userslist = [];
  File? selectedImage;
  String? fileName;
  String searchText = '';
  Map<String, int> messageCountMap = {}; // Map to store message counts
  bool showDeleteIcon = false;
  String? selectedUserId;

  late StreamSubscription<QuerySnapshot> _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _loadMessageCountMap(); // Load message count map from Firestore
    getUsersData(); //Load user data

    // Subscribe to messages stream
    _messagesSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('receiverId', isEqualTo: firebaseAuth.currentUser!.uid)
        .snapshots()
        .listen((snapshot) {
      snapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          String senderId = change.doc['senderId'];
          bool isRead = change.doc['isRead'] ?? false;
          if (!isRead && senderId != firebaseAuth.currentUser!.uid) {
            // Update message count
            setState(() {
              if (messageCountMap.containsKey(senderId)) {
                messageCountMap[senderId] =
                    (messageCountMap[senderId] ?? 0) + 1;
              } else {
                messageCountMap[senderId] = 1;
              }
            });

            // Update the corresponding user in userslist
            int userIndex =
                userslist.indexWhere((user) => user.userId == senderId);
            if (userIndex != -1) {
              setState(() {
                userslist[userIndex].unreadMessageCount =
                    messageCountMap[senderId] ?? 0;
              });
            }

            // Update last message for the user in userslist
            UserModel? updatedUser = userslist
                .firstWhere((user) => user.userId == senderId, orElse: () {
              return UserModel(
                userId: senderId,
                name: 'Unknown User',
                profilePhotoUrl: 'default_profile_image_url', email: '',
                about: '',
                // Set other default values as needed
              );
            } // Return null if no matching user is found
                    );
            if (updatedUser != null) {
              setState(() {
                updatedUser.lastmessage = change.doc['content'] as String?;
                updatedUser.isImage = change.doc['imageUrl'] != null &&
                    change.doc['imageUrl'].isNotEmpty;
                updatedUser.lastMessageTime =
                    (change.doc['timestamp'] as Timestamp).toDate();
              });
            }

            _saveMessageCountMap();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    // Save messageCountMap to Firestore on app exit
    _saveMessageCountMap();
    _messagesSubscription.cancel(); // Cancel the stream subscription
    super.dispose();
  }

  // Method to mark message as read when returning from IndividualChat
  void _markMessagesAsRead(String senderId) async {
    try {
      QuerySnapshot unreadMessages = await FirebaseFirestore.instance
          .collection('chats')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: firebaseAuth.currentUser!.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'isRead': true});
      }

      setState(() {
        messageCountMap[senderId] = 0;
      });

      _saveMessageCountMap();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Save messageCountMap to Firestore
  void _saveMessageCountMap() async {
    try {
      await FirebaseFirestore.instance
          .collection('messageCounts')
          .doc(firebaseAuth.currentUser!.uid)
          .set({'counts': messageCountMap});
      print('Message counts saved successfully.');
    } catch (e) {
      print('Error saving message counts: $e');
    }
  }

  // Load messageCountMap from Firestore

  Future<void> _loadMessageCountMap() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('messageCounts')
          .doc(firebaseAuth.currentUser!.uid)
          .get();
      if (doc.exists) {
        setState(() {
          messageCountMap = Map.from(doc.data()!['counts']);
        });
        print('Message counts loaded successfully.');
      } else {
        messageCountMap = {};
      }
    } catch (e) {
      print('Error loading message counts: $e');
    }
    setState(() {
      isLoading = false;
    });
  }

  // Fetching users with whom the logged-in user has chats
  Future<void> getUsersData() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        print("User is not authenticated.");
        return;
      }

      // Fetch chats where the logged-in user is either sender or receiver
      QuerySnapshot sentChats = await FirebaseFirestore.instance
          .collection('chats')
          .where('senderId', isEqualTo: user.uid)
          .get();

      QuerySnapshot receivedChats = await FirebaseFirestore.instance
          .collection('chats')
          .where('receiverId', isEqualTo: user.uid)
          .get();

      // Combine the user IDs from both sent and received chats
      Set<String> userIds = {};
      sentChats.docs.forEach((doc) {
        userIds.add(doc['receiverId']);
      });
      receivedChats.docs.forEach((doc) {
        userIds.add(doc['senderId']);
      });

      // Fetch users based on chat data
      QuerySnapshot usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds.toList())
          .get();

      List<UserModel> users = usersQuery.docs.map((doc) {
        return UserModel.fromDocumentSnapshot(doc);
      }).toList();

      // Fetch the last message for each user
      for (UserModel userModel in users) {
        // Query for both sent and received messages
        QuerySnapshot sentMessagesQuery = await FirebaseFirestore.instance
            .collection('chats')
            .where('senderId', isEqualTo: user.uid)
            .where('receiverId', isEqualTo: userModel.userId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        QuerySnapshot receivedMessagesQuery = await FirebaseFirestore.instance
            .collection('chats')
            .where('senderId', isEqualTo: userModel.userId)
            .where('receiverId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        var lastSentMessage = sentMessagesQuery.docs.isNotEmpty
            ? sentMessagesQuery.docs.first
            : null;
        var lastReceivedMessage = receivedMessagesQuery.docs.isNotEmpty
            ? receivedMessagesQuery.docs.first
            : null;

        // Determine the most recent message
        if (lastSentMessage != null && lastReceivedMessage != null) {
          var lastSentTimestamp = lastSentMessage['timestamp'] as Timestamp?;
          var lastReceivedTimestamp =
              lastReceivedMessage['timestamp'] as Timestamp?;

          if (lastSentTimestamp != null && lastReceivedTimestamp != null) {
            if (lastSentTimestamp.compareTo(lastReceivedTimestamp) > 0) {
              userModel.lastmessage = lastSentMessage['content'] as String?;
              userModel.isImage = lastSentMessage['imageUrl'] != null &&
                  lastSentMessage['imageUrl'].isNotEmpty;
              userModel.lastMessageTime = lastSentTimestamp.toDate();
            } else {
              userModel.lastmessage = lastReceivedMessage['content'] as String?;
              userModel.isImage = lastReceivedMessage['imageUrl'] != null &&
                  lastReceivedMessage['imageUrl'].isNotEmpty;
              userModel.lastMessageTime = lastReceivedTimestamp.toDate();
            }
          } else if (lastSentTimestamp != null) {
            userModel.lastmessage = lastSentMessage['content'] as String?;
            userModel.isImage = lastSentMessage['imageUrl'] != null &&
                lastSentMessage['imageUrl'].isNotEmpty;
            userModel.lastMessageTime = lastSentTimestamp.toDate();
          } else if (lastReceivedTimestamp != null) {
            userModel.lastmessage = lastReceivedMessage['content'] as String?;
            userModel.isImage = lastReceivedMessage['imageUrl'] != null &&
                lastReceivedMessage['imageUrl'].isNotEmpty;
            userModel.lastMessageTime = lastReceivedTimestamp.toDate();
          }
        } else if (lastSentMessage != null) {
          userModel.lastmessage = lastSentMessage['content'] as String?;
          userModel.isImage = lastSentMessage['imageUrl'] != null &&
              lastSentMessage['imageUrl'].isNotEmpty;
          userModel.lastMessageTime =
              (lastSentMessage['timestamp'] as Timestamp).toDate();
        } else if (lastReceivedMessage != null) {
          userModel.lastmessage = lastReceivedMessage['content'] as String?;
          userModel.isImage = lastReceivedMessage['imageUrl'] != null &&
              lastReceivedMessage['imageUrl'].isNotEmpty;
          userModel.lastMessageTime =
              (lastReceivedMessage['timestamp'] as Timestamp).toDate();
        } else {
          userModel.lastmessage = null;
          userModel.isImage = false;
          userModel.lastMessageTime = null;
        }

        // Initialize message count for the user
        if (!messageCountMap.containsKey(userModel.userId)) {
          messageCountMap[userModel.userId] = 0;
        } else {
          // Update unread count for each user based on unread messages
          QuerySnapshot unreadMessages = await FirebaseFirestore.instance
              .collection('chats')
              .where('senderId', isEqualTo: userModel.userId)
              .where('receiverId', isEqualTo: firebaseAuth.currentUser!.uid)
              .where('isRead', isEqualTo: false)
              .get();
          messageCountMap[userModel.userId] = unreadMessages.docs.length;
        }
      }

      setState(() {
        userslist =
            users.where((userModel) => userModel.userId != user.uid).toList();
        userModel = userslist.isNotEmpty ? userslist.first : null;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  String _formatTime(DateTime time) {
    // Get current date without time
    DateTime currentDate = DateTime.now();
    DateTime messageDate = time;

    // Compare the message date with the current date
    if (currentDate.year == messageDate.year &&
        currentDate.month == messageDate.month &&
        currentDate.day == messageDate.day) {
      // Today, format as time only
      return DateFormat.jm().format(time); // Format: 8:32 PM
    } else if (currentDate.year == messageDate.year &&
        currentDate.month == messageDate.month &&
        currentDate.day - messageDate.day == 1) {
      // Yesterday
      return 'Yesterday';
    } else {
      // Return the date in the format 23/6/2024
      return DateFormat('dd/M/yyyy').format(time); // Format: 23/6/2024
    }
  }

  Future<void> uploadProfileImage() async {
    final picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        fileName = pickedImage.name;
        selectedImage = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userModel == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Loading...',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo[900],
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(isSearched ? Icons.close : Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          if (isSearched) _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: getUsersData,
              child: ListView.builder(
                itemCount: userslist.length,
                itemBuilder: (context, index) {
                  final theuser = userslist[index];
                  if (shouldShowUser(theuser)) {
                    return _buildUserListTile(theuser);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(5),
      margin: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: TextField(
        textInputAction: TextInputAction.search,
        onChanged: (value) => setState(() => searchText = value.trim()),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefixIcon: Icon(Icons.search, color: Colors.black.withOpacity(0.4)),
          hintText: 'Search name',
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
          contentPadding: const EdgeInsets.all(5),
        ),
      ),
    );
  }

  Widget _buildUserListTile(UserModel theuser) {
    final unreadCount = messageCountMap[theuser.userId] ?? 0;

    return Card(
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(5),
        leading: CircleAvatar(
          radius: 25,
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: theuser.profilePhotoUrl,
              placeholder: (context, url) =>
                  Image.asset('images/profileplaceholder.jpg'),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              fit: BoxFit.cover,
              width: 50,
              height: 50,
            ),
          ),
        ),
        title: Text(
          theuser.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onTap: () => _openChat(theuser),
        subtitle: _buildSubtitle(theuser),
        trailing: _buildTrailing(theuser, unreadCount),
      ),
    );
  }

  Widget _buildSubtitle(UserModel theuser) {
    if (theuser.lastmessage == null) return const SizedBox.shrink();

    return theuser.isImage
        ? Row(
            children: const [
              Icon(Icons.photo, color: Colors.black54),
              SizedBox(width: 5),
              Text('Photo', style: TextStyle(color: Colors.black54)),
            ],
          )
        : Text(
            theuser.lastmessage!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          );
  }

  Widget _buildTrailing(UserModel theuser, int unreadCount) {
    return SizedBox(
      width: 55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 9),
          Text(
            theuser.lastMessageTime != null
                ? _formatTime(theuser.lastMessageTime!)
                : '',
            style: TextStyle(
                color: unreadCount > 0 ? Colors.indigo : Colors.black),
          ),
          const SizedBox(height: 1),
          if (unreadCount > 0)
            CircleAvatar(
              radius: 11.5,
              backgroundColor: Colors.indigo[700],
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      isSearched = !isSearched;
      if (!isSearched) {
        searchText = '';
      }
    });
  }

  bool shouldShowUser(UserModel user) {
    return searchText.isEmpty ||
        user.name.toLowerCase().contains(searchText.toLowerCase());
  }

  Future<void> _openChat(UserModel theuser) async {
    _markMessagesAsRead(theuser.userId);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => IndividualChat(user: theuser)),
    );
    if (result != null && result is String) {
      _markMessagesAsRead(theuser.userId);
    }
    setState(() => messageCountMap[theuser.userId] = 0);
    _saveMessageCountMap();
    getUsersData();
  }
}
