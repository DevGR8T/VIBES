import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String userId;
  String name;
  String about;
  String email;
  String profilePhotoUrl;
  String? lastmessage; //Last message text
  DateTime? lastMessageTime; // New field for last message time
  bool isImage; // Indicates if the last message is an image
  int unreadMessageCount;
  bool isChatPageOpen = false;

  UserModel({
    required this.userId,
    required this.name,
    required this.about,
    required this.email,
    required this.profilePhotoUrl,
    this.lastmessage,
    this.lastMessageTime,
    this.isImage = false, // Initialize isImage to false
    this.unreadMessageCount = 0,
    this.isChatPageOpen = false, // Initialize isChatPageOpen to false
  });

  factory UserModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      name: data['name'] ?? '',
      about: data['about'] ?? '',
      email: data['email'] ?? '',
      profilePhotoUrl: data['profilephotourl'] ?? '',
      isChatPageOpen: false, // Initialize isChatPageOpen to false
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'about': about,
      'email': email,
      'profilephotourl': profilePhotoUrl,
    };
  }
}
