import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/constants.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields first!"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20),
        ),
      );
      return;
    }

    setState(() { _isLoading = true; });
    try {
      final response = await http.post(
        Uri.parse(AppConstants.loginUrl),
        body: {
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
        },
      );

      final data = json.decode(response.body);

      if (data['status'] == "success")
      {
        final prefs = await SharedPreferences.getInstance();
        var userData = data['user'];

        // Extraction logic based on your specific database keys: first_name and last_name
        String fName = userData['first_name']?.toString() ?? "";
        String lName = userData['last_name']?.toString() ?? "";

        // Combine them for the UI
        String fullName = "$fName $lName".trim();
        if (fullName.isEmpty) fullName = "User";

        String emailToSave = userData['email']?.toString() ?? _emailController.text.trim();

        // Save to Local Storage
        await prefs.setString('full_name', fullName);
        await prefs.setString('email', emailToSave);

        if (!mounted) return;

        // Redirect to Home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Login failed"))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Server error. Please check your connection."))
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.auto_stories, size: 80, color: Colors.white),
              const Text("UniBook",
                  style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold)),
              const SizedBox(height: 50),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(60)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "University Email",
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: "Password",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3C72),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text("LOGIN",
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen()));
                        },
                        child: const Text("Don't have an account? Sign Up",
                            style: TextStyle(color: Colors.blueGrey)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}