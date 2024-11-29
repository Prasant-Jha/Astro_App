import 'package:astro_app/config.dart';
import 'package:astro_app/screens/Admin_Screen.dart';
import 'package:astro_app/screens/HomePageContent.dart';
import 'package:astro_app/screens/News_Screen.dart';
import 'package:astro_app/screens/Profile/Profile_Screen.dart';
import 'package:flutter/material.dart';
import 'package:astro_app/utils/app_pictures.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? userData;
  int _selectedIndex = 0;

  final List<Widget> _baseWidgetOptions = <Widget>[
    HomePageContent(),
    NewsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<Map<String, dynamic>> fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      final response = await http.get(
        Uri.parse('$backendBaseUrl/api/auth/profile/:_id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load profile');
      }
    } else {
      throw Exception('No token found');
    }
  }

  // Method to get widget options including admin if the user is admin
  List<Widget> getWidgetOptions() {
    if (userData != null && userData!['role'] == 'admin') {
      return [..._baseWidgetOptions, AdminScreen()];
    }
    return _baseWidgetOptions;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
          // Set userData after fetching
          userData = snapshot.data;

          return Scaffold(
            appBar: _selectedIndex == 0
                ? AppBar(
                    backgroundColor: Colors.red,
                    toolbarHeight: 60,
                    automaticallyImplyLeading: false,
                    flexibleSpace: Padding(
                      padding: const EdgeInsets.only(left: 20, top: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            kundliImage,
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                userData != null
                                    ? userData!['name']
                                    : 'Loading...',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20),
                              ),
                              Text(
                                "What do you want to know",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
            body: getWidgetOptions()[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.newspaper_outlined),
                  label: 'News',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle),
                  label: 'Profile',
                ),
                // Conditionally add the Admin icon if the user is an admin
                if (userData != null && userData!['role'] == 'admin')
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.admin_panel_settings),
                    label: 'Admin',
                  ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.black45,
              iconSize: 30,
              selectedLabelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 13,
                color: Colors.black45,
              ),
              onTap: _onItemTapped,
            ),
          );
        }
      },
    );
  }
}
