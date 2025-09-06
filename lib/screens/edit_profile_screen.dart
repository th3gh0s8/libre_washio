import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../theme_provider.dart'; // Assuming theme_provider.dart is in lib/
import '../api.dart'; 

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic> updatedUserData)? onUserDataUpdated; // Callback

  const EditProfileScreen({
    Key? key, 
    required this.userData,
    this.onUserDataUpdated, // Add to constructor
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  String _displayPhone = ""; 
  int? _userId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _updateControllersFromWidgetData();
  }

  @override
  void didUpdateWidget(covariant EditProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the userData passed to the widget changes, update the controllers
    if (widget.userData != oldWidget.userData) {
      _updateControllersFromWidgetData();
    }
  }

  void _updateControllersFromWidgetData() {
    _userId = widget.userData['id'] as int?;
    _nameController = TextEditingController(text: widget.userData['name']?.toString() ?? '');
    _emailController = TextEditingController(text: widget.userData['email']?.toString() ?? '');
    _addressController = TextEditingController(text: widget.userData['address']?.toString() ?? '');
    String phone = widget.userData['phone']?.toString() ?? ''; 
    _displayPhone = phone; 
    // If a field was being edited and widget rebuilds with same data, selection might be lost.
    // Storing and restoring selection is an advanced topic if this becomes an issue.
  }


  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      if (_userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User ID is missing. Cannot update.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final response = await ApiService.updateUserDetails(
          userId: _userId!, 
          name: _nameController.text,
          email: _emailController.text,
          address: _addressController.text.isNotEmpty ? _addressController.text : null,
        );

        if (mounted) {
          if (response['status'] == 'success') {
            Map<String, dynamic> updatedUserData = response['user_data'] ?? widget.userData;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
            
            // Call the callback if provided
            if (widget.onUserDataUpdated != null) {
              widget.onUserDataUpdated!(updatedUserData);
            }
            
            // Pop if this screen was pushed onto a navigator stack
            // If it's directly in AppShell, pop might not be the intended behavior
            // but AppShell will handle its own state update via the callback.
            if (Navigator.canPop(context)) {
              Navigator.pop(context, updatedUserData); 
            }

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
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'), // Changed title for consistency
        automaticallyImplyLeading: false, // AppShell handles navigation
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_displayPhone.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    'Phone: $_displayPhone',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
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
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,               
                  backgroundColor: Colors.blue,                
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
