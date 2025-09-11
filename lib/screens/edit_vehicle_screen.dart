import 'package:flutter/material.dart';
import '../api.dart'; // Import ApiService

class EditVehicleScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic> vehicleData;

  const EditVehicleScreen({
    super.key,
    required this.userId,
    required this.vehicleData,
  });

  @override
  _EditVehicleScreenState createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _vehicleFormKey = GlobalKey<FormState>();
  late TextEditingController _vehicleNoController;
  late TextEditingController _vehicleTypeController;
  late TextEditingController _vehicleModelController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _vehicleNoController = TextEditingController(text: widget.vehicleData['vehicle_no']?.toString() ?? '');
    _vehicleTypeController = TextEditingController(text: widget.vehicleData['vehicle_type']?.toString() ?? '');
    _vehicleModelController = TextEditingController(text: widget.vehicleData['vehicle_model']?.toString() ?? '');
  }

  @override
  void dispose() {
    _vehicleNoController.dispose();
    _vehicleTypeController.dispose();
    _vehicleModelController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdateVehicle() async {
    if (!_vehicleFormKey.currentState!.validate()) {
      return; // Form is not valid
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      final vehicleNo = _vehicleNoController.text.trim();
      final vehicleType = _vehicleTypeController.text.trim();
      final vehicleModel = _vehicleModelController.text.trim();
      final vehicleId = widget.vehicleData['vehicle_id'] as int;

      final response = await ApiService.updateVehicle(
        vehicleId: vehicleId,
        userId: widget.userId,
        vehicleNo: vehicleNo,
        vehicleType: vehicleType,
        vehicleModel: vehicleModel,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Vehicle updated successfully'),
          backgroundColor: response['status'] == 'success' ? Colors.green : Colors.red,
        ),
      );

      if (response['status'] == 'success') {
        Navigator.pop(context, true); // Pop with true to indicate success
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating vehicle: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Vehicle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _vehicleFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _vehicleNoController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number',
                  hintText: 'e.g., ABC-1234',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter vehicle number';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehicleTypeController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  hintText: 'e.g., Car, Bike, Van',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car_filled_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter vehicle type';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehicleModelController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Model',
                  hintText: 'e.g., Toyota Corolla, Honda CB Shine',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.branding_watermark_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter vehicle model';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _isSubmitting
                    ? Container(
                        width: 20,
                        height: 20,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_alt_outlined),
                label: Text(_isSubmitting ? 'SAVING CHANGES...' : 'Save Changes'),
                onPressed: _isSubmitting ? null : _submitUpdateVehicle,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
