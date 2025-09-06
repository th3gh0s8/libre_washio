import 'package:flutter/material.dart';
import 'edit_profile_screen.dart'; // Import the new EditProfileScreen
// import 'profile_screen.dart'; // Old profile screen, can be removed if EditProfileScreen replaces it

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
      // If EditProfileScreen returned updated data, update the state
      setState(() {
        _userData = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract user's name for display, provide a default if not found
    String userName = _userData['name'] as String? ?? 'User';
    // You can extract other fields like email, address, phone, country_code from _userData as needed
    // String userEmail = _userData['email'] as String? ?? 'No email';
    // String displayPhone = "${_userData['country_code'] ?? ''}${_userData['phone'] ?? ''}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false, // To prevent back button to previous screens in auth flow
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note), // Changed icon to represent editing profile
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
              // You can add more user details here if needed:
              // Text("Email: $userEmail", style: TextStyle(fontSize: 16)),
              // Text("Phone: $displayPhone", style: TextStyle(fontSize: 16)),
              // if (_userData['address'] != null && (_userData['address'] as String).isNotEmpty)
              //   Text("Address: ${_userData['address']}", style: TextStyle(fontSize: 16)),
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
