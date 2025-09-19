import 'package:flutter/material.dart';
import './map_selection_screen.dart'; // Ensure this path is correct

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  void _navigateToMapSelection(BuildContext context, String addressType) {
    // TODO: Replace '1' with the actual logged-in user ID from your auth system/state management
    int currentUserId = 1; 

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(
          addressType: addressType,
          userId: currentUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Addresses'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(0), 
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Addresses', 
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
                  tooltip: 'Add New Address',
                  iconSize: 28,
                  onPressed: () {
                    _navigateToMapSelection(context, 'Other'); // 'Other' or 'Generic' for the general add button
                  },
                ),
              ],
            ),
          ),
          const Divider(),

          ListTile(
            leading: Icon(Icons.home_outlined, color: theme.colorScheme.secondary, size: 28),
            title: const Text('Add Home'),
            subtitle: const Text('Save your home address for faster checkout'),
            trailing: Icon(Icons.add_circle_outline, color: Colors.green[600], size: 26),
            onTap: () {
              _navigateToMapSelection(context, 'Home');
            },
          ),
          const Divider(indent: 16, endIndent: 16),

          ListTile(
            leading: Icon(Icons.work_outline, color: theme.colorScheme.secondary, size: 28),
            title: const Text('Add Work'),
            subtitle: const Text('Save your work address for convenience'),
            trailing: Icon(Icons.add_circle_outline, color: Colors.green[600], size: 26),
            onTap: () {
              _navigateToMapSelection(context, 'Work');
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
