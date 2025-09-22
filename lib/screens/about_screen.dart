import 'package:flutter/material.dart';
import './privacy_policy_screen.dart';
import './terms_of_service_screen.dart';
import './about_us_screen.dart'; // Added this import

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _appName = 'Washio';
  static const String _appVersion = '1.0.0';
  static const String _developerName = 'Powersoft Pvt Ltd';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About $_appName'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: <Widget>[
          _buildSectionTitle(context, 'App Information'),
          _buildInfoTile(context, Icons.info_outline, 'App Name', _appName),
          _buildInfoTile(context, Icons.new_releases_outlined, 'Version', _appVersion),
          _buildInfoTile(context, Icons.people_outline, 'Developed by', _developerName),

          const SizedBox(height: 24),
          // MODIFIED SECTION: Changed title and replaced text block with a LinkTile
          _buildSectionTitle(context, 'About Washio'), // Section title for the "About Us" link
          _buildLinkTile(
            context,
            Icons.info_outline, // Using an info icon for "About Us"
            'About Us',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutUsScreen()),
              );
            }
          ),
          // The inline "About Us" text block has been removed from here.

          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Legal & More'),
          _buildLinkTile(
            context,
            Icons.shield_outlined,
            'Privacy Policy',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
              );
            }
          ),
          _buildLinkTile(
            context,
            Icons.description_outlined,
            'Terms of Service',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
              );
            }
          ),
          /* // Open Source Licenses remains commented out
          _buildLinkTile(
            context,
            Icons.code_outlined,
            'Open Source Licenses',
            () {
              showLicensePage(
                context: context,
                applicationName: _appName,
                applicationVersion: _appVersion,
                applicationLegalese: '© ${DateTime.now().year} Powersoft Pvt Ltd',
              );
            }
          ),
          */

          const SizedBox(height: 40),
          Center(
            child: Text(
              '© ${DateTime.now().year} Powersoft Pvt Ltd. All rights reserved.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0), // MODIFIED padding
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold, // MODIFIED fontWeight
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 28),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }

  Widget _buildLinkTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 28),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, size: 24),
        onTap: onTap,
      ),
    );
  }
}
