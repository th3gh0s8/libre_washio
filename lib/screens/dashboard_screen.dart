import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For LatLng
import 'edit_profile_screen.dart'; 
import 'map_selection_screen.dart'; // Import the new map screen

// --- AppShell Widget (Manages Bottom Navigation) ---
class AppShell extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AppShell({Key? key, required this.userData}) : super(key: key);

  @override
  _AppShellState createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  late Map<String, dynamic> _currentActionUserData;

  @override
  void initState() {
    super.initState();
    _currentActionUserData = widget.userData;
    _initializeScreens(); 
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userData != oldWidget.userData) {
      setState(() {
        _currentActionUserData = widget.userData;
        _initializeScreens();
      });
    }
  }

  void _initializeScreens() {
    _screens = [
      DashboardScreen(userData: _currentActionUserData), // Home
      const BrowseScreen(), // Browse
      const OrdersScreen(), // Orders
      EditProfileScreen( // Account
        userData: _currentActionUserData, 
        onUserDataUpdated: _handleUserDataUpdateFromProfile,
      ),
    ];
  }

  void _handleUserDataUpdateFromProfile(Map<String, dynamic> newUserData) {
    setState(() {
      _currentActionUserData = newUserData;
      _initializeScreens(); 
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack( 
        index: _selectedIndex,
        children: _screens, 
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue, 
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, 
      ),
    );
  }
}

// --- DashboardScreen (Home tab content) ---
class DashboardScreen extends StatefulWidget { 
  final Map<String, dynamic> userData;

  const DashboardScreen({Key? key, required this.userData}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> { 
  LatLng? _selectedCoordinates;
  String _selectedLocationDisplay = "Not Set";

  Future<void> _changeLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapSelectionScreen()),
    );

    if (result != null && result is LatLng) {
      setState(() {
        _selectedCoordinates = result;
        // For now, just display LatLng. In a real app, do reverse geocoding here.
        _selectedLocationDisplay = "Lat: ${result.latitude.toStringAsFixed(4)}, Lng: ${result.longitude.toStringAsFixed(4)}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String userName = widget.userData['name']?.toString() ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'), 
        automaticallyImplyLeading: false, 
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome, $userName!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'This is your Washio Dashboard.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Text(
                'Current Location: $_selectedLocationDisplay',
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _changeLocation,
                child: const Text('Change Location'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Placeholder Screens ---
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Browse Screen - Coming Soon!', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Orders Screen - Coming Soon!', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
