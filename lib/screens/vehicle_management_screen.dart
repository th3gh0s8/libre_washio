import 'package:flutter/material.dart';
import '../api.dart'; 
import './add_vehicle_screen.dart';
import './edit_vehicle_screen.dart';

class VehicleManagementScreen extends StatefulWidget {
  final int userId;

  const VehicleManagementScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _VehicleManagementScreenState createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  late Future<List<Map<String, dynamic>>> _vehiclesFuture;

  @override
  void initState() {
    super.initState();
    _vehiclesFuture = ApiService.getUserVehicles(widget.userId);
  }

  Future<void> _refreshVehicles() async {
    setState(() {
      _vehiclesFuture = ApiService.getUserVehicles(widget.userId);
    });
  }

  Future<void> _navigateToAddVehicleScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddVehicleScreen(userId: widget.userId),
      ),
    );
    if (result == true) {
      _refreshVehicles();
    }
  }

  Future<void> _navigateToEditVehicleScreen(Map<String, dynamic> vehicleData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVehicleScreen(
          userId: widget.userId,
          vehicleData: vehicleData,
        ),
      ),
    );
    if (result == true) {
      _refreshVehicles();
    }
  }

  void _showDeleteVehicleDialog(int vehicleId, String vehicleNo) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete vehicle "$vehicleNo"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(ctx).pop(); // Close dialog immediately
                try {
                  final response = await ApiService.deleteVehicle(
                    vehicleId: vehicleId,
                    userId: widget.userId,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(response['message'] ?? 'Vehicle delete status unknown'), backgroundColor: response['status'] == 'success' ? Colors.green : Colors.red),
                    );
                    if (response['status'] == 'success') {
                      _refreshVehicles();
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'car':
        return Icons.directions_car_filled_outlined;
      case 'motorcycle':
      case 'bike':
        return Icons.two_wheeler_outlined;
      case 'van':
        return Icons.airport_shuttle_outlined;
      case 'suv':
        return Icons.rv_hookup_outlined;
      default:
        return Icons.directions_car_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshVehicles,
            tooltip: 'Refresh Vehicles',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _vehiclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildErrorWidget(theme);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyStateWidget(theme);
          }

          final vehicles = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              final vehicleId = vehicle['vehicle_id'] as int;
              final vehicleNo = vehicle['vehicle_no'] ?? 'N/A';
              final vehicleType = vehicle['vehicle_type'] ?? 'N/A';
              final vehicleModel = vehicle['vehicle_model'] ?? 'N/A';
              final vehicleIcon = _getVehicleIcon(vehicleType);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                elevation: 2.0,
                shadowColor: theme.shadowColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Icon(
                        vehicleIcon,
                        color: theme.colorScheme.primary,
                        size: 26,
                      ),
                    ),
                    title: Text(vehicleNo, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('$vehicleType - $vehicleModel', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: Colors.blue.shade600),
                          tooltip: 'Edit Vehicle',
                          onPressed: () => _navigateToEditVehicleScreen(vehicle),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                          tooltip: 'Delete Vehicle',
                          onPressed: () => _showDeleteVehicleDialog(vehicleId, vehicleNo),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddVehicleScreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
        tooltip: 'Add a new vehicle',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildErrorWidget(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 80, color: theme.colorScheme.error.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text('Failed to Load Vehicles', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t fetch your vehicle list. Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_transfer_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text('No Vehicles Found', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              'Add your vehicles to get started with our services faster.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
