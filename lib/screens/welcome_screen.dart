import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http; // Temporarily commented out
// import 'dart:convert'; // Temporarily commented out
import 'package:country_code_picker/country_code_picker.dart';
// import '../api.dart'; // Temporarily commented out
import 'verification_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _phoneController = TextEditingController();
  String _selectedCountryCode = "+94";
  String _selectedCountryName = "Sri Lanka"; // Added state for country name

  void _login() {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showMessage('Please fill in all fields.');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VerificationScreen(
          phoneNumber: phone,
          countryCode: _selectedCountryCode,
          countryName: _selectedCountryName,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget buildMobileNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile number',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Row(
            children: [
              CountryCodePicker(
                onChanged: (countryCode) {
                  setState(() {
                    _selectedCountryCode = countryCode.dialCode ?? "+94";
                    _selectedCountryName = countryCode.name ?? "Unknown Country"; // Update country name
                  });
                },
                initialSelection: 'LK',
                favorite: const ['+94', 'LK'],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                alignLeft: false,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(10),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Mobile number',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Added for keyboard handling
      body: SingleChildScrollView( // Added to make content scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20), // Added some top padding if needed when scrolled
              Image.asset('assets/images/logo_light.png', height: 280),
              const SizedBox(height: 20),
              const Text(
                'Get started with Washio',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              buildMobileNumberField(),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: _login,
                child: const Text('Continue'),
              ),
              const SizedBox(height: 20),
              const Text('or'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () {
                  // Implement Google Sign-In logic here
                },
                icon: Image.asset('assets/images/google_logo.png', height: 20, width: 20),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 20),
              const Text(
                '''By proceeding, you consent to receiving calls, WhatsApp or SMS/RCS messages, including by automated means, from Washio and its affiliates to the number provided.''',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 20), // Added some bottom padding if needed when scrolled
            ],
          ),
        ),
      ),
    );
  }
}
