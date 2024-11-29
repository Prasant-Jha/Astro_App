import 'dart:io';
import 'package:astro_app/config.dart';
import 'package:astro_app/screens/HomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  _AdminNewsScreenState createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedDate;
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate != null
          ? DateTime.parse(_selectedDate!)
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _selectedDate = picked.toIso8601String().split('T')[0];
        _dateController.text = _selectedDate!;
      });
    }
  }

  Future<void> _submitNews() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final uri = Uri.parse('$backendBaseUrl/api/news/create');

      var request = http.MultipartRequest('POST', uri)
        ..fields['title'] = _titleController.text
        ..fields['date'] = _dateController.text
        ..fields['description'] = _descriptionController.text;

      request.headers['Authorization'] = 'Bearer $token';

      if (_pickedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _pickedImage!.path,
        ));
      }

      try {
        var response = await request.send();
        final responseBody = await http.Response.fromStream(response);

        print('Response status: ${response.statusCode}');
        print('Response body: ${responseBody.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const HomePage()));
        } else {
          print('Failed to add news: ${responseBody.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add news: ${responseBody.body}')),
          );
        }
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Title", style: TextStyle(fontSize: 22)),
                SizedBox(height: 5),
                TextFormField(
                  controller: _titleController,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a title' : null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  ),
                ),
                SizedBox(height: 15),
                Text("Date", style: TextStyle(fontSize: 22)),
                SizedBox(height: 5),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  ),
                ),
                SizedBox(height: 15),
                Text("Image", style: TextStyle(fontSize: 22)),
                SizedBox(height: 5),
                TextFormField(
                  controller: _imageController,
                  readOnly: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.image),
                      onPressed: _pickImage,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  ),
                ),
                SizedBox(height: 15),
                Text("Description", style: TextStyle(fontSize: 22)),
                SizedBox(height: 5),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a description' : null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Write here..',
                  ),
                ),
                SizedBox(height: 25),
                SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 120),
                    child: ElevatedButton(
                      onPressed: _submitNews,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 60),
                      ),
                      child: Text(
                        "Add",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
