import 'package:flutter/material.dart';
import '../api.dart';

class ActualEditProfileFormScreen extends StatefulWidget {
  final Map<String, dynamic> initialUserData;
  final Function(Map<String, dynamic> updatedUserData)? onUserDataUpdated;

  const ActualEditProfileFormScreen({
    super.key,
    required this.initialUserData,
    this.onUserDataUpdated,
  });

  @override
  _ActualEditProfileFormScreenState createState() =>
      _ActualEditProfileFormScreenState();
}

class _ActualEditProfileFormScreenState
    extends State<ActualEditProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  // MODIFIED: Controllers for first and last name
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  int? _userId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userId = widget.initialUserData['id'] as int?;

    // Split initial full name into first and last names
    String initialFullName = widget.initialUserData['name']?.toString() ?? '';
    String initialFirstName = '';
    String initialLastName = '';
    List<String> nameParts = initialFullName.split(' ');
    if (nameParts.isNotEmpty) {
      initialFirstName = nameParts[0];
      if (nameParts.length > 1) {
        initialLastName = nameParts.sublist(1).join(' ').trim();
      }
    }

    _firstNameController = TextEditingController(text: initialFirstName);
    _lastNameController = TextEditingController(text: initialLastName);
    _emailController = TextEditingController(text: widget.initialUserData['email']?.toString() ?? '');
    _addressController = TextEditingController(text: widget.initialUserData['address']?.toString() ?? '');
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      if (_userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: User ID is missing. Cannot update.')),
          );
        }
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // MODIFIED: Combine first and last name to full name for API
      String firstName = _firstNameController.text.trim();
      String lastName = _lastNameController.text.trim();
      String fullName = '$firstName $lastName'.trim();

      try {
        final response = await ApiService.updateUserDetails(
          userId: _userId!,
          name: fullName, // Send combined full name
          email: _emailController.text.trim(),
          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        );

        if (mounted) {
          if (response['status'] == 'success') {
            Map<String, dynamic> updatedUserDataFromResponse =
                response['user_data'] as Map<String, dynamic>? ?? {};
            
            // Ensure the local data is updated with what the server returns
            // including the combined name if the server provides it back directly
            // or construct it if only first/last are returned (though our PHP sends combined)
            Map<String, dynamic> finalUpdatedUserData = Map.from(widget.initialUserData);
            finalUpdatedUserData.addAll(updatedUserDataFromResponse);
             // Ensure the 'name' field in finalUpdatedUserData is the combined one
            finalUpdatedUserData['name'] = fullName; 

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
            
            widget.onUserDataUpdated?.call(finalUpdatedUserData);
            
            Navigator.pop(context, finalUpdatedUserData); // Pop back to Account screen
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] ?? 'Failed to update profile.')),
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
  void dispose() {
    // MODIFIED: Dispose new name controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String displayPhone = widget.initialUserData['country_code']?.toString() ?? '';
    displayPhone += widget.initialUserData['phone']?.toString() ?? '';
    if (displayPhone.isEmpty) {
      displayPhone = "Phone number not available";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (displayPhone.isNotEmpty && displayPhone != "Phone number not available")
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    'Phone: $displayPhone',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                    textAlign: TextAlign.start,
                  ),
                ),
              // MODIFIED: First Name TextFormField
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              // MODIFIED: Last Name TextFormField
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                // Last name can be optional, adjust validator if needed
                validator: (value) {
                  // if (value == null || value.trim().isEmpty) {
                  //   return 'Please enter your last name';
                  // }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                  hintText: 'Enter your address (optional)',
                ),
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,               
                  backgroundColor: Theme.of(context).colorScheme.primary,                
                  minimumSize: const Size(double.infinity, 50), 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), 
                  ),
                  elevation: 5,                                
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10), 
                ),
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : const Text('Save Changes'), 
              ),
            ],
          ),
        ),
      ),
    );
  }
}
