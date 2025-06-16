import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PIN Code Lookup',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: PinCodePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PinCodePage extends StatefulWidget {
  @override
  _PinCodePageState createState() => _PinCodePageState();
}

class _PinCodePageState extends State<PinCodePage> {
  final TextEditingController _controller = TextEditingController();
  String? region, district, state, status;
  String error = '';
  bool isLoading = false;

  Future<void> fetchPinCodeDetails(String pinCode) async {
    setState(() {
      isLoading = true;
      error = '';
    });

    final url = 'https://api.postalpincode.in/pincode/$pinCode';
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data[0]['Status'] == 'Success') {
        final postOffice = data[0]['PostOffice'][0];
        setState(() {
          region = postOffice['Region'];
          district = postOffice['District'];
          state = postOffice['State'];
          status = postOffice['DeliveryStatus'];
        });
      } else {
        setState(() {
          error = '❌ Invalid PIN Code';
          region = district = state = status = null;
        });
      }
    } else {
      setState(() {
        error = '⚠️ Failed to fetch data';
      });
    }
  }

  void resetForm() {
    _controller.clear();
    setState(() {
      region = district = state = status = null;
      error = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PIN Code Lookup')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Enter 6-digit PIN Code',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.search),
                      label: Text('Search'),
                      onPressed: () {
                        final pin = _controller.text.trim();
                        if (pin.length == 6) {
                          fetchPinCodeDetails(pin);
                        } else {
                          setState(() {
                            error = '⚠️ Please enter a valid 6-digit PIN Code';
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    tooltip: 'Reset',
                    onPressed: resetForm,
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (isLoading) CircularProgressIndicator(),
              if (error.isNotEmpty)
                Text(error, style: TextStyle(color: Colors.red, fontSize: 16)),
              if (region != null) buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildResultCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            resultRow('📍 Region', region!),
            resultRow('🏙️ District', district!),
            resultRow('🗺️ State', state!),
            resultRow('🚚 Delivery Status', status!),
          ],
        ),
      ),
    );
  }

  Widget resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
