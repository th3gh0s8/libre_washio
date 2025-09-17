import 'package:flutter/material.dart';
import '../api.dart';
import 'add_vehicle_screen.dart';
import 'edit_vehicle_screen.dart';

class VehicleManagementScreen extends StatefulWidget {
  final int userId;

  const VehicleManagementScreen({Key? key, required this.userId}) : super(key: key);

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

  void _refreshVehicles() {
    setState(() {
      _vehiclesFuture = ApiService.getUserVehicles(widget.userId);
    });
  }

  void _navigateToAddVehicle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddVehicleScreen(userId: widget.userId)),
    );
    if (result == true) {
      _refreshVehicles();
    }
  }

  void _navigateToEditVehicle(Map<String, dynamic> vehicle) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditVehicleScreen(vehicle: vehicle)),
    );
    if (result == true) {
      _refreshVehicles();
    }
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this vehicle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // FIXED: Added the vehicleId argument to the deleteVehicle call
        final response = await ApiService.deleteVehicle(vehicleId);
        if (mounted) {
            if (response['status'] == 'success') {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vehicle deleted successfully')),
                );
                _refreshVehicles();
            } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(response['message'] ?? 'Failed to delete vehicle')),
                );
            }
        }
      } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('An error occurred: ${e.toString()}')),
            );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddVehicle,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _vehiclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No vehicles found. Add one!'));
          }

          final vehicles = snapshot.data!;

          return ListView.builder(
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return ListTile(
                title: Text(vehicle['vehicle_model'] ?? 'N/A'),
                subtitle: Text(vehicle['vehicle_no'] ?? 'N/A'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _navigateToEditVehicle(vehicle),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteVehicle(vehicle['id'] as int),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
