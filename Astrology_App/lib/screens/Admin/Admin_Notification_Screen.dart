import 'package:astro_app/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class AdminNotificationScreen extends StatefulWidget {
  @override
  _AdminNotificationScreenState createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  OverlayEntry? overlayEntry;

  @override
  void initState() {
    super.initState();
    initOneSignal();
  }

  // Initialize OneSignal
  void initOneSignal() {
    OneSignal.shared.setAppId("d579a077-7719-4391-aadd-a494a3bc3295");
    OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
      print("Accepted permission: $accepted");
    });

    // Handle notification received in the foreground
    OneSignal.shared.setNotificationWillShowInForegroundHandler((event) {
      // Extract notification details
      var notification = event.notification;
      String title = notification.title ?? "No Title";
      String message = notification.body ?? "No Message";

      // Show the notification as a popup card
      _showNotificationPopup(title, message);

      // Complete the event to show the notification in the system tray
      event.complete(event.notification);
    });
  }

  void _showNotificationPopup(String title, String message) {
    // Create an OverlayEntry to show the popup card
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50.0, // Position of the popup card from the top
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(message, style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      overlayEntry?.remove(); // Dismiss the popup
                      overlayEntry = null;
                    },
                    child: Text("Dismiss", style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Insert the overlay entry into the overlay
    Overlay.of(context).insert(overlayEntry!);

    // Automatically dismiss the popup after 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      overlayEntry?.remove();
      overlayEntry = null;
    });
  }

  Future<void> sendNotification() async {
    if (_formKey.currentState!.validate()) {
      final String title = _titleController.text;
      final String message = _messageController.text;

      final Uri url = Uri.parse('$backendBaseUrl/api/send-notification');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': title,
            'message': message,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Notification sent successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send notification.')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Title', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                TextFormField(
                  controller: _titleController,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a title' : null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text('Message', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                TextFormField(
                  controller: _messageController,
                  maxLines: 5,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a message' : null,
                  decoration: InputDecoration(
                    hintText: 'Write your message here ......',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: sendNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(
                          horizontal: 50.0, vertical: 15.0),
                    ),
                    child: Text(
                      'Push',
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
      ),
    );
  }
}
