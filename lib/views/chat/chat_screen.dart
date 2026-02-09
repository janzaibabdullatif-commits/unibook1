import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  // Helper function to create a consistent Chat Room ID
  String getChatRoomId(String userA, String userB) {
    List<String> users = [userA, userB];
    users.sort(); // Sorting ensures the ID is always the same regardless of who opens it
    return "${users[0]}_${users[1]}".toLowerCase().replaceAll(" ", "_");
  }

  @override
  Widget build(BuildContext context) {
    // Current user's name (In a real app, you'd get this from SharedPreferences)
    const String myName = "Huzaifa Khan";

    final List<Map<String, String>> chats = [
      {"name": "Ali Khan", "msg": "Hey, did you finish the assignment?", "time": "2:30 PM"},
      {"name": "Sarah Ahmed", "msg": "Let's meet at the library.", "time": "1:15 PM"},
      {"name": "Professor Usman", "msg": "Please check the portal for updates.", "time": "Yesterday"},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView.separated(
        itemCount: chats.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
        itemBuilder: (context, index) {
          String otherUser = chats[index]['name']!;

          return ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF1E3C72),
              child: Text(
                  otherUser[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
            title: Text(
                otherUser,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            subtitle: Text(
              chats[index]['msg']!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    chats[index]['time']!,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)
                ),
                const SizedBox(height: 5),
                const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
              ],
            ),
            onTap: () {
              // Generate the Firebase Room ID
              String roomId = getChatRoomId(myName, otherUser);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(
                    userName: otherUser,
                    chatRoomId: roomId,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}