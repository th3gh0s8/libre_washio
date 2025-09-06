import 'package:flutter/material.dart';
import 'edit_profile_screen.dart'; // Import the new EditProfileScreen

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData; // Expecting the full user data map

  const DashboardScreen({Key? key, required this.userData}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Map<String, dynamic> _userData;

  @override
  void initState() {
    super.initState();
    _userData = widget.userData;
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userData: _userData),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _userData = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String userName = _userData['name']?.toString() ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false, 
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle), // Changed icon
            tooltip: 'Profile', // Updated tooltip
            onPressed: _navigateToEditProfile,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome, $userName!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 30),
              const Text(
                'This is your Washio Dashboard.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
