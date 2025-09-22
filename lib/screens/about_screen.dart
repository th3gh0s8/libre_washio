import 'package:flutter/material.dart';
import './privacy_policy_screen.dart'; // Added import
import './terms_of_service_screen.dart'; // Added import

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // You can fetch these dynamically later using package_info_plus or other methods
  static const String _appName = 'Washio'; 
  static const String _appVersion = '1.0.0'; // Placeholder
  static const String _developerName = 'Powersoft Pvt Ltd';
  // static const String _privacyPolicyUrl = 'YOUR_PRIVACY_POLICY_URL_HERE';
  // static const String _termsOfServiceUrl = 'YOUR_TERMS_OF_SERVICE_URL_HERE';

  // Helper method to launch URLs (requires url_launcher package)
  /*
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      // Consider showing a SnackBar or dialog if URL launch fails
      print('Could not launch $urlString');
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About $_appName'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: <Widget>[
          // App Logo (Optional)
          /* 
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Image.asset(
              themeProvider.isDarkMode ? 'assets/images/logo_dark.png' : 'assets/images/logo_light.png',
              height: 80,
            ),
          ),
          */
          
          _buildSectionTitle(context, 'App Information'),
          _buildInfoTile(context, Icons.info_outline, 'App Name', _appName),
          _buildInfoTile(context, Icons.new_releases_outlined, 'Version', _appVersion),
          _buildInfoTile(context, Icons.people_outline, 'Developed by', _developerName),
          
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'About Us'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Washio is a smart and convenient platform that connects vehicle owners with trusted car wash service stations, making it easier than ever to keep your car clean. Just like booking a ride, you can now book a car wash anytime, anywhere with a few taps on your phone.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.justify, 
                ),
                const SizedBox(height: 12),
                Text(
                  'Our mission is to bring efficiency, transparency, and convenience to car care by providing a seamless experience for both customers and service stations. With Washio, you save time, enjoy reliable service, and ensure your car gets the care it deserves.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.justify, 
                ),
                const SizedBox(height: 12),
                Text(
                  'Washio is proudly developed and maintained by Powersoft (Pvt) Ltd, a leading technology company dedicated to creating innovative digital solutions for everyday needs.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.justify, 
                ),
              ],
            ),
          ),

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
          /*
          _buildLinkTile(
            context, 
            Icons.code_outlined, 
            'Open Source Licenses',
            () {
              showLicensePage(
                context: context,
                applicationName: _appName,
                applicationVersion: _appVersion,
                // applicationIcon: Image.asset('assets/images/app_icon.png', height: 40), // Optional
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
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
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
