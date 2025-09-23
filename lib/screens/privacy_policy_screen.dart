import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: const <Widget>[
          SizedBox(height: 8),
          _SectionCard(
            title: 'Introduction',
            icon: Icons.info_outline,
            content: 'This document explains what data Washio collects, why we collect it, and how we use it. Washio values user privacy and is committed to protecting personal data.',
          ),
          _SectionCard(
            title: 'Information We Collect',
            icon: Icons.inventory_2_outlined,
            content: 'From Users (car owners): Name, phone, email, location, car details, payment info.\nFrom Service Stations (partners): Business name, location, contact info, bank/payment details.\nAutomatic Data: App usage, device info, cookies, GPS location.',
          ),
          _SectionCard(
            title: 'How We Use the Information',
            icon: Icons.rule_folder_outlined,
            content: 'To connect users with service stations. Process bookings & payments. Improve app performance & features. Customer support & dispute resolution. Marketing (only with consent).',
          ),
          _SectionCard(
            title: 'Sharing of Data',
            icon: Icons.share_outlined,
            content: 'With service stations for fulfilling requests. With payment gateways (for secure transactions). With legal authorities if required. Never sold to third parties.',
          ),
          _SectionCard(
            title: 'Data Storage & Security',
            icon: Icons.security_outlined,
            content: 'Encryption for sensitive info. Limited employee access. Servers may be inside/outside Sri Lanka (or your operating country).',
          ),
          _SectionCard(
            title: 'User Rights',
            icon: Icons.manage_accounts_outlined,
            content: 'Access, update, or delete their personal data. Opt out of marketing communications.',
          ),
          _SectionCard(
            title: 'Children’s Privacy',
            icon: Icons.child_care_outlined,
            content: 'Washio is not for users under 18 without parental consent.',
          ),
           _SectionCard(
            title: 'Changes to Privacy Policy',
            icon: Icons.edit_notifications_outlined,
            content: 'Notify users when major changes are made.',
          ),
           _SectionCard(
            title: 'Contact Information',
            icon: Icons.contact_support_outlined,
            content: 'Email/phone for privacy-related queries.',
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
