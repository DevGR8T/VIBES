import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    Key? key,
    required this.message,
    required this.iscoming,
    required this.status,
    required this.time,
    required this.imageurl,
    this.onDisplayed,
    required this.isMe,
    required this.isRead,
  }) : super(key: key);

  final String message;
  final bool iscoming;
  final IconData status;
  final String time;
  final String imageurl;
  final bool isMe;
  final bool isRead;
  final VoidCallback? onDisplayed;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (onDisplayed != null) {
        onDisplayed!();
      }
    });

    return Padding(
      padding: iscoming
          ? const EdgeInsets.only(right: 10.0, left: 50.0)
          : const EdgeInsets.only(left: 10.0, right: 50.0),
      child: Column(
        crossAxisAlignment:
            iscoming ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: iscoming ? Colors.indigo[100] : Colors.grey[300],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  if (imageurl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: CachedNetworkImage(
                        imageUrl: imageurl,
                        fit: BoxFit.cover,
                        width: 200.0,
                        height: 200.0,
                        placeholder: (context, url) => SizedBox(
                          width: 200.0,
                          height: 200.0,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) =>
                            Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  if (imageurl.isNotEmpty && message.isNotEmpty)
                    SizedBox(height: 8.0),
                  if (message.isNotEmpty)
                    Text(
                      message,
                      style: TextStyle(
                        color: iscoming ? Colors.black : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(fontSize: 10, color: Colors.black),
                      ),
                      if (isMe) SizedBox(width: 4),
                      if (isMe)
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: isRead ? Colors.blue : Colors.grey[600],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 6),
        ],
      ),
    );
  }
}
