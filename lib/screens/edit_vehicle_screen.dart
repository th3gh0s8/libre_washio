import 'package:flutter/material.dart';
import '../api.dart';

class EditVehicleScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const EditVehicleScreen({Key? key, required this.vehicle}) : super(key: key);

  @override
  _EditVehicleScreenState createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _vehicleNoController;
  late TextEditingController _vehicleTypeController;
  late TextEditingController _vehicleModelController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _vehicleNoController = TextEditingController(text: widget.vehicle['vehicle_no']);
    _vehicleTypeController = TextEditingController(text: widget.vehicle['vehicle_type']);
    _vehicleModelController = TextEditingController(text: widget.vehicle['vehicle_model']);
  }

  Future<void> _updateVehicle() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await ApiService.updateVehicle(
          vehicleId: widget.vehicle['id'] as int,
          vehicleNo: _vehicleNoController.text,
          vehicleType: _vehicleTypeController.text,
          vehicleModel: _vehicleModelController.text,
        );

        if (mounted) {
            if (response['status'] == 'success') {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vehicle updated successfully')),
                );
                Navigator.of(context).pop(true);
            } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(response['message'] ?? 'Failed to update vehicle')),
                );
            }
        }
      } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('An error occurred: ${e.toString()}')),
            );
        }
      } finally {
        if (mounted) {
            setState(() {
                _isLoading = false;
            });
        }
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
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _vehicleNoController,
                decoration: const InputDecoration(labelText: 'Vehicle Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vehicle number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _vehicleTypeController,
                decoration: const InputDecoration(labelText: 'Vehicle Type'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vehicle type';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _vehicleModelController,
                decoration: const InputDecoration(labelText: 'Vehicle Model'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vehicle model';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateVehicle,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Update Vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
