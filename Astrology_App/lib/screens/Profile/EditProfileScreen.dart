// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:astro_app/config.dart';
import 'package:astro_app/screens/HomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert'; // To decode JSON responses
import 'package:intl/intl.dart'; // For formatting date
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class EditProfileScreen extends StatefulWidget {
  final String id;

  const EditProfileScreen({super.key, required this.id});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  String selectedGender = 'Other';

  File? _pickedImage;

  void _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
        _imageController.text = path.basename(_pickedImage!.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        print("No token found, please log in again.");
        return;
      }

      var response = await http.get(
        Uri.parse('$backendBaseUrl/api/auth/profile/${widget.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        var profileData = jsonDecode(response.body);

        setState(() {
          nameController.text = profileData['name'];
          contactController.text = profileData['contact'];
          countryController.text = profileData['country'];
          dobController.text = profileData['dob'];
          selectedGender = profileData['gender'];
        });
      } else {
        print("Failed to load profile: ${response.statusCode}");
      }
    } catch (e) {
      print("Error occurred while fetching profile: $e");
    }
  }

  Future<void> _selectDOB() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _saveChanges() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        print("No token found, please log in again.");
        return;
      }

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$backendBaseUrl/api/auth/update/${widget.id}'),
      );

      // Set authorization header with the token
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'application/json';

      request.fields['name'] = nameController.text;
      request.fields['contact'] = contactController.text;
      request.fields['country'] = countryController.text;
      request.fields['dob'] = dobController.text;
      request.fields['gender'] = selectedGender;

      if (_pickedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'profilePicture',
          _pickedImage!.path,
        ));
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var result = String.fromCharCodes(responseData);
        print("Profile updated successfully: $result");
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => HomePage()));
      } else {
        print("Error updating profile: ${response.statusCode}");
      }
    } catch (e) {
      print("Error occurred while updating profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 15),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        _pickedImage != null ? FileImage(_pickedImage!) : null,
                    child: _pickedImage == null
                        ? Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Full Name',
                style: TextStyle(fontSize: 22),
              ),
              SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  suffixIcon: Icon(Icons.person),
                  border: UnderlineInputBorder(),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Contact',
                style: TextStyle(fontSize: 22),
              ),
              SizedBox(height: 8),
              TextField(
                controller: contactController,
                decoration: InputDecoration(
                  suffixIcon: Icon(Icons.call),
                  border: UnderlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 24),
              Text(
                'Country',
                style: TextStyle(fontSize: 22),
              ),
              SizedBox(height: 8),
              TextField(
                controller: countryController,
                decoration: InputDecoration(
                  suffixIcon: Icon(Icons.location_city),
                  border: UnderlineInputBorder(),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'DOB',
                style: TextStyle(fontSize: 22),
              ),
              SizedBox(height: 8),
              TextField(
                controller: dobController,
                readOnly: true,
                onTap: _selectDOB,
                decoration: InputDecoration(
                  suffixIcon: Icon(Icons.date_range),
                  border: UnderlineInputBorder(),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Gender',
                style: TextStyle(fontSize: 22),
              ),
              Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Male'),
                    value: 'Male',
                    groupValue: selectedGender,
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Female'),
                    value: 'Female',
                    groupValue: selectedGender,
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Other'),
                    value: 'Other',
                    groupValue: selectedGender,
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value!;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding:
                        EdgeInsets.symmetric(horizontal: 110, vertical: 13),
                  ),
                  child: Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
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
