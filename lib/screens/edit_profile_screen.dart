import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../api.dart';
import './actual_edit_profile_form_screen.dart';
import './about_screen.dart';
import './welcome_screen.dart';
import './saved_addresses_screen.dart';
import './vehicle_management_screen.dart'; // <<< NEW IMPORT for Vehicle Management

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
  late int _currentUserId; // To store the user ID for navigation

  @override
  void initState() {
    super.initState();
    _updateDisplayDataFromWidgetData();
    // Ensure 'id' is the correct key for user ID from your userData map
    // and handle potential null or incorrect type if necessary.
    _currentUserId = widget.userData['id'] as int; 
  }

  @override
  void didUpdateWidget(covariant EditProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userData != oldWidget.userData) {
      _updateDisplayDataFromWidgetData();
      // Update user ID if it could change during the lifetime of this widget instance
      _currentUserId = widget.userData['id'] as int;
    }
  }

  void _updateDisplayDataFromWidgetData() {
    _displayName = widget.userData['name']?.toString() ?? 'User';
    _displayEmail = widget.userData['email']?.toString() ?? 'No email';
    // No need to call setState here if initState and didUpdateWidget handle it,
    // unless _navigateToActualEditProfile doesn't guarantee a rebuild that reflects changes.
    // However, since it's called in initState and didUpdateWidget, direct setState might be redundant
    // if those methods correctly trigger rebuilds. For safety or if direct updates are needed:
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _navigateToActualEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActualEditProfileFormScreen(
          initialUserData: widget.userData,
          onUserDataUpdated: (updatedData) {
            // This callback is good for updating the source of truth if needed
            widget.onUserDataUpdated?.call(updatedData);
            // And also update local state if this screen remains visible
            if (mounted) {
                 setState(() {
                   // Merge updatedData into widget.userData if it's the source
                   widget.userData.addAll(updatedData);
                  _updateDisplayDataFromWidgetData(); // Refresh display name/email
                 });
            }
          },
        ),
      ),
    );

    // Fallback if onUserDataUpdated isn't called or further updates are needed
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

  void _navigateToVehicleManagementScreen() { // <<< NEW METHOD
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleManagementScreen(userId: _currentUserId),
      ),
    );
  }

  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (Route<dynamic> route) => false,
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
          ListTile( // <<< NEW LISTTILE FOR VEHICLES
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
