import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../api.dart'; 
import './actual_edit_profile_form_screen.dart'; 
import './about_screen.dart'; 
import './welcome_screen.dart'; // <<< NEW IMPORT for WelcomeScreen

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic> updatedUserData)? onUserDataUpdated;

  const EditProfileScreen({
    Key? key, 
    required this.userData,
    this.onUserDataUpdated,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String _displayName = "User";
  String _displayEmail = "";

  @override
  void initState() {
    super.initState();
    _updateDisplayDataFromWidgetData();
  }

  @override
  void didUpdateWidget(covariant EditProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userData != oldWidget.userData) {
      _updateDisplayDataFromWidgetData();
    }
  }

  void _updateDisplayDataFromWidgetData() {
    _displayName = widget.userData['name']?.toString() ?? 'User';
    _displayEmail = widget.userData['email']?.toString() ?? 'No email';
    setState(() {}); 
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _navigateToActualEditProfile() async { 
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActualEditProfileFormScreen(
          initialUserData: widget.userData,
          onUserDataUpdated: widget.onUserDataUpdated, 
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      _updateDisplayDataFromWidgetData(); 
    }
  }

  void _navigateToAboutScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutScreen()), 
    );
  }
  
  void _handleLogout() {
    // Navigate to WelcomeScreen and remove all routes behind it.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()), 
      (Route<dynamic> route) => false, // This predicate ensures all previous routes are removed.
    );
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'), 
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          // User Info Header
          Container(
            padding: const EdgeInsets.all(20.0),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  _displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _displayEmail,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          _buildSectionTitle(context, "Profile Management"),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _navigateToActualEditProfile,
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Change Password screen would open here.')),
              );
            },
          ),

          _buildSectionTitle(context, "App Settings"),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings would open here.')),
              );
            },
          ),

          _buildSectionTitle(context, "Support & Legal"),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Washio'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _navigateToAboutScreen, 
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Policy would open here.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms of Service would open here.')),
              );
            },
          ),
          
          const Divider(height: 32, thickness: 1),

          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text('Logout', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: _handleLogout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
