import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String currentPhoneNumber;
  final String currentCountryCode;
  final String currentCountryName;

  const EditProfileScreen({
    Key? key,
    required this.currentName,
    required this.currentEmail,
    required this.currentPhoneNumber,
    required this.currentCountryCode,
    required this.currentCountryName,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _phoneController = TextEditingController(text: widget.currentPhoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final updatedDetails = {
      'name': _nameController.text,
      'email': _emailController.text,
      'phoneNumber': _phoneController.text,
    };
    Navigator.pop(context, updatedDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Reduced padding
          child: Column(
            children: <Widget>[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  icon: Icon(Icons.person_outline),
                  isDense: true, // Made denser
                ),
              ),
              const SizedBox(height: 12), // Reduced height
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  icon: Icon(Icons.email_outlined),
                  isDense: true, // Made denser
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12), // Reduced height
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  icon: const Icon(Icons.phone_outlined),
                  prefixText: widget.currentCountryCode + ' ',
                  isDense: true, // Made denser
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12), // Reduced height
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Country'),
                subtitle: Text(widget.currentCountryName),
                dense: true, // Made ListTile denser
              ),
              const SizedBox(height: 20), // Reduced height
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
