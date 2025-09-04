import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String phoneNumber;
  final String countryCode;
  final String countryName;

  const ProfileScreen({
    Key? key,
    required this.phoneNumber,
    required this.countryCode,
    required this.countryName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Name'),
            subtitle: Text('John Doe'), // Keeping dummy name for now
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.email_outlined),
            title: Text('Email'),
            subtitle: Text('john.doe@example.com'), // Keeping dummy email for now
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Phone'),
            subtitle: Text('$countryCode $phoneNumber'), // Dynamic phone number
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Country'), // Changed title to Country
            subtitle: Text(countryName), // Dynamic country name as address
          ),
        ],
      ),
    );
  }
}
