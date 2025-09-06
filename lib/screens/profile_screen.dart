import 'package:flutter/material.dart';
import 'edit_profile_screen.dart'; // We will create this next

class ProfileScreen extends StatefulWidget {
  final String initialPhoneNumber;
  final String initialCountryCode;
  final String initialCountryName;

  const ProfileScreen({
    Key? key,
    required this.initialPhoneNumber,
    required this.initialCountryCode,
    required this.initialCountryName,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String phoneNumber;
  late String countryCode;
  late String countryName;
  // Dummy fields for now, we can make them editable later
  String name = 'John Doe';
  String email = 'john.doe@example.com';

  @override
  void initState() {
    super.initState();
    phoneNumber = widget.initialPhoneNumber;
    countryCode = widget.initialCountryCode;
    countryName = widget.initialCountryName;
  }

  void _updateProfileDetails(Map<String, String> updatedDetails) {
    setState(() {
      name = updatedDetails['name'] ?? name;
      email = updatedDetails['email'] ?? email;
      phoneNumber = updatedDetails['phoneNumber'] ?? phoneNumber;
      // countryCode and countryName might not be editable in this flow
      // but if they are, they can be updated here too.
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
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    currentName: name,
                    currentEmail: email,
                    currentPhoneNumber: phoneNumber,
                    currentCountryCode: countryCode, // Pass even if not directly editable for context
                    currentCountryName: countryName, userData: {}, // Pass even if not directly editable for context
                  ),
                ),
              );

              if (result != null && result is Map<String, String>) {
                _updateProfileDetails(result);
              }
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
