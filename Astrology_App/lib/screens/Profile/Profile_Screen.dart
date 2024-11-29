import 'dart:convert';
import 'package:astro_app/config.dart';
import 'package:astro_app/screens/Profile/EditProfileScreen.dart';
import 'package:astro_app/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;

  Future<void> fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      String? id = prefs.getString('id');
      try {
        final response = await http.get(
          Uri.parse('$backendBaseUrl/api/auth/profile/$id'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            userData = json.decode(response.body);
          });
        } else if (response.statusCode == 401) {
          // Token might be expired
          await _logout(context); // Logout if token is expired
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Failed to load profile: ${response.reasonPhrase}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('id'); // Remove user ID if necessary
    print(prefs.getString('token')); // Ensure it's removed

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully logged out')),
    );

    await Future.delayed(Duration(seconds: 1));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SignupPage(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        automaticallyImplyLeading: false,
        title: Text(
          "Profile",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _logout(context);
            },
          ),
        ],
        centerTitle: true,
      ),
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    userData!['profilePicture'] != null &&
                            userData!['profilePicture'] != ''
                        ? Image.network(
                            '$backendBaseUrl/' + userData!['profilePicture'],
                            height: 90,
                            width: 90,
                          )
                        : Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: Colors.grey,
                          ),
                    Text(
                      userData!['name'] ?? 'Unknown',
                      style: TextStyle(fontSize: 26),
                    ),
                    Text(
                      userData!['email'] ?? 'Unknown',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(height: 40),
                    buildProfileRow(
                        'Contact', userData!['contact'] ?? 'Unknown'),
                    buildProfileRow(
                        'Country', userData!['country'] ?? 'Unknown'),
                    buildProfileRow('DOB', userData!['dob'] ?? 'Unknown'),
                    buildProfileRow('Gender', userData!['gender'] ?? 'Unknown'),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (userData != null && userData!['id'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProfileScreen(id: userData!['id']),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('User ID not found')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding:
                            EdgeInsets.symmetric(horizontal: 110, vertical: 13),
                      ),
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildProfileRow(String label, String value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 18)),
            SizedBox(width: 200),
            Text(value, style: TextStyle(fontSize: 18)),
          ],
        ),
        Divider(color: Colors.grey, thickness: 1),
        SizedBox(height: 24),
      ],
    );
  }
}
