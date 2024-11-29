import 'dart:convert';
import 'package:astro_app/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  _AdminUserScreenState createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  List<Map<String, dynamic>> users = [];
  List<bool> expandedStates = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final String apiUrl = '$backendBaseUrl/api/auth/userList';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> userData = jsonDecode(response.body);

        setState(() {
          users = userData.map<Map<String, dynamic>>((user) {
            return {
              'id': user['_id'],
              'name': user['name'],
              'profilePicture': user['profilePicture'],
              'email': user['email'],
              'contact': user['contact'],
              'country': user['country'],
              'dob': user['dob'],
              'gender': user['gender'],
              'role': user['role'], // Added role
            };
          }).toList();

          expandedStates = List<bool>.filled(users.length, false);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching users: $error');
    }
  }

  Future<void> updateUserRole(String id, String newRole) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final String apiUrl = '$backendBaseUrl/api/auth/updateRole';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'id': id,
      'role': newRole,
    });

    try {
      final response =
          await http.put(Uri.parse(apiUrl), headers: headers, body: body);

      if (response.statusCode == 200) {
        final updatedUser = jsonDecode(response.body);
        setState(() {
          // Update the role in the list of users
          final index = users.indexWhere((user) => user['id'] == id);
          if (index != -1) {
            users[index]['role'] = newRole;
          }
        });
        print('User role updated: $updatedUser');
      } else {
        throw Exception('Failed to update role');
      }
    } catch (error) {
      print('Error updating role: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(top: 50.0, left: 25, right: 25),
              child: Column(
                children: users.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> user = entry.value;

                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            expandedStates[index] = !expandedStates[index];
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.black, width: 1),
                                image: DecorationImage(
                                  image: NetworkImage('$backendBaseUrl/' +
                                      user['profilePicture']!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name']!,
                                  style: TextStyle(
                                    fontSize: 20,
                                  ),
                                ),
                                Text('Role: ${user['role']}'),
                                DropdownButton<String>(
                                  value: user['role'],
                                  onChanged: (String? newRole) {
                                    if (newRole != null) {
                                      updateUserRole(user['id'], newRole);
                                    }
                                  },
                                  items: <String>['user', 'admin']
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (expandedStates[index])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: ${user['email']}'),
                              Text('Contact: ${user['contact']}'),
                              Text('Country: ${user['country']}'),
                              Text('Date of Birth: ${user['dob']}'),
                              Text('Gender: ${user['gender']}'),
                            ],
                          ),
                        ),
                      SizedBox(height: 20),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }
}
