import 'package:flutter/material.dart';
import 'package:movie_reviews/widgets/custom_loading.dart';

import '../api_service.dart';
import 'movie_reviews_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();

  void _login() async {
    // Show loading
    CustomLoading.show();

    final success = await _apiService.loginUser(
      _usernameController.text,
      _passwordController.text,
    );

    if (success) {
      // Dismiss loading
      CustomLoading.dismiss();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MovieReviewsScreen(username: _usernameController.text),
        ),
      );
    } else {
      // Dismiss loading
      CustomLoading.dismiss();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Login gagal. Silakan cek username/password.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              ),
              child: const Text('Belum punya akun? Daftar di sini.'),
            ),
          ],
        ),
      ),
    );
  }
}
