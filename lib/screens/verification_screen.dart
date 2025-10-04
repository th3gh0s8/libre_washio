import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api.dart'; 
import '../session_manager.dart'; // Import the session manager
import 'dashboard_screen.dart';
import 'registration_screen.dart'; 

class VerificationScreen extends StatefulWidget {
  final String phoneNumber; 
  final String countryCode; 
  final String countryName;
  final String otpPurpose; 

  const VerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
    required this.countryName,
    required this.otpPurpose, 
  });

  @override
  VerificationScreenState createState() => VerificationScreenState();
}

class VerificationScreenState extends State<VerificationScreen> {
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    String otp = _codeControllers.map((controller) => controller.text).join();
    
    if (otp.length != 6) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit code.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.verifyOtp(widget.countryCode, widget.phoneNumber, otp, widget.otpPurpose); 

      if (response['status'] == 'success') {
        bool userExists = response['user_exists'] ?? false;
        Map<String, dynamic>? userData = response['user_data'] as Map<String, dynamic>?;

        if (userExists && userData != null) {
          // --- SAVE USER DATA TO SESSION ---
          await SessionManager.saveUserData(userData);

          navigator.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => AppShell( 
                userData: userData, 
              ),
            ),
            (Route<dynamic> route) => false, 
          );
        } else if (userExists && userData == null) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('User exists but data is missing. Please try again.')),
          );
          // Reset focus and clear fields on error too if needed, similar to wrong OTP
          for (var controller in _codeControllers) {
            controller.clear();
          }
          if (_focusNodes.isNotEmpty) {
            FocusScope.of(context).requestFocus(_focusNodes[0]);
          }
        } else {
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (context) => RegistrationScreen(
                phoneNumber: widget.phoneNumber,
                countryCode: widget.countryCode,
              ),
            ),
          );
        }
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Invalid OTP. Please try again.')),
        );
        // Clear fields and reset focus for incorrect OTP
        for (var controller in _codeControllers) {
          controller.clear();
        }
        if (_focusNodes.isNotEmpty) { 
          FocusScope.of(context).requestFocus(_focusNodes[0]);
        }
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
      // Optionally, clear fields and reset focus on general error too
      for (var controller in _codeControllers) {
          controller.clear();
      }
      if (_focusNodes.isNotEmpty) {
          FocusScope.of(context).requestFocus(_focusNodes[0]);
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() {
      _isLoading = true; 
    });
    try {
      final Map<String, dynamic> newOtpResponse = await ApiService.requestOtp(widget.phoneNumber, widget.countryCode);
      if (newOtpResponse['status'] == 'success') {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('A new OTP has been sent to your phone number. Please check your messages.')), 
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(newOtpResponse['message'] ?? 'Failed to resend OTP. Please try again.')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to resend OTP: ${e.toString()}')),
      );
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
              'Enter the 6-digit code sent to ${widget.countryCode}${widget.phoneNumber}. Purpose: ${widget.otpPurpose}', 
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            KeyboardListener(
              focusNode: FocusNode(), 
              onKeyEvent: (KeyEvent event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
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
