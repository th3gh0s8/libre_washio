import 'package:flutter/material.dart';
import 'profile_screen.dart'; // Import the profile screen

class DashboardScreen extends StatelessWidget {
  final String phoneNumber;
  final String countryCode;
  final String countryName;

  const DashboardScreen({
    Key? key,
    required this.phoneNumber,
    required this.countryCode,
    required this.countryName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false, // To prevent back button to verification
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    phoneNumber: phoneNumber,
                    countryCode: countryCode,
                    countryName: countryName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to Washio!', // Corrected text
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
