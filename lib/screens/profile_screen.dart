import 'package:flutter/material.dart';
import 'actual_edit_profile_form_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  final String initialPhoneNumber;
  final String initialCountryCode;
  final String initialCountryName;

  const ProfileScreen({
    super.key,
    required this.initialPhoneNumber,
    required this.initialCountryCode,
    required this.initialCountryName,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String phoneNumber;
  late String countryCode;
  late String countryName;
  String name = 'John Doe';
  String email = 'john.doe@example.com';

  @override
  void initState() {
    super.initState();
    phoneNumber = widget.initialPhoneNumber;
    countryCode = widget.initialCountryCode;
    countryName = widget.initialCountryName;
  }

  void _updateProfileDetails(Map<String, dynamic> updatedDetails) {
    if (!mounted) return;
    setState(() {
      name = updatedDetails['name']?.toString() ?? name;
      email = updatedDetails['email']?.toString() ?? email;
      phoneNumber = updatedDetails['phone']?.toString() ?? phoneNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActualEditProfileFormScreen(
                    initialUserData: {
                      'name': name,
                      'email': email,
                      'phone': phoneNumber,
                      'country_code': countryCode,
                      // This screen seems to be legacy and doesn't have a full user object.
                      // Passing what we have to satisfy the form.
                    },
                    onUserDataUpdated: (updatedData) {
                      if (mounted) {
                        _updateProfileDetails(updatedData);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blueAccent,
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Name'),
            subtitle: Text(name),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(email),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Phone'),
            subtitle: Text('$countryCode $phoneNumber'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Country'),
            subtitle: Text(countryName),
          ),
        ],
      ),
    );
  }
}
