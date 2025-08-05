import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'verification_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();




}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;


  Future<void> _login() async {
    final phoneNumber = _phoneController.text.trim();


    if (phoneNumber.isEmpty) {
      _showMessage('Please fill in all fields.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse("${ApiService.baseUrl}login.php");
    final response = await http.post(
      url,
      body: {'phoneNumber': phoneNumber},
    );

    final result = jsonDecode(response.body);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['status'] == 'success') {
      String userId = result['user_id'];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userId);

      _showMessage('Login Successful!');

      // Navigate to Dashboard
      //Navigator.pushReplacementNamed(context, 'screens/verification_screen.dart');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationScreen(phoneNumber: phoneNumber),
        ),
      );
      
    } else {
      _showMessage(result['message']);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Reusable UI function for the mobile number input field
  Widget buildMobileNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobile number',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            SizedBox(width: 10),
            Text('+94'),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  hintText: 'Mobile number',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }



/*
  void _navigateToVerificationScreen() {
    String phoneNumber = "+94" + _phoneController.text.trim();
    if (_phoneController.text.trim().isEmpty) {
      _showMessage('Please enter your mobile number.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerificationScreen(phoneNumber: phoneNumber),
      ),
    );
  }*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo_light.png', height: 250),
            SizedBox(height: 20),
            Text(
              'Get started with Washio',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            buildMobileNumberField(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateToVerificationScreen,
              child: Text('Continue'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                padding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),

            SizedBox(height: 20),
            Text('or'),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Implement Google Sign-In logic here
              },
              icon: Icon(Icons.g_mobiledata),
              label: Text('Continue with Google'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                padding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'By proceeding, you consent to receiving calls, WhatsApp or SMS/RCS messages, including by automated means, from Washio and its affiliates to the number provided.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
