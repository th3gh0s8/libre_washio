import 'package:flutter/material.dart';
import '../api.dart';
import './map_selection_screen.dart';

class SavedAddressesScreen extends StatefulWidget {
  final int userId;

  const SavedAddressesScreen({super.key, required this.userId});

  @override
  _SavedAddressesScreenState createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  late Future<List<Map<String, dynamic>>> _addressesFuture;

  @override
  void initState() {
    super.initState();
    _addressesFuture = ApiService.getUserAddresses(widget.userId);
  }

  Future<void> _refreshAddresses() async {
    setState(() {
      _addressesFuture = ApiService.getUserAddresses(widget.userId);
    });
  }

  Future<void> _navigateToMapSelection(String addressType) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(
          addressType: addressType,
          userId: widget.userId,
        ),
      ),
    );

    if (result == true && mounted) {
      _refreshAddresses();
    }
  }

  Widget _buildAddressTile({
    required BuildContext context,
    required String type,
    required IconData icon,
    required Map<String, dynamic>? addressData,
  }) {
    final theme = Theme.of(context);
    final bool hasAddress = addressData != null;
    final title = hasAddress ? addressData['Address_Type'] : 'Add $type';
    final subtitle = hasAddress
        ? (addressData['Map_Address'] ?? 'No address details')
        : 'Save your $type address';

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.secondary, size: 28),
      title: Text(title, style: TextStyle(fontWeight: hasAddress ? FontWeight.bold : FontWeight.normal)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Icon(
        hasAddress ? Icons.edit_outlined : Icons.add_circle_outline,
        color: hasAddress ? Colors.blue.shade600 : Colors.green.shade600,
        size: 26,
      ),
      onTap: () => _navigateToMapSelection(type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Addresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAddresses,
            tooltip: 'Refresh Addresses',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _addressesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allAddresses = snapshot.data ?? [];
          final homeAddress = allAddresses.firstWhere(
            (addr) => addr['Address_Type'] == 'Home',
            orElse: () => <String, dynamic>{},
          );
          final workAddress = allAddresses.firstWhere(
            (addr) => addr['Address_Type'] == 'Work',
            orElse: () => <String, dynamic>{},
          );
          final otherAddresses = allAddresses.where((addr) => addr['Address_Type'] != 'Home' && addr['Address_Type'] != 'Work').toList();

          return ListView(
            children: [
              _buildAddressTile(
                context: context,
                type: 'Home',
                icon: Icons.home_outlined,
                addressData: homeAddress.isNotEmpty ? homeAddress : null,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildAddressTile(
                context: context,
                type: 'Work',
                icon: Icons.work_outline,
                addressData: workAddress.isNotEmpty ? workAddress : null,
              ),
              const Divider(height: 1),
              if (otherAddresses.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Other Locations',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ...otherAddresses.map((addr) => _buildAddressTile(
                      context: context,
                      type: 'Other',
                      icon: Icons.location_on_outlined,
                      addressData: addr,
                    )),
              ]
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToMapSelection('Other'),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add New Address'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
