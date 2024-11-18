
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend_blog_posting/screens/dashboard.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Function to handle login API call
  Future<void> _submitLoginForm() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Get the username and password values
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    // Set the URL of your API endpoint
    final url = 'http://localhost:3000/api/auth/login';

    try {
      // Make POST request to login API
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];

        // Store the token in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        // On successful login, navigate to the Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );
      } else {
        // Show error message if login fails
        final responseBody = jsonDecode(response.body);
        setState(() {
          _errorMessage = responseBody['message'] ?? 'Login failed, try again!';
        });
      }
    } catch (e) {
      // Handle error (e.g., network error)
      setState(() {
        _errorMessage = 'Something went wrong. Please try again later.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Login',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Enter username',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,  // Hide the password text
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            if (_isLoading)
              CircularProgressIndicator()  // Show loading indicator
            else
              ElevatedButton(
                onPressed: _submitLoginForm,
                child: Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                ),
              ),
            SizedBox(height: 10),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
