import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api.dart'; 
import 'dashboard_screen.dart';
import 'registration_screen.dart'; // Placeholder for the new registration screen
// import 'package:shared_preferences/shared_preferences.dart'; // For future session management

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;
  final String countryName;

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

    final String fullPhoneNumber = widget.countryCode + widget.phoneNumber;

    try {
      final response = await ApiService.verifyOtp(fullPhoneNumber, otp);

      if (mounted) {
        if (response['status'] == 'success') {
          bool userExists = response['user_exists'] ?? false;
          // dynamic userData = response['user_data']; // Available if needed

          if (userExists) {
            // User is registered, go to Dashboard
            // TODO: Optionally save user session here using userData
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(
                  phoneNumber: widget.phoneNumber,
                  countryCode: widget.countryCode,
                  countryName: widget.countryName, 
                  // userData: userData, // You could pass user data if DashboardScreen expects it
                ),
              ),
            );
          } else {
            // User is not registered, go to RegistrationScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RegistrationScreen(
                  phoneNumber: widget.phoneNumber,
                  countryCode: widget.countryCode,
                  // countryName: widget.countryName, // Pass if needed by RegistrationScreen
                ),
              ),
            );
          }
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
              if (_codeControllers.every((controller) => controller.text.isNotEmpty)) {
                 _verifyCode();
              }
            }
          }
        },
      ),
    );
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true; 
    });
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
              onPressed: _isLoading ? null : _resendOtp,
              child: const Text('Resend OTP'),
            )
          ],
        ),
      ),
    );
  }
}
