import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jewellery_admin/admin_home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    const url = 'https://jewellery-backend-icja.onrender.com/api/auth/login';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final String token = data['token'];
        await _saveToken(token);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Successful!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomePage()),
        );
      } else {
        final message = data['message'] ?? 'Login failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F1),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 100, vertical: 40),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8D99A)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Logo
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8952A),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB8952A).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: const Icon(Icons.diamond,
                        color: Colors.white, size: 34),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Jewellery Admin',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Sign in to continue',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor: const Color(0xFFF4F2EC),
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                    value == null || value.isEmpty
                        ? 'Enter your email'
                        : null,
                  ),

                  const SizedBox(height: 20),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: const Color(0xFFF4F2EC),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                    value == null || value.length < 6
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),

                  const SizedBox(height: 30),

                  _isLoading
                      ? const CircularProgressIndicator(
                      color: Color(0xFFB8952A))
                      : SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFFB8952A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'LOGIN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    '© 2026 Jewellery Admin',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}