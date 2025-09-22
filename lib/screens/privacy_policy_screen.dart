import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0), // Increased top padding
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary, // Added primary color
            ),
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith( // Changed to bodyLarge
              height: 1.5, // Added line height
            ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildParagraph(context, 'This document explains what data Washio collects, why we collect it, and how we use it.'),
          _buildSectionTitle(context, 'Introduction'),
          _buildParagraph(context, 'Washio values user privacy and is committed to protecting personal data.'),
          _buildSectionTitle(context, 'Information We Collect'),
          _buildParagraph(context, 'From Users (car owners): Name, phone, email, location, car details, payment info.'),
          _buildParagraph(context, 'From Service Stations (partners): Business name, location, contact info, bank/payment details.'),
          _buildParagraph(context, 'Automatic Data: App usage, device info, cookies, GPS location.'),
          _buildSectionTitle(context, 'How We Use the Information'),
          _buildParagraph(context, 'To connect users with service stations.'),
          _buildParagraph(context, 'Process bookings & payments.'),
          _buildParagraph(context, 'Improve app performance & features.'),
          _buildParagraph(context, 'Customer support & dispute resolution.'),
          _buildParagraph(context, 'Marketing (only with consent).'),
          _buildSectionTitle(context, 'Sharing of Data'),
          _buildParagraph(context, 'With service stations for fulfilling requests.'),
          _buildParagraph(context, 'With payment gateways (for secure transactions).'),
          _buildParagraph(context, 'With legal authorities if required.'),
          _buildParagraph(context, 'Never sold to third parties.'),
          _buildSectionTitle(context, 'Data Storage & Security'),
          _buildParagraph(context, 'Encryption for sensitive info.'),
          _buildParagraph(context, 'Limited employee access.'),
          _buildParagraph(context, 'Servers may be inside/outside Sri Lanka (or your operating country).'),
          _buildSectionTitle(context, 'User Rights'),
          _buildParagraph(context, 'Access, update, or delete their personal data.'),
          _buildParagraph(context, 'Opt out of marketing communications.'),
          _buildSectionTitle(context, 'Children’s Privacy'),
          _buildParagraph(context, 'Washio is not for users under 18 without parental consent.'),
          _buildSectionTitle(context, 'Changes to Privacy Policy'),
          _buildParagraph(context, 'Notify users when major changes are made.'),
          _buildSectionTitle(context, 'Contact Information'),
          _buildParagraph(context, 'Email/phone for privacy-related queries.'),
        ],
      ),
    );
  }
}
