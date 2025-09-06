import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../api.dart'; // Import your ApiService
import 'verification_screen.dart';

class PhoneNumberRule {
  final int inputLength; 
  final int actualLength;
  final bool forbidLeadingZero;

  PhoneNumberRule({
    required this.inputLength,
    required this.actualLength,
    this.forbidLeadingZero = false,
  });
}

class NoLeadingZeroFormatter extends TextInputFormatter {
  final bool forbidLeadingZero;

  NoLeadingZeroFormatter({required this.forbidLeadingZero});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (forbidLeadingZero && newValue.text.isNotEmpty && newValue.text.startsWith('0')) {
      String newText = newValue.text.substring(1);
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
    return newValue; 
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _selectedCountryCode = "+94";
  String _selectedCountryName = "Sri Lanka";
  String _selectedCountryIsoCode = "LK"; 
  bool _isLoading = false;

  // Initialize with LK rule as it's the initial selection
  PhoneNumberRule _currentPhoneRule = PhoneNumberRule(inputLength: 9, actualLength: 9, forbidLeadingZero: true);

  final Map<String, PhoneNumberRule> _countryPhoneRules = {
    'LK': PhoneNumberRule(inputLength: 9, actualLength: 9, forbidLeadingZero: true),
    'US': PhoneNumberRule(inputLength: 10, actualLength: 10, forbidLeadingZero: false),
    'IN': PhoneNumberRule(inputLength: 10, actualLength: 10, forbidLeadingZero: false), 
  };

  @override
  void initState() {
    super.initState();
    _updatePhoneRule(_selectedCountryIsoCode); 
  }

  void _updatePhoneRule(String countryIsoCode) {
    setState(() {
      _currentPhoneRule = _countryPhoneRules[countryIsoCode] ??
          PhoneNumberRule(inputLength: 15, actualLength: 10, forbidLeadingZero: false); 
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) { 
      return;
    }

    String phoneToSend = _phoneController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final formattedCountryCode = _selectedCountryCode.startsWith('+') 
          ? _selectedCountryCode.replaceAll(' ', '') 
          : '+' + _selectedCountryCode.replaceAll(' ', '');

      final response = await ApiService.requestOtp(phoneToSend, formattedCountryCode);

      if (mounted) {
        if (response['status'] == 'success') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                phoneNumber: phoneToSend,
                countryCode: formattedCountryCode,
                countryName: _selectedCountryName,
              ),
            ),
          );
        } else {
          _showMessage(response['message'] ?? 'Failed to send OTP. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('An error occurred: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
        );
    }
  }

  Widget buildMobileNumberField() {
    return Form(
      key: _formKey,
      child: Column(
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
                      _selectedCountryName = countryCode.name ?? "Unknown Country";
                      _selectedCountryIsoCode = countryCode.code ?? "LK";
                      _updatePhoneRule(_selectedCountryIsoCode);
                      _phoneController.clear(); 
                    });
                  },
                  initialSelection: _selectedCountryIsoCode, 
                  favorite: const ['+94', 'LK', '+1', 'US', '+91', 'IN'],
                  showCountryOnly: false,
                  showOnlyCountryWhenClosed: false,
                  alignLeft: false,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      NoLeadingZeroFormatter(forbidLeadingZero: _currentPhoneRule.forbidLeadingZero),
                      LengthLimitingTextInputFormatter(_currentPhoneRule.inputLength),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      hintText: 'Mobile number',
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your mobile number.';
                      }
                      if (value.trim().length != _currentPhoneRule.actualLength) {
                        return 'Enter a valid ${_currentPhoneRule.actualLength}-digit number for $_selectedCountryCode.';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
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
                onPressed: _isLoading ? null : _login,
                child: _isLoading 
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)) 
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
                icon: Image.asset('assets/images/google_logo.png', height: 20, width: 20),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 20),
              const Text(
                '''By proceeding, you consent to receiving calls, WhatsApp or SMS/RCS messages, including by automated means, from Washio and its affiliates to the number provided.''',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
