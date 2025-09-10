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
  // MODIFIED: Use separate controllers for first and last name
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
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

      // MODIFIED: Get first and last name and combine them
      String firstName = _firstNameController.text.trim();
      String lastName = _lastNameController.text.trim();
      String fullName = '$firstName $lastName'.trim(); // Combine and trim any extra space if last name is empty
      
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
      
      try {
        final response = await ApiService.registerUser(
          name: fullName, // Send the combined full name
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
    // MODIFIED: Dispose new name controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
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
              // MODIFIED: First Name TextFormField
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              // MODIFIED: Last Name TextFormField
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                // Last name can be optional depending on your requirements, adjust validator accordingly
                validator: (value) {
                  // Example: making last name optional
                  // if (value == null || value.trim().isEmpty) {
                  //   return 'Please enter your last name';
                  // }
                  return null; 
                },
                textInputAction: TextInputAction.next,
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
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),
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
