import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatDetailScreen extends StatefulWidget {
  final String userName;
  final String chatRoomId; // We add this to identify the specific conversation

  const ChatDetailScreen({
    super.key,
    required this.userName,
    required this.chatRoomId
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? myEmail;

  @override
  void initState() {
    super.initState();
    _getMyEmail();
  }

  // We need to know who "Me" is to align bubbles correctly
  _getMyEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myEmail = prefs.getString('email');
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || myEmail == null) return;

    // Send to Firestore
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add({
      "text": _messageController.text.trim(),
      "sender": myEmail,
      "timestamp": FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              // STREAM: This listens to Firestore in real-time
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true) // Newest at bottom
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Start from bottom
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    bool isMe = docs[index]['sender'] == myEmail;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF1E3C72) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          docs[index]['text'],
                          style: TextStyle(color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF1E3C72)),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}