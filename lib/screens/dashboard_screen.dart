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
        // Corrected: Only pass userData as EditProfileScreen constructor expects
        builder: (context) => EditProfileScreen(userData: _userData),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      // If EditProfileScreen returned updated data, update the state
      setState(() {
        _userData = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String userName = _userData['name']?.toString() ?? 'User';
    // You can also ensure other fields are safely converted to string if displayed directly
    // String userEmail = _userData['email']?.toString() ?? 'No email';
    // String displayPhone = "${_userData['country_code']?.toString() ?? ''}${_userData['phone']?.toString() ?? ''}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false, 
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note), 
            tooltip: 'Edit Profile',
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
