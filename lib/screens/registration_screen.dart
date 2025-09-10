import 'package:flutter/material.dart';
import '../api.dart'; // Import ApiService
import 'dashboard_screen.dart'; // This file now contains AppShell

class RegistrationScreen extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;

  const RegistrationScreen({
    Key? key,
    required this.phoneNumber,
    required this.countryCode,
  }) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  // New controllers for optional vehicle details
  final TextEditingController _vehicleNoController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();

  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String name = _nameController.text.trim();
      String email = _emailController.text.trim();
      String address = _addressController.text.trim();
      // Get optional vehicle details
      String? vehicleNo = _vehicleNoController.text.trim().isNotEmpty 
                           ? _vehicleNoController.text.trim() 
                           : null;
      String? vehicleType = _vehicleTypeController.text.trim().isNotEmpty 
                             ? _vehicleTypeController.text.trim() 
                             : null;
      String? vehicleModel = _vehicleModelController.text.trim().isNotEmpty 
                              ? _vehicleModelController.text.trim() 
                              : null;
      
      // Ensure all or none for vehicle details if any is partially filled by user
      // Though ApiService.registerUser handles this by only sending if all three are non-empty,
      // this client-side check can provide immediate feedback if desired, or be removed
      // if we rely solely on ApiService and backend logic.
      // For now, let ApiService and backend handle the "all or nothing" logic.

      try {
        final response = await ApiService.registerUser(
          name: name,
          email: email,
          phone: widget.phoneNumber,
          countryCode: widget.countryCode,
          address: address.isNotEmpty ? address : null,
          vehicleNo: vehicleNo,
          vehicleType: vehicleType,
          vehicleModel: vehicleModel,
        );

        if (mounted) {
          if (response['status'] == 'success') {
            Map<String, dynamic>? newUserData = response['user_data'] as Map<String, dynamic>?;

            if (newUserData != null) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => AppShell(
                    userData: newUserData,
                  ),
                ),
                (Route<dynamic> route) => false,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Registration successful, but user data was not returned. Please try logging in.')),
              );
              // Optionally navigate to login or show other message
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] ?? 'Registration failed. Please try again.')),
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    // Dispose new vehicle controllers
    _vehicleNoController.dispose();
    _vehicleTypeController.dispose();
    _vehicleModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Registering for: ${widget.countryCode} ${widget.phoneNumber}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                // No validator as it's optional
              ),
              const SizedBox(height: 24),
              // Optional Vehicle Details Section
              Text(
                'Vehicle Details (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _vehicleNoController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number (Optional)',
                  hintText: 'e.g., ABC-1234',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car_filled_outlined),
                ),
                textInputAction: TextInputAction.next,
                // No validator as it's optional
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehicleTypeController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type (Optional)',
                  hintText: 'e.g., Car, Bike, Van',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.two_wheeler_outlined),
                ),
                textInputAction: TextInputAction.next,
                // No validator as it's optional
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehicleModelController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Model (Optional)',
                  hintText: 'e.g., Toyota Corolla, Honda CB Shine',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.branding_watermark_outlined),
                ),
                textInputAction: TextInputAction.done,
                // No validator as it's optional
              ),
              const SizedBox(height: 24),
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
                onPressed: _isLoading ? null : _registerUser,
                child: _isLoading
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : const Text('Complete Registration'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}