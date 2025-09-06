import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added this import for LogicalKeyboardKey
import '../api.dart'; // Import your ApiService
import 'dashboard_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // For future session management

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;
  final String countryName; // Keep if needed for display or other logic

  const VerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.countryCode,
    required this.countryName,
  }) : super(key: key);

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = 
      List.generate(6, (index) => FocusNode());
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
         FocusScope.of(context).requestFocus(_focusNodes[0]);
        }
    });
  }

  Future<void> _verifyCode() async {
    String otp = _codeControllers.map((controller) => controller.text).join();
    
    if (otp.length != 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid 6-digit code.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Construct full phone number. Ensure countryCode starts with + and has no spaces.
    // WelcomeScreen already formats countryCode, so it should be fine here.
    final String fullPhoneNumber = widget.countryCode + widget.phoneNumber;

    try {
      final response = await ApiService.verifyOtp(fullPhoneNumber, otp);

      if (mounted) {
        if (response['status'] == 'success') {
          // OTP Verified!
          // Optional: Save user session/details if user_exists is true and user_data is available
          // For example:
          // if (response['user_exists'] == true && response['user_data'] != null) {
          //   SharedPreferences prefs = await SharedPreferences.getInstance();
          //   await prefs.setString('user_token', response['user_data']['id'].toString()); // Example token/id
          //   await prefs.setString('user_phone', fullPhoneNumber);
          // }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                phoneNumber: widget.phoneNumber, // Or fullPhoneNumber
                countryCode: widget.countryCode,
                countryName: widget.countryName, 
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Invalid OTP. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

 @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Widget _buildOtpTextField(int index) {
    return SizedBox(
      width: 45,
      child: TextField(
        controller: _codeControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          counterText: '',
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) { 
              FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
            } else {
              _focusNodes[index].unfocus(); 
              // If all fields are filled, automatically attempt to verify
              if (_codeControllers.every((controller) => controller.text.isNotEmpty)) {
                 _verifyCode();
              }
            }
          }
        },
      ),
    );
  }

  // TODO: Implement Resend OTP logic - requires an API call
  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true; // Can use the same loading state or a different one
    });
    // Ensure country code always starts with + and has no extra spaces
    final formattedCountryCode = widget.countryCode.startsWith('+') 
        ? widget.countryCode.replaceAll(' ', '') 
        : '+' + widget.countryCode.replaceAll(' ', '');

    try {
      final response = await ApiService.requestOtp(widget.phoneNumber, formattedCountryCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'OTP Resent (check server log for OTP).')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend OTP: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Verification Code'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter the 6-digit code sent to ${widget.countryCode}${widget.phoneNumber}.',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            RawKeyboardListener(
              focusNode: FocusNode(), 
              onKey: (RawKeyEvent event) {
                if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                  for (int i = 0; i < 6; i++) {
                    if (_focusNodes[i].hasFocus) {
                      if (_codeControllers[i].text.isEmpty && i > 0) {
                        FocusScope.of(context).requestFocus(_focusNodes[i - 1]);
                      }
                      break; 
                    }
                  }
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildOtpTextField(index)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _isLoading ? null : _verifyCode,
              child: _isLoading 
                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)) 
                  : const Text('Verify & Continue'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _isLoading ? null : _resendOtp, // Call _resendOtp
              child: const Text('Resend OTP'),
            )
          ],
        ),
      ),
    );
  }
}
