import 'dart:io';

import 'package:first_chat_app/services/firebasestorage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class ChatBox extends StatefulWidget {
  ChatBox({super.key, required this.onSend, required this.controller});
  final TextEditingController controller;
  final Function(String) onSend;

  @override
  State<ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<ChatBox> {
  final FirebaseServices firebaseServices = FirebaseServices();
  bool isLoading = false; // Track loading state for image upload
  bool showEmojiPicker = false; //Track visibility of emoji picker

  // Function to handle image selection and upload
  Future<void> _sendImage() async {
    setState(() {
      isLoading = true;
    });
    final picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      String filename = pickedImage.name;
      File imageFile = File(pickedImage.path);

      try {
        // Upload image to Firebase Storage
        String? imageUrl = await firebaseServices.uploadPhoto(
          imageFile,
        );

        // If image upload successful, send message with image URL
        if (imageUrl != null) {
          widget.onSend(imageUrl);
        } else {
          print('Failed to upload image');
        }
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
    setState(() {
      isLoading = false; // Set loading state to false after upload
    });
  }

  // Function to toggle emoji picker visibility
  void toggleEmojiPicker() {
    setState(() {
      showEmojiPicker = !showEmojiPicker;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Show emoji picker if showEmojiPicker is true
        if (showEmojiPicker)
          EmojiPicker(
            // Add selected emoji to the message input
            onEmojiSelected: (category, emoji) {
              widget.controller.text += emoji.emoji;
            },
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Button to toggle emoji picker
                IconButton(
                  onPressed: toggleEmojiPicker,
                  icon: Icon(
                    Icons.emoji_emotions_outlined,
                    size: 30,
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    maxLines: null, //Allow text field to expand vertically
                    textAlignVertical:
                        TextAlignVertical.top, // Align text to the bottom
                    scrollPhysics: BouncingScrollPhysics(),
                    controller: widget.controller,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type message...',
                      hintStyle: TextStyle(color: Colors.black),
                    ),
                  ),
                ),

                // Button to pick and send an image
                IconButton(
                  onPressed: isLoading ? null : _sendImage,
                  icon: Icon(Icons.photo_library),
                ),
                IconButton(
                  onPressed: () async {
                    setState(() {
                      isLoading =
                          true; // Set loading state to true when sending message
                    });
                    await widget.onSend('');
                    setState(() {
                      isLoading =
                          false; // Set loading state to false after sending message
                    });
                  },
                  icon: isLoading
                      ? CircularProgressIndicator() // Show loading indicator when sending message
                      : Icon(
                          Icons.send,
                          color: Colors.indigo[900],
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
