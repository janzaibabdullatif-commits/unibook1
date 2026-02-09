import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../profile/profile_screen.dart';
import '../chat/chat_screen.dart';
import '../friends/friends_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const Color unibookBlue = Color(0xFF1E3C72);
  int _selectedIndex = 0;

  List<dynamic> posts = [];
  bool isLoading = true;
  bool isSubmitting = false;

  String loggedInUserName = "Student";
  String loggedInUserEmail = "";
  String loggedInUserUni = "";

  Timer? _notificationTimer;
  File? _selectedMedia;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInUserName = prefs.getString('full_name') ?? "Student";
      loggedInUserEmail = prefs.getString('email') ?? "";
      loggedInUserUni = prefs.getString('university') ?? "";
    });
    await fetchPosts(showLoader: true);
    if (loggedInUserEmail.isNotEmpty) {
      _startNotificationListener();
    }
  }

  Future<void> _pickImage(StateSetter setModalState) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        var bytes = await image.readAsBytes();
        setModalState(() {
          _webImage = bytes;
          _selectedMedia = File(image.path);
        });
      } else {
        setModalState(() {
          _selectedMedia = File(image.path);
        });
      }
    }
  }

  void _startNotificationListener() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (loggedInUserEmail.isEmpty) return;
      try {
        final response = await http.get(
          Uri.parse("https://trendosky.com/unibook_api/check_notifications.php?email=$loggedInUserEmail"),
        );
        if (response.statusCode == 200) {
          List newNotes = json.decode(response.body);
          for (var note in newNotes) {
            _showNotificationPopup(note['message']);
          }
        }
      } catch (e) {
        debugPrint("Notification error: $e");
      }
    });
  }

  void _showNotificationPopup(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orangeAccent, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> fetchPosts({bool showLoader = false}) async {
    if (!mounted) return;
    if (showLoader) setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(
          "https://trendosky.com/unibook_api/get_posts.php?user_email=$loggedInUserEmail"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            posts = data['data'] ?? [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- DELETE POST FUNCTION ---
  Future<void> _deletePost(String postId) async {
    try {
      final response = await http.post(
        Uri.parse("https://trendosky.com/unibook_api/delete_post.php"),
        body: {"post_id": postId, "user_email": loggedInUserEmail},
      );
      if (response.statusCode == 200) {
        fetchPosts(showLoader: false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post deleted successfully")));
      }
    } catch (e) { debugPrint("Delete Post Error: $e"); }
  }

  // --- DELETE COMMENT FUNCTION ---
  Future<void> _deleteComment(String commentId, StateSetter setModalState) async {
    try {
      final response = await http.post(
        Uri.parse("https://trendosky.com/unibook_api/delete_comment.php"),
        body: {"comment_id": commentId, "user_name": loggedInUserName},
      );
      if (response.statusCode == 200) {
        setModalState(() {}); // Triggers the FutureBuilder inside the modal to reload
        fetchPosts(showLoader: false);
      }
    } catch (e) { debugPrint("Delete Comment Error: $e"); }
  }

  Future<void> _toggleLike(String postId) async {
    int index = posts.indexWhere((p) => p['id'].toString() == postId);
    if (index != -1) {
      setState(() {
        bool isAlreadyLiked = (posts[index]['is_liked'].toString() == "1");
        int currentLikes = int.tryParse(posts[index]['likes_count'].toString()) ?? 0;
        posts[index]['is_liked'] = isAlreadyLiked ? "0" : "1";
        posts[index]['likes_count'] = isAlreadyLiked ? (currentLikes - 1) : (currentLikes + 1);
      });
    }
    try {
      await http.post(
        Uri.parse("https://trendosky.com/unibook_api/toggle_like.php"),
        body: {"post_id": postId, "user_email": loggedInUserEmail},
      );
      fetchPosts(showLoader: false);
    } catch (e) { debugPrint(e.toString()); }
  }

  void _showCommentDialog(String postId) {
    TextEditingController commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const Padding(padding: EdgeInsets.all(15), child: Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
              const Divider(),
              Expanded(
                child: FutureBuilder(
                  future: http.get(Uri.parse("https://trendosky.com/unibook_api/get_comments.php?post_id=$postId")),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final data = json.decode(snapshot.data!.body);
                    List comments = data['data'] ?? [];
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        // Check if I am the owner of this comment
                        bool isMyComment = comments[index]['user_name'] == loggedInUserName;
                        return ListTile(
                          leading: CircleAvatar(child: Text(comments[index]['user_name'][0].toUpperCase())),
                          title: Text(comments[index]['user_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(comments[index]['comment_text']),
                          trailing: isMyComment
                              ? IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            onPressed: () => _deleteComment(comments[index]['id'].toString(), setModalState),
                          )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(child: TextField(controller: commentController, decoration: InputDecoration(hintText: "Add a comment...", filled: true, fillColor: const Color(0xFFF0F2F5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none)))),
                    IconButton(icon: const Icon(Icons.send, color: unibookBlue), onPressed: () async {
                      if (commentController.text.trim().isEmpty) return;
                      await http.post(Uri.parse("https://trendosky.com/unibook_api/add_comment.php"), body: {"post_id": postId, "user_name": loggedInUserName, "comment_text": commentController.text});
                      commentController.clear();
                      setModalState(() {});
                      fetchPosts(showLoader: false);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 2) { _showCreatePostModal(); }
    else { setState(() => _selectedIndex = index); }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [ _buildHomeFeed(), const FriendsScreen(), const SizedBox(), const ChatScreen(), const SettingsScreen() ];
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0.5, title: const Text("unibook", style: TextStyle(color: unibookBlue, fontSize: 26, fontWeight: FontWeight.bold))),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: unibookBlue,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          const BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: "Friends"),
          BottomNavigationBarItem(icon: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: unibookBlue, shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white)), label: "Create"),
          const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Chat"),
          const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Settings"),
        ],
      ),
    );
  }

  Widget _buildHomeFeed() {
    return RefreshIndicator(
      onRefresh: () => fetchPosts(showLoader: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchHeader(),
            const Padding(padding: EdgeInsets.only(left: 16, top: 15, bottom: 8), child: Text("Story", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            _buildStoryList(),
            const SizedBox(height: 10),
            isLoading
                ? const Padding(padding: EdgeInsets.only(top: 100), child: Center(child: BookLoadingIndicator()))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) => _buildPostCard(posts[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userName: loggedInUserName, userEmail: loggedInUserEmail))),
            child: CircleAvatar(backgroundColor: unibookBlue, child: Text(loggedInUserName[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _showCreatePostModal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey.shade300)),
                child: Text("What's on your mind, $loggedInUserName?", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryList() {
    return SizedBox(height: 140, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), itemCount: 6, itemBuilder: (context, index) => _buildStoryItem(index == 0)));
  }

  Widget _buildStoryItem(bool isAdd) {
    return Container(width: 90, margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: isAdd ? Column(children: [Expanded(child: Container(decoration: BoxDecoration(color: unibookBlue.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(15))), child: const Icon(Icons.add, color: unibookBlue))), const Padding(padding: EdgeInsets.all(6), child: Text("Add Story", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))]) : const Center(child: Icon(Icons.person, color: Colors.grey)));
  }

  Widget _buildPostCard(dynamic post) {
    String postId = post['id'].toString();
    bool isLiked = (post['is_liked'].toString() == "1");
    // Only show delete menu if I created the post
    bool isMyPost = post['user_email'] == loggedInUserEmail;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(backgroundColor: unibookBlue, child: Text(post['user_name'][0].toUpperCase(), style: const TextStyle(color: Colors.white))),
            title: Text(post['user_name'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(post['university'] ?? "University"),
            trailing: isMyPost
                ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') _deletePost(postId);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 10), Text("Delete Post", style: TextStyle(color: Colors.red))]))
              ],
            )
                : null,
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text(post['content'] ?? "", style: const TextStyle(fontSize: 15))),

          if (post['media_url'] != null && post['media_url'] != "")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post['media_url'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.grey[200],
                      child: const Column(
                        children: [
                          Icon(Icons.broken_image, color: Colors.grey),
                          Text("Image could not be loaded", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),

          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionItem(isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, "${post['likes_count'] ?? 0} Like", () => _toggleLike(postId), iconColor: isLiked ? unibookBlue : Colors.grey),
              _actionItem(Icons.chat_bubble_outline, "${post['comments_count'] ?? 0} Comment", () => _showCommentDialog(postId)),
              _actionItem(Icons.share_outlined, "Share", () => Share.share("Check out this post: ${post['content']}")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionItem(IconData icon, String label, VoidCallback onTap, {Color iconColor = Colors.grey}) {
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [Icon(icon, size: 20, color: iconColor), const SizedBox(width: 5), Text(label, style: TextStyle(color: iconColor))])));
  }

  void _showCreatePostModal() {
    TextEditingController postController = TextEditingController();
    _selectedMedia = null;
    _webImage = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Post as $loggedInUserName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: unibookBlue)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              TextField(controller: postController, maxLines: 3, decoration: const InputDecoration(hintText: "What's on your mind?", border: InputBorder.none)),

              if (_selectedMedia != null || _webImage != null)
                Stack(
                  children: [
                    Container(
                        height: 150,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: kIsWeb
                                ? Image.memory(_webImage!, fit: BoxFit.cover)
                                : Image.file(_selectedMedia!, fit: BoxFit.cover)
                        )
                    ),
                    Positioned(right: 5, top: 5, child: GestureDetector(onTap: () => setModalState(() { _selectedMedia = null; _webImage = null; }), child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 15, color: Colors.white)))),
                  ],
                ),

              Row(
                children: [
                  IconButton(icon: const Icon(Icons.photo_library, color: Colors.green), onPressed: () => _pickImage(setModalState)),
                  const Text("Add Photo", style: TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: unibookBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: isSubmitting ? null : () async {
                    setModalState(() => isSubmitting = true);
                    await _handlePostSubmission(postController.text);
                    if (mounted) setModalState(() => isSubmitting = false);
                  },
                  child: isSubmitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("POST", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePostSubmission(String content) async {
    if (content.trim().isEmpty && _selectedMedia == null && _webImage == null) return;
    try {
      var request = http.MultipartRequest('POST', Uri.parse("https://trendosky.com/unibook_api/create_post.php"));
      request.fields['user_name'] = loggedInUserName;
      request.fields['user_email'] = loggedInUserEmail; // Ownership identifier
      request.fields['university'] = loggedInUserUni;
      request.fields['content'] = content;

      if (kIsWeb && _webImage != null) {
        request.files.add(http.MultipartFile.fromBytes('media', _webImage!, filename: 'upload.jpg'));
      } else if (_selectedMedia != null) {
        request.files.add(await http.MultipartFile.fromPath('media', _selectedMedia!.path));
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        Navigator.pop(context);
        fetchPosts(showLoader: true);
      }
    } catch (e) { debugPrint("Post error: $e"); }
  }
}

class BookLoadingIndicator extends StatefulWidget {
  const BookLoadingIndicator({super.key});
  @override
  _BookLoadingIndicatorState createState() => _BookLoadingIndicatorState();
}

class _BookLoadingIndicatorState extends State<BookLoadingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(height: 60, width: 80, child: Stack(alignment: Alignment.center, children: [ _buildPage(), AnimatedBuilder(animation: _controller, builder: (context, child) => Transform(alignment: Alignment.centerLeft, transform: Matrix4.identity()..setEntry(3, 2, 0.0015)..rotateY(-_controller.value * 3.14159), child: _buildPage())), ])),
      const SizedBox(height: 10),
      const Text("LOADING UNIBOOK", style: TextStyle(letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72))),
    ]);
  }
  Widget _buildPage() => Container(width: 35, height: 50, decoration: BoxDecoration(color: const Color(0xFF1E3C72), borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)), border: Border.all(color: Colors.white24)));
}