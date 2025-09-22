import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
        title: const Text('Terms of Service'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildParagraph(context, 'This governs the legal agreement between Washio, users, and service stations.'),
          _buildSectionTitle(context, 'Acceptance of Terms'),
          _buildParagraph(context, 'By downloading/using Washio, users agree to these terms.'),
          _buildSectionTitle(context, 'Services Provided'),
          _buildParagraph(context, 'Washio is a marketplace/platform, not a car wash operator.'),
          _buildParagraph(context, 'Washio connects users with independent service stations.'),
          _buildSectionTitle(context, 'User Responsibilities'),
          _buildParagraph(context, 'Provide accurate info when registering.'),
          _buildParagraph(context, 'Ensure payment details are valid.'),
          _buildParagraph(context, 'Use the app lawfully.'),
          _buildSectionTitle(context, 'Service Station Responsibilities'),
          _buildParagraph(context, 'Provide quality and timely car wash services.'),
          _buildParagraph(context, 'Maintain business licenses/insurance (if applicable).'),
          _buildParagraph(context, 'Follow Washio’s rules and policies.'),
          _buildSectionTitle(context, 'Booking & Payments'),
          _buildParagraph(context, 'Payments are made through the app (online, wallet, or cash if allowed).'),
          _buildParagraph(context, 'Cancellations/refunds policy.'),
          _buildParagraph(context, 'Washio may charge service/commission fees.'),
          _buildSectionTitle(context, 'Platform Role & Disclaimer'),
          _buildParagraph(context, 'Washio is not responsible for the quality, safety, or damages during services (service station is responsible).'),
          _buildParagraph(context, 'Washio provides technology platform only.'),
          _buildSectionTitle(context, 'Liability Limitation'),
          _buildParagraph(context, 'Washio’s liability is limited to the amount of service fees paid.'),
          _buildSectionTitle(context, 'Termination'),
          _buildParagraph(context, 'Washio can suspend accounts for fraud, misuse, or policy violations.'),
          _buildSectionTitle(context, 'Dispute Resolution'),
          _buildParagraph(context, 'Disputes should first be reported to Washio support.'),
          _buildParagraph(context, 'Any legal disputes handled under Sri Lankan law (or your chosen jurisdiction).'),
          _buildSectionTitle(context, 'Modifications'),
          _buildParagraph(context, 'Washio can update terms; continued use = acceptance.'),
          _buildSectionTitle(context, 'Contact Info'),
          _buildParagraph(context, 'Support details for users and service stations.'),
        ],
      ),
    );
  }
}
