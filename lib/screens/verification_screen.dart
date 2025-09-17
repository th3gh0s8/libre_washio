import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../api.dart'; 
import 'registration_screen.dart';
import 'dashboard_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;
  final String otpPurpose; // 'login' or 'registration'

  const VerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.countryCode,
    required this.otpPurpose,
  }) : super(key: key);

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    for (int i = 0; i < 4; i++) {
      _otpControllers[i].addListener(() {
        if (_otpControllers[i].text.length == 1 && i < 3) {
          FocusScope.of(context).requestFocus(_otpFocusNodes[i + 1]);
        }
      });
    }
  }

  void _startResendTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _resendTimer = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_isLoading) return;

    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 4-digit code.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.verifyOtp(widget.phoneNumber, widget.countryCode, otp);

      if (mounted) {
        if (response['status'] == 'success') {
          if (widget.otpPurpose == 'login' && response.containsKey('user_data')) {
             Map<String, dynamic> userData = response['user_data'];
             Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => AppShell(userData: userData)),
                (Route<dynamic> route) => false,
              );
          } else if (widget.otpPurpose == 'registration') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegistrationScreen(
                  phoneNumber: widget.phoneNumber,
                  countryCode: widget.countryCode,
                ),
              ),
            );
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification successful, but action is unclear.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Invalid OTP or an error occurred.')),
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

  Future<void> _resendOtp() async {
    if (_resendTimer > 0) return;

    setState(() {
      _isLoading = true; // Show loading indicator while resending
    });

    try {
      final response = await ApiService.requestOtp(widget.phoneNumber, widget.countryCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'OTP resent successfully.'),
            backgroundColor: response['status'] == 'success' ? Colors.green : Colors.red,
          ),
        );
        if (response['status'] == 'success') {
          _startResendTimer(); // Restart timer on success
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend OTP: ${e.toString()}'), backgroundColor: Colors.red),
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
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Verification Code'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 30),
            Text(
              'We have sent a 4-digit code to\n${widget.countryCode} ${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 50,
                  child: TextFormField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: ''
                    ),
                    onChanged: (value) {
                      if (value.length == 1 && index < 3) {
                        _otpFocusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _otpFocusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              child: _isLoading
                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                  : const Text('Verify'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _resendTimer == 0 ? _resendOtp : null,
              child: Text(
                _resendTimer > 0
                    ? 'Resend code in $_resendTimer seconds'
                    : 'Resend Code',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
