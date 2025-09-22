import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../session_manager.dart'; // Import the session manager
import './actual_edit_profile_form_screen.dart';
import './about_screen.dart';
import './welcome_screen.dart';
import './saved_addresses_screen.dart';
import './vehicle_management_screen.dart';
import './privacy_policy_screen.dart'; // Added import
import './terms_of_service_screen.dart'; // Added import

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic> updatedUserData)? onUserDataUpdated;

  const EditProfileScreen({
    super.key,
    required this.userData,
    this.onUserDataUpdated,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String _displayName = "User";
  String _displayEmail = "";
  late int _currentUserId;

  @override
  void initState() {
    super.initState();
    _updateDisplayDataFromWidgetData();
    _currentUserId = widget.userData['id'] as int; 
  }

  @override
  void didUpdateWidget(covariant EditProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userData != oldWidget.userData) {
      _updateDisplayDataFromWidgetData();
      _currentUserId = widget.userData['id'] as int;
    }
  }

  void _updateDisplayDataFromWidgetData() {
    if (mounted) {
      setState(() {
        _displayName = widget.userData['name']?.toString() ?? 'User';
        _displayEmail = widget.userData['email']?.toString() ?? 'No email';
      });
    }
  }

  Future<void> _navigateToActualEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActualEditProfileFormScreen(
          initialUserData: widget.userData,
          onUserDataUpdated: (updatedData) {
            widget.onUserDataUpdated?.call(updatedData);
            if (mounted) {
                 setState(() {
                   widget.userData.addAll(updatedData);
                  _updateDisplayDataFromWidgetData();
                 });
            }
          },
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic> && mounted) {
       _updateDisplayDataFromWidgetData();
    }
  }

  void _navigateToAboutScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutScreen()),
    );
  }

  void _navigateToSavedAddressesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SavedAddressesScreen()),
    );
  }

  void _navigateToVehicleManagementScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleManagementScreen(userId: _currentUserId),
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Clear the saved user data from the device
    await SessionManager.clearUserData();

    // Navigate back to the WelcomeScreen and remove all previous routes
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (Route<dynamic> route) => false,
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

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
          Container(
            padding: const EdgeInsets.all(20.0),
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
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
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _displayEmail,
                  style: theme.textTheme.bodyMedium,
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
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Saved Addresses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _navigateToSavedAddressesScreen,
          ),
          ListTile(
            leading: const Icon(Icons.directions_car_outlined), 
            title: const Text('My Vehicles'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _navigateToVehicleManagementScreen, 
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
            onTap: () { // MODIFIED onTap
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () { // MODIFIED onTap
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
              );
            },
          ),
          const Divider(height: 32, thickness: 1),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text('Logout', style: TextStyle(color: theme.colorScheme.error)),
            onTap: _handleLogout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
