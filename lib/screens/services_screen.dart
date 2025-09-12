import 'package:flutter/material.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'), // Changed title here
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Services Screen - Explore Our Offerings!', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
