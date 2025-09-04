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
      // countryCode and countryName are not edited here but could be if needed
    };
    Navigator.pop(context, updatedDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                icon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                icon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                icon: const Icon(Icons.phone_outlined),
                prefixText: widget.currentCountryCode + ' ', // Display country code
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Country'),
              subtitle: Text(widget.currentCountryName), // Display country, not editable for now
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
