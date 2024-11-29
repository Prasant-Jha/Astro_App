import 'package:astro_app/config.dart';
import 'package:flutter/material.dart';
import 'dart:convert'; // For decoding JSON
import 'package:http/http.dart' as http; // For making HTTP requests
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalUsers = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTotalUsers();
  }

  Future<void> _fetchTotalUsers() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final String apiUrl = '$backendBaseUrl/api/auth/userCount';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _totalUsers = data['totalUsers'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load user count');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching total users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.brown, width: 4),
              ),
              child: Center(
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text(
                        '$_totalUsers',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Total Users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
