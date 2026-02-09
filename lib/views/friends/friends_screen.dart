import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final Color unibookBlue = const Color(0xFF1E3C72);
  String? myEmail;
  String? myName; // Added to send your name in notifications
  List allUsers = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myEmail = prefs.getString('email');
      myName = prefs.getString('full_name') ?? "Someone";
    });

    if (myEmail != null && myEmail!.isNotEmpty) {
      _fetchUsersFromMySQL("");
    } else {
      debugPrint("Error: No email found in SharedPreferences.");
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchUsersFromMySQL(String query) async {
    if (myEmail == null) return;
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("https://trendosky.com/unibook_api/search_students.php"),
        body: {
          "myEmail": myEmail,
          "search": query,
        },
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        setState(() {
          allUsers = (decodedData is List) ? decodedData : [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => isLoading = false);
    }
  }

  // --- UPDATED SEND REQUEST (FIREBASE + DOMAIN NOTIFICATION) ---
  void _sendRequest(String targetEmail) async {
    if (myEmail == null) return;

    // 1. Firebase Logic
    FirebaseFirestore.instance.collection('friend_requests').add({
      'sender': myEmail,
      'receiver': targetEmail,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Domain Notification Logic (New)
    try {
      await http.post(
        Uri.parse("https://trendosky.com/unibook_api/send_notification.php"),
        body: {
          "receiver_email": targetEmail,
          "sender_name": myName,
        },
      );
    } catch (e) {
      debugPrint("Notification Error: $e");
    }

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Friend Request Sent!"))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("UniBook Community",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: unibookBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: unibookBlue,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _fetchUsersFromMySQL(value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search by Name or Roll Number...",
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: () => _fetchUsersFromMySQL(_searchController.text),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIncomingRequests(),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text("All Students",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    allUsers.isEmpty
                        ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text("No students found.")),
                    )
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allUsers.length,
                      itemBuilder: (context, index) {
                        return _buildUserListItem(allUsers[index]);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friend_requests')
          .where('receiver', isEqualTo: myEmail)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Pending Requests",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            ),
            ...snapshot.data!.docs.map((doc) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(doc['sender'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Sent you a request"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _handleRequest(doc.id, 'accepted')),
                    IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _handleRequest(doc.id, 'rejected')),
                  ],
                ),
              ),
            )),
            const Divider(thickness: 1, indent: 15, endIndent: 15),
          ],
        );
      },
    );
  }

  Widget _buildUserListItem(Map user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friend_requests')
          .where('sender', isEqualTo: myEmail)
          .where('receiver', isEqualTo: user['email'])
          .snapshots(),
      builder: (context, snapshot) {
        bool requestSent = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        String status = requestSent ? snapshot.data!.docs.first['status'] : "none";
        String docId = requestSent ? snapshot.data!.docs.first.id : "";

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]
          ),
          child: ListTile(
            leading: CircleAvatar(
                backgroundColor: unibookBlue,
                child: Text(
                    (user['name'] != null && user['name'].isNotEmpty)
                        ? user['name'][0].toUpperCase()
                        : "U",
                    style: const TextStyle(color: Colors.white)
                )
            ),
            title: Text(user['name'] ?? "Unknown User", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Roll: ${user['roll_no'] ?? 'N/A'}"),
            trailing: _buildButton(status, user['email'], docId),
          ),
        );
      },
    );
  }

  Widget _buildButton(String status, String targetEmail, String docId) {
    if (status == "accepted") {
      return const Chip(label: Text("Friends", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)));
    } else if (status == "pending") {
      return TextButton(
        onPressed: () => FirebaseFirestore.instance.collection('friend_requests').doc(docId).delete(),
        child: const Text("Cancel", style: TextStyle(color: Colors.red)),
      );
    } else {
      return ElevatedButton(
        onPressed: () => _sendRequest(targetEmail),
        style: ElevatedButton.styleFrom(backgroundColor: unibookBlue),
        child: const Text("Add Friend", style: TextStyle(color: Colors.white)),
      );
    }
  }

  void _handleRequest(String docId, String newStatus) {
    if (newStatus == 'accepted') {
      FirebaseFirestore.instance.collection('friend_requests').doc(docId).update({'status': 'accepted'});
    } else {
      FirebaseFirestore.instance.collection('friend_requests').doc(docId).delete();
    }
  }
}