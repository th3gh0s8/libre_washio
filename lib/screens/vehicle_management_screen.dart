import 'package:flutter/material.dart';
import '../api.dart'; // Import ApiService
import './add_vehicle_screen.dart'; // Import the new add vehicle screen
import './edit_vehicle_screen.dart'; // Import the new edit vehicle screen

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
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoadingVehicles = true;
  String? _vehicleError;

  @override
  void initState() {
    super.initState();
    _fetchUserVehicles();
  }

  Future<void> _fetchUserVehicles() async {
    if (!mounted) return;
    setState(() {
      _isLoadingVehicles = true;
      _vehicleError = null;
    });
    try {
      final vehicles = await ApiService.getUserVehicles(widget.userId);
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _isLoadingVehicles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingVehicles = false;
          _vehicleError = "Failed to load vehicles: ${e.toString()}";
        });
      }
    }
  }

  Future<void> _navigateToAddVehicleScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddVehicleScreen(userId: widget.userId),
      ),
    );

    if (result == true && mounted) {
      _fetchUserVehicles(); // Refresh the list if a vehicle was added
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

    if (result == true && mounted) {
      _fetchUserVehicles(); // Refresh the list if a vehicle was updated
    }
  }

  void _showDeleteVehicleDialog(int vehicleId, String vehicleNo) {
    bool isDialogDeleting = false;
    showDialog(
      context: context,
      barrierDismissible: !isDialogDeleting,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Confirm Delete'),
              content: Text('Are you sure you want to delete vehicle "$vehicleNo"? This action cannot be undone.'),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: isDialogDeleting ? null : () => Navigator.of(ctx).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: isDialogDeleting 
                      ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) 
                      : Text('Delete'),
                  onPressed: isDialogDeleting ? null : () async {
                    setDialogState(() => isDialogDeleting = true);
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
                          Navigator.of(ctx).pop();
                          _fetchUserVehicles(); 
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setDialogState(() => isDialogDeleting = false);
                      }
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildVehicleList() {
    if (_isLoadingVehicles) {
      return Center(child: CircularProgressIndicator());
    }
    if (_vehicleError != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_vehicleError!, style: TextStyle(color: Colors.red), textAlign: TextAlign.center,)));
    }
    if (_vehicles.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('No vehicles registered yet.', textAlign: TextAlign.center,),
      ));
    }

    return ListView.builder(
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        final vehicleId = vehicle['vehicle_id'] as int;
        final vehicleNo = vehicle['vehicle_no'] ?? 'N/A';
        final vehicleType = vehicle['vehicle_type'] ?? 'N/A';
        final vehicleModel = vehicle['vehicle_model'] ?? 'N/A';

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: ListTile(
            leading: Icon(Icons.directions_car, color: Theme.of(context).primaryColor),
            title: Text(vehicleNo, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$vehicleType - $vehicleModel'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: Colors.blueAccent),
                  tooltip: 'Edit Vehicle',
                  onPressed: () => _navigateToEditVehicleScreen(vehicle), // Updated to call new navigation method
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Delete Vehicle',
                  onPressed: () => _showDeleteVehicleDialog(vehicleId, vehicleNo),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Vehicles'),
      ),
      body: _buildVehicleList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddVehicleScreen, 
        icon: Icon(Icons.add),
        label: Text('Add Vehicle'),
        tooltip: 'Add a new vehicle',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
