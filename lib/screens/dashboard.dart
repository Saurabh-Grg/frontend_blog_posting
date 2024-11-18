
import 'dart:convert';
import 'package:frontend_blog_posting/screens/update_blog.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _blogs = [];


  int _currentPage = 1;
  final int _blogsPerPage = 4;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _getBlogs(_currentPage);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  Future<void> _postBlog() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Token not found. Please log in again.")),
      );
      return;
    }

    String title = _titleController.text;
    String description = _descriptionController.text;

    final url = 'http://localhost:3000/api/blog/post';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'blog_title': title,
          'blog_description': description,
        }),
      );

      if (response.statusCode == 201) {
        _titleController.clear();
        _descriptionController.clear();
        // / Reload the blog list after posting
        setState(() {
          _currentPage = 1; // Start from page 1 after posting
          _hasMore = true; // Reset hasMore flag
        });
        _getBlogs(_currentPage);

        _getBlogs(_currentPage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Blog posted successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to post blog.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error posting blog.")),
      );
    }
  }

  Future<void> _getBlogs(int page) async {
    if (_isLoading || !_hasMore) return; // Prevent duplicate calls

    setState(() => _isLoading = true);
    print('Fetching more data for page $_currentPage...');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Token not found. Please log in again.")),
      );
      return;
    }

    final url =
        'http://127.0.0.1:3000/api/blog/all?page=$_currentPage&limit=$_blogsPerPage';
    print('page=$_currentPage&limit=$_blogsPerPage');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> blogs = jsonDecode(response.body);

        setState(() {
          // If the number of blogs returned is less than the page size, there are no more blogs to load
          if (blogs.length < _blogsPerPage) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No more blogs.'))
            );
            _hasMore = false; // No more blogs available
          }
          _blogs = blogs.map((blog) => blog as Map<String, dynamic>).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch blogs")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching blogs")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _goToNextPage() {
    if (_hasMore) {
      setState(() {
        _currentPage++;
      });
      _getBlogs(_currentPage);
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _getBlogs(_currentPage);
    }
  }


  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent) {
      _currentPage++;
      _getBlogs(_currentPage);
    }
  }

  Future<void> _deleteBlog(int blogId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Token not found. Please log in again.")),
      );
      return;
    }

    final url = 'http://localhost:3000/api/blog/$blogId';
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Reload the blog list after deleting
        setState(() {
          _currentPage = 1; // Start from page 1 after deleting
          _hasMore = true; // Reset hasMore flag
        });
        _getBlogs(_currentPage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Blog deleted successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete blog.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting blog.")),
      );
    }
  }

  void _navigateToUpdateBlog(int blogId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdateBlog(blogId: blogId)),
    );

    if (result == true) {
      // Reload blogs here
      _getBlogs(_currentPage);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Blog Posting App",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Text(
              'Blogs List',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                // controller: _scrollController,
                itemCount: _blogs.length + (_hasMore ? 1 : 0),
                // Add extra item for loader
                itemBuilder: (context, index) {
                  // Calculate the global index for the blog
                  final globalIndex = (_currentPage - 1) * _blogsPerPage + index;

                  if (index == _blogs.length && _hasMore) {
                    return Center(
                      child: SizedBox(
                        height: 50,
                        width: 50,
                        child: CircularProgressIndicator(),
                      ),
                    );// Show loader
                  }
                  final blog = _blogs[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${globalIndex + 1}')),
                      title: Text(blog['blog_title'], maxLines: 1,),
                      subtitle: Text(blog['blog_description'], maxLines: 1,),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.black),
                            onPressed: () => _navigateToUpdateBlog(blog['blog_id']),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.grey),
                            onPressed: () => _deleteBlog(blog['blog_id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left, color: Colors.black),
                  onPressed: _currentPage > 1
                      ? _goToPreviousPage
                      : null, // Disable Prev button when on the first page
                ),
                Text('$_currentPage'),
                IconButton(
                  icon: Icon(Icons.arrow_right, color: Colors.black),
                  onPressed: _hasMore
                      ? _goToNextPage
                      : null, // Disable Next button when there are no more blogs
                ),
              ],
            ),
            SizedBox(height: 15),
            Text(
              'Post a Blog',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: _postBlog,
              child: Text(
                'Post Blog',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
