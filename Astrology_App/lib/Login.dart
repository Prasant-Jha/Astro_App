import 'package:astro_app/config.dart';
import 'package:astro_app/screens/HomeScreen.dart';
import 'package:astro_app/screens/Profile/OTPResetScreen.dart';
import 'package:flutter/material.dart';
import 'package:astro_app/utils/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKeyLogin = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _isAgreeTermsLogin = false;
  bool _isPasswordVisibleLogin = false;

  final RegExp _emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  final RegExp _passwordRegExp = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKeyLogin.currentState?.validate() ?? false) {
      final url = Uri.parse('$backendBaseUrl/api/auth/login');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _loginEmailController.text.trim(),
            'password': _loginPasswordController.text,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          print('Login successful, token: ${data['token']}');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          final errorData = jsonDecode(response.body);
          print('Login failed: ${errorData['message']}');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${errorData['message']}')),
          );
        }
      } catch (error) {
        print('Error occurred: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 0.0),
        child: Form(
          key: _formKeyLogin,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24),
              Text(
                'Email',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _loginEmailController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!_emailRegExp.hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 25),
              Text('Password',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              TextFormField(
                controller: _loginPasswordController,
                obscureText: !_isPasswordVisibleLogin,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisibleLogin
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisibleLogin = !_isPasswordVisibleLogin;
                      });
                    },
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (!_passwordRegExp.hasMatch(value)) {
                    return 'Password must be at least 8 characters long, include an uppercase letter, a lowercase letter, a number, and a special character';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: _isAgreeTermsLogin,
                    onChanged: (bool? value) {
                      setState(() {
                        _isAgreeTermsLogin = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Remember me',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OTPResetScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(fontSize: 14, color: PrimaryColor),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKeyLogin.currentState?.validate() ?? false) {
                      if (_isAgreeTermsLogin) {
                        _login();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('You must agree with the terms'),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(fontSize: 18),
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
