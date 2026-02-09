import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color unibookBlue = Color(0xFF1E3C72);

  String displayName = "Loading...";
  String displayEmail = "";
  bool isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // We get the combined name "Huzaifa Khan" saved by the Login screen
    String? savedName = prefs.getString('full_name');
    String? savedEmail = prefs.getString('email');

    setState(() {
      // Logic: If memory has a name, use it. If not, use the passed name.
      // If both fail, show "User".
      displayName = (savedName != null && savedName.isNotEmpty)
          ? savedName
          : (widget.userName.isNotEmpty ? widget.userName : "User");

      displayEmail = (savedEmail != null && savedEmail.isNotEmpty)
          ? savedEmail
          : (widget.userEmail.isNotEmpty ? widget.userEmail : "No Email");

      isDataLoaded = true;
    });
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Important: Clears the session completely

    if (!mounted) return;

    // Direct move to Login
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isDataLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: unibookBlue)),
      );
    }

    // This dynamically gets "H" from "Huzaifa Khan"
    String firstLetter = (displayName.isNotEmpty && displayName != "User")
        ? displayName[0].toUpperCase()
        : "U";

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Profile",
            style: TextStyle(color: unibookBlue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: unibookBlue),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(firstLetter),
            const SizedBox(height: 60),
            Text(
              displayName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              displayEmail,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 30),
            _buildTile(Icons.article_outlined, "My Posts", onTap: () {}),
            _buildTile(Icons.settings_outlined, "Settings", onTap: () {}),
            const Divider(),
            _buildTile(
                Icons.logout,
                "Logout",
                isLogout: true,
                onTap: _handleLogout
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String letter) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [unibookBlue, Color(0xFF2A5298)]),
          ),
        ),
        Positioned(
          top: 100,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 46,
              backgroundColor: unibookBlue,
              child: Text(
                letter,
                style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, {required VoidCallback onTap, bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : unibookBlue),
      title: Text(title, style: TextStyle(color: isLogout ? Colors.red : Colors.black)),
      trailing: isLogout ? null : const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}