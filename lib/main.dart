import 'package:flutter/material.dart';
import 'package:frontend_blog_posting/screens/login.dart';

void main() {
  runApp(BlogPostingApp());
}

class BlogPostingApp extends StatelessWidget {
  BlogPostingApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LoginPage(),
      // home: Dashboard(),
    );
  }
}

