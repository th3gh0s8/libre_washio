import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: const <Widget>[
          SizedBox(height: 8),
          _SectionCard(
            title: 'Acceptance of Terms',
            icon: Icons.check_circle_outline,
            content: 'By downloading/using Washio, users agree to these terms.',
          ),
          _SectionCard(
            title: 'Services Provided',
            icon: Icons.local_car_wash_outlined,
            content: 'Washio is a marketplace/platform, not a car wash operator. Washio connects users with independent service stations.',
          ),
          _SectionCard(
            title: 'User Responsibilities',
            icon: Icons.person_outline,
            content: 'Provide accurate info when registering. Ensure payment details are valid. Use the app lawfully.',
          ),
          _SectionCard(
            title: 'Service Station Responsibilities',
            icon: Icons.storefront_outlined,
            content: 'Provide quality and timely car wash services. Maintain business licenses/insurance (if applicable). Follow Washio’s rules and policies.',
          ),
          _SectionCard(
            title: 'Booking & Payments',
            icon: Icons.payment_outlined,
            content: 'Payments are made through the app (online, wallet, or cash if allowed). Cancellations/refunds policy. Washio may charge service/commission fees.',
          ),
          _SectionCard(
            title: 'Platform Role & Disclaimer',
            icon: Icons.info_outline,
            content: 'Washio is not responsible for the quality, safety, or damages during services (service station is responsible). Washio provides technology platform only.',
          ),
          _SectionCard(
            title: 'Liability Limitation',
            icon: Icons.gavel_outlined,
            content: 'Washio’s liability is limited to the amount of service fees paid.',
          ),
          _SectionCard(
            title: 'Termination',
            icon: Icons.block_outlined,
            content: 'Washio can suspend accounts for fraud, misuse, or policy violations.',
          ),
          _SectionCard(
            title: 'Dispute Resolution',
            icon: Icons.support_agent_outlined,
            content: 'Disputes should first be reported to Washio support. Any legal disputes handled under Sri Lankan law (or your chosen jurisdiction).',
          ),
           _SectionCard(
            title: 'Modifications',
            icon: Icons.edit_document,
            content: 'Washio can update terms; continued use = acceptance.',
          ),
           _SectionCard(
            title: 'Contact Info',
            icon: Icons.contact_mail_outlined,
            content: 'Support details for users and service stations.',
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _SectionCard({required this.title, required this.content, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      elevation: 2.0,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ExpansionTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content,
            textAlign: TextAlign.justify,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
