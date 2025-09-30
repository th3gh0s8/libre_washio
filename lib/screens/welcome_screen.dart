import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:provider/provider.dart';
import '../api.dart'; 
import '../theme_provider.dart'; 
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
  const WelcomeScreen({super.key});

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
    String phoneInput = _phoneController.text.trim();
    String currentSelectedDialCode = _selectedCountryCode.startsWith('+') 
          ? _selectedCountryCode.replaceAll(' ', '') 
          : '+${_selectedCountryCode.replaceAll(' ', '')}';

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.requestOtp(phoneInput, currentSelectedDialCode);
      if (mounted) {
        if (response['status'] == 'success') {
          String otpPurpose = response['otp_purpose'] as String? ?? 'login';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                phoneNumber: phoneInput,
                countryCode: currentSelectedDialCode,
                countryName: _selectedCountryName,
                otpPurpose: otpPurpose,
              ),
            ),
          );
        } else {
          _showMessage(response['message'] ?? 'Failed to send OTP. Please try again.');
        }
      }
    } catch (e) {
      print('LOGIN ERROR: ${e.toString()}');
      if (mounted) {
        _showMessage('An error occurred: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
        );
    }
  }

  Widget buildMobileNumberField(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mobile number',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
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
                  textStyle: TextStyle(color: theme.colorScheme.onSurface),
                  dialogBackgroundColor: theme.dialogBackgroundColor,
                  dialogTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                  searchDecoration: InputDecoration(
                    hintText: 'Search country',
                    hintStyle: TextStyle(color: theme.hintColor),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.primaryColor),
                    ),
                    prefixIcon: Icon(Icons.search, color: theme.iconTheme.color), 
                  ),
                  searchStyle: TextStyle(color: theme.colorScheme.onSurface),
                  flagDecoration: BoxDecoration(borderRadius: BorderRadius.circular(2)),
                  boxDecoration: BoxDecoration(color: Colors.transparent),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    inputFormatters: [
                      NoLeadingZeroFormatter(forbidLeadingZero: _currentPhoneRule.forbidLeadingZero),
                      LengthLimitingTextInputFormatter(_currentPhoneRule.inputLength),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: 'Mobile number',
                      hintStyle: TextStyle(color: theme.hintColor),
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your mobile number.';
                      }
                      if (value.trim().length != _currentPhoneRule.actualLength) {
                        return 'Enter a valid ${_currentPhoneRule.actualLength}-digit number for $_selectedCountryName.';
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final String logoAssetPath = themeProvider.isDarkMode 
        ? 'assets/images/logo_dark.png' 
        : 'assets/images/logo_light.png';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Image.asset(logoAssetPath, height: 280),
              const SizedBox(height: 20),
              const Text(
                'Get started with Washio',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              buildMobileNumberField(context),
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
              const SizedBox(height: 24.0), // Spacing before disclaimer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // Match button horizontal padding
                child: Text(
                  'By proceeding, you consent to receiving calls, WhatsApp or SMS/RCS messages, including by automated means, from Washio and its affiliates to the number provided.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.0, color: Colors.grey.shade600, height: 1.3),
                ),
              ),
              const SizedBox(height: 20.0), // Spacing at the very bottom
            ],
          ),
        ),
      ),
    );
  }
}
