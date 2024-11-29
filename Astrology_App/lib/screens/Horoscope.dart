import 'package:astro_app/screens/HomeScreen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:astro_app/screens/string_extensions.dart';

class Horoscope extends StatefulWidget {
  final String zodiacSign;
  final String timePeriod;
  final String selectedDate;
  final String imagePath;

  const Horoscope({
    super.key,
    required this.zodiacSign,
    required this.timePeriod,
    required this.selectedDate,
    required this.imagePath,
  });

  @override
  _HoroscopeState createState() => _HoroscopeState();
}

class _HoroscopeState extends State<Horoscope> {
  Future<Map<String, dynamic>> _horoscopeData = Future.value({});

  @override
  void initState() {
    super.initState();
    _fetchHoroscope();
  }

  void _fetchHoroscope() {
    setState(() {
      _horoscopeData = getHoroscope(
          widget.zodiacSign, widget.timePeriod, widget.selectedDate);
    });
  }

  Future<Map<String, dynamic>> getHoroscope(
      String zodiacSign, String timePeriod, String selectedDate) async {
    final String apiUrl =
        'https://horoscope-api-ashutoshkrris.vercel.app/api/v1/get-horoscope/$timePeriod?sign=$zodiacSign&day=$selectedDate';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load horoscope data');
      }
    } catch (e) {
      throw Exception('Error fetching horoscope: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.zodiacSign} Horoscope',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _horoscopeData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final data = snapshot.data!;

            final horoscopeData =
                data['data']['horoscope_data'] ?? 'No data available';

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        widget.imagePath,
                        height: 150,
                      ),
                      SizedBox(height: 20),
                      Text(
                        '${widget.zodiacSign} Horoscope (${widget.timePeriod.capitalize()})',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Date: ${widget.selectedDate}',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Horoscope: $horoscopeData',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 40),
                      TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HomePage()));
                          },
                          child: Text(
                            "select another sign",
                            style: TextStyle(color: Colors.blue, fontSize: 18),
                          )),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Center(child: Text('No data found.'));
          }
        },
      ),
    );
  }
}
