// ignore_for_file: prefer_const_constructors

import 'package:astro_app/config.dart';
import 'package:flutter/material.dart';
import 'package:astro_app/screens/Profile/PasswordResetScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;

  OTPVerificationScreen({required this.email});

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController otpController1 = TextEditingController();
  final TextEditingController otpController2 = TextEditingController();
  final TextEditingController otpController3 = TextEditingController();
  final TextEditingController otpController4 = TextEditingController();

  Future<void> verifyOtp() async {
    String otp = otpController1.text +
        otpController2.text +
        otpController3.text +
        otpController4.text;

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    // Call your backend API to verify the OTP
    final response = await http.post(
      Uri.parse('$backendBaseUrl/api/auth/verify-otp'),
      body: json.encode({'email': widget.email, 'otp': otp}),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
    );

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PasswordResetScreen(email: widget.email),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(
          "Verify",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "OTP",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20),
              CircleAvatar(
                radius: 60,
                backgroundImage:
                    AssetImage('assets/images/VerificationCode.png'),
              ),
              SizedBox(height: 20),
              Text(
                "Verification Code",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "We have sent a verification code to your email",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _otpTextField(otpController1),
                  _otpTextField(otpController2),
                  _otpTextField(otpController3),
                  _otpTextField(otpController4),
                ],
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  verifyOtp(); // Call the function to verify OTP
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: Text(
                  "Submit",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpTextField(TextEditingController controller) {
    return Container(
      width: 50,
      height: 50,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          counterText: '',
          fillColor: Colors.white,
          filled: true,
        ),
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
