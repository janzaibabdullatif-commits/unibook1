import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Color unibookBlue = const Color(0xFF1E3C72);
  bool isDarkMode = false;
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildSectionHeader("Account"),
          _buildSettingsTile(Icons.person_outline, "Edit Profile", () {}),
          _buildSettingsTile(Icons.lock_outline, "Security & Password", () {}),
          _buildSettingsTile(Icons.verified_user_outlined, "Privacy Center", () {}),

          const Divider(),
          _buildSectionHeader("Preferences"),
          _buildSwitchTile(Icons.notifications_none, "Notifications", notificationsEnabled, (val) {
            setState(() => notificationsEnabled = val);
          }),
          _buildSwitchTile(Icons.dark_mode_outlined, "Dark Mode", isDarkMode, (val) {
            setState(() => isDarkMode = val);
          }),
          _buildSettingsTile(Icons.language, "Language", () {}),

          const Divider(),
          _buildSectionHeader("Support"),
          _buildSettingsTile(Icons.help_outline, "Help Center", () {}),
          _buildSettingsTile(Icons.info_outline, "About unibook", () {}),

          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _showLogoutDialog,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text("Logout", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: unibookBlue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
      tileColor: Colors.white,
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      secondary: Icon(icon, color: unibookBlue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      value: value,
      onChanged: onChanged,
      activeColor: unibookBlue,
      tileColor: Colors.white,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to sign out of unibook?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Clear user session
              // Navigate to login screen and clear stack
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}