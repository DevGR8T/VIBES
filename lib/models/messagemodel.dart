import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String message;
  final String senderName;
  final String readStatus;
  final String imageUrl;
  final String videoUrl;
  final String audioUrl;
  final String content;
  final String senderId;
  final String receiverId;
  final String documentUrl;
  final List<String> reactions;
  final List<dynamic> replies;
  final Timestamp timestamp;

  MessageModel({
    required this.id,
    required this.message,
    required this.senderName,
    required this.readStatus,
    required this.imageUrl,
    required this.videoUrl,
    required this.audioUrl,
    required this.content,
    required this.senderId,
    required this.receiverId,
    required this.documentUrl,
    required this.reactions,
    required this.replies,
    required this.timestamp,
  });

  factory MessageModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      message: data['message'] ?? '',
      senderName: data['senderName'] ?? '',
      readStatus: data['readStatus'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
      content: data['content'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      documentUrl: data['documentUrl'] ?? '',
      reactions: List<String>.from(data['reactions'] ?? []),
      replies: List<dynamic>.from(data['replies'] ?? []),
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'senderName': senderName,
      'readStatus': readStatus,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'content': content,
      'senderId': senderId,
      'receiverId': receiverId,
      'documentUrl': documentUrl,
      'reactions': reactions,
      'replies': replies,
      'timestamp': timestamp,
    };
  }
}
