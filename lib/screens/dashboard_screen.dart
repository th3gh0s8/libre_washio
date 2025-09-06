import 'package:flutter/material.dart';
import 'edit_profile_screen.dart'; 

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
    _initializeScreens(); // Initialize screens once with initial user data
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the userData provided to AppShell itself changes, re-initialize
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

  // Callback for EditProfileScreen to update AppShell's user data
  void _handleUserDataUpdateFromProfile(Map<String, dynamic> newUserData) {
    setState(() {
      _currentActionUserData = newUserData;
      // Re-initialize screens to ensure they all get the updated user data
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
      body: IndexedStack( // Use IndexedStack to keep state of screens
        index: _selectedIndex,
        children: _screens, // Use the state variable _screens
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
        selectedItemColor: Colors.blue, // Or your theme's primary color
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // To show all labels
      ),
    );
  }
}

// --- DashboardScreen (Home tab content) ---
class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String userName = userData['name']?.toString() ?? 'User';

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
