import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false, // To prevent back button to verification
      ),
      body: const Center(
        child: Text(
          'Welcome to Washio!', // Changed here
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
