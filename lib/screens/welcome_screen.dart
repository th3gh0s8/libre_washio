import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart'; // Added import
import '../api.dart';
import 'verification_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String _selectedCountryCode = "+94"; // Added state variable for country code

  Future<void> _login() async {
    // Ensure _selectedCountryCode includes '+' or add it if necessary for your API
    // The CountryCodePicker's dialCode usually includes '+'
    final phoneWithCountryCode = _selectedCountryCode + _phoneController.text.trim();
    final phone = _phoneController.text.trim(); // Original phone for verification screen

    // print('Phone number with country code: $phoneWithCountryCode'); // For debugging

    if (phone.isEmpty) {
      _showMessage('Please fill in all fields.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse("${ApiService.baseUrl}login.php");
    print('Requesting URL: $url'); // For debugging

    final response = await http.post(
      url,
      body: {'phone': phoneWithCountryCode}, // Use phoneWithCountryCode
    ).timeout(const Duration(seconds: 10));


    print('Response status code: ${response.statusCode}'); // For debugging
    print('Response body: ${response.body}'); // For debugging

    if (!mounted) return;

    final result = jsonDecode(response.body);

    if (result['status'] == 'success') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // Pass the phone number without country code, or with, depending on VerificationScreen needs
          builder: (context) => VerificationScreen(phoneNumber: phone),
        ),
      );
    } else {
      _showMessage(result['message'] ?? 'Login failed. Please try again.');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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
        Container( // Added a container for better UI for the row
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
                  });
                },
                initialSelection: 'LK', // ISO code for Sri Lanka
                favorite: const ['+94', 'LK'], // Optional: Add favorites
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                alignLeft: false,
              ),
              const SizedBox(width: 5), // Reduced SizedBox
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(10), // Adjust length if needed based on country
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo_light.png', height: 250),
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
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Continue'),
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
              icon: Image.asset('assets/images/google_logo.png', height: 24, width: 24), // Replaced Icon with Google logo
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 20),
            const Text(
              '''By proceeding, you consent to receiving calls, WhatsApp or SMS/RCS messages, including by automated means, from Washio and its affiliates to the number provided.''',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
