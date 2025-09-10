import 'package:flutter/material.dart';
import '../api.dart'; // Import ApiService

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

  void _showAddOrEditVehicleDialog({Map<String, dynamic>? vehicleToEdit}) {
    final isEditing = vehicleToEdit != null;
    final _vehicleFormKey = GlobalKey<FormState>();
    String dialogTitle = isEditing ? 'Edit Vehicle' : 'Add New Vehicle';

    final TextEditingController vehicleNoController =
        TextEditingController(text: vehicleToEdit?['vehicle_no']?.toString() ?? '');
    final TextEditingController vehicleTypeController =
        TextEditingController(text: vehicleToEdit?['vehicle_type']?.toString() ?? '');
    final TextEditingController vehicleModelController =
        TextEditingController(text: vehicleToEdit?['vehicle_model']?.toString() ?? '');
    
    bool isDialogSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: !isDialogSubmitting, // Prevent dismissal during submission
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(dialogTitle),
              content: Form(
                key: _vehicleFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: vehicleNoController,
                        decoration: InputDecoration(labelText: 'Vehicle Number', hintText: 'e.g., ABC-1234'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter vehicle number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: vehicleTypeController,
                        decoration: InputDecoration(labelText: 'Vehicle Type', hintText: 'e.g., Car, Bike'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter vehicle type';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: vehicleModelController,
                        decoration: InputDecoration(labelText: 'Vehicle Model', hintText: 'e.g., Toyota Corolla'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter vehicle model';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: isDialogSubmitting ? null : () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: isDialogSubmitting 
                      ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) 
                      : Text(isEditing ? 'Save Changes' : 'Add Vehicle'),
                  onPressed: isDialogSubmitting ? null : () async {
                    if (_vehicleFormKey.currentState!.validate()) {
                      setDialogState(() => isDialogSubmitting = true);
                      try {
                        final vehicleNo = vehicleNoController.text.trim();
                        final vehicleType = vehicleTypeController.text.trim();
                        final vehicleModel = vehicleModelController.text.trim();
                        Map<String, dynamic> response;

                        if (isEditing) {
                          response = await ApiService.updateVehicle(
                            vehicleId: vehicleToEdit!['vehicle_id'] as int,
                            userId: widget.userId,
                            vehicleNo: vehicleNo,
                            vehicleType: vehicleType,
                            vehicleModel: vehicleModel,
                          );
                        } else {
                          response = await ApiService.addVehicle(
                            userId: widget.userId,
                            vehicleNo: vehicleNo,
                            vehicleType: vehicleType,
                            vehicleModel: vehicleModel,
                          );
                        }

                        if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text(response['message'] ?? (isEditing ? 'Vehicle updated' : 'Vehicle added')), backgroundColor: response['status'] == 'success' ? Colors.green : Colors.red),
                           );
                          if (response['status'] == 'success') {
                            Navigator.of(context).pop();
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
                           setDialogState(() => isDialogSubmitting = false);
                         }
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
                  onPressed: () => _showAddOrEditVehicleDialog(vehicleToEdit: vehicle),
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
        onPressed: () => _showAddOrEditVehicleDialog(),
        icon: Icon(Icons.add),
        label: Text('Add Vehicle'),
        tooltip: 'Add a new vehicle',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}