import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  Widget _buildParagraph(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0), // Added a bit more bottom padding for paragraphs
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15), // Slightly larger font
        textAlign: TextAlign.justify,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
      ),
      body: ListView( // Changed to ListView for consistency and potential future additions
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildParagraph(
            context,
            'Washio is a smart and convenient platform that connects vehicle owners with trusted car wash service stations, making it easier than ever to keep your car clean. Just like booking a ride, you can now book a car wash anytime, anywhere with a few taps on your phone.',
          ),
          _buildParagraph(
            context,
            'Our mission is to bring efficiency, transparency, and convenience to car care by providing a seamless experience for both customers and service stations. With Washio, you save time, enjoy reliable service, and ensure your car gets the care it deserves.',
          ),
          _buildParagraph(
            context,
            'Washio is proudly developed and maintained by Powersoft (Pvt) Ltd, a leading technology company dedicated to creating innovative digital solutions for everyday needs.',
          ),
        ],
      ),
    );
  }
}
