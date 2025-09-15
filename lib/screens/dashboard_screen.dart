import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../cart_provider.dart';
import './cart_screen.dart';
import 'edit_profile_screen.dart'; 
import 'map_selection_screen.dart'; 
import './services_screen.dart';

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
      DashboardScreen(userData: _currentActionUserData), // Home (Index 0)
      const ServicesScreen(), // Services (Index 1) - Now imported
      const BrowseScreen(), // Browse (Index 2)
      const OrdersScreen(), // Orders (Index 3)
      EditProfileScreen( // Account (Index 4)
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
            icon: Icon(Icons.miscellaneous_services),
            label: 'Services',
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
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cart, child) {
          // Only show the button if there are items in the cart
          return cart.itemCount > 0
              ? Badge(
                  label: Text(cart.itemCount.toString()),
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/cart');
                    },
                    child: const Icon(Icons.shopping_cart),
                  ),
                )
              : const SizedBox.shrink(); // Return an empty widget if cart is empty
        },
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
  String? _selectedAddress; 

  Future<void> _navigateToMapAndGetAddress() async {
    dynamic rawUserId = widget.userData['id'];
    int userId = 0; 
    if (rawUserId is int) {
      userId = rawUserId;
    } else if (rawUserId is String) {
      userId = int.tryParse(rawUserId) ?? 0;
    }

    const String addressType = 'DisplayLocation';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(
          addressType: addressType,
          userId: userId,
        ),
      ),
    );

    if (result == true) {
      debugPrint("MapSelectionScreen indicated a save attempt for 'DisplayLocation' was successful.");
    } else {
      debugPrint("Map selection did not return a successful save confirmation. Result: $result");
    }
  }

  String _getShortenedAddress(String? fullAddress) {
    if (fullAddress == null || fullAddress.isEmpty) {
      return "Set your location";
    }
    const int maxLengthPreferred = 35; 
    if (fullAddress.length <= maxLengthPreferred) {
      return fullAddress;
    }
    List<String> parts = fullAddress.split(',');
    if (parts.length >= 2) {
      String shortened = '${parts[0].trim()}, ${parts[1].trim()}';
      return shortened;
    }
    if (parts.isNotEmpty) {
      return parts[0].trim();
    }
    return fullAddress; 
  }

  Widget _buildLocationDisplayWidget(BuildContext context, String? currentAddress, VoidCallback onTap) {
    final theme = Theme.of(context);
    String displayAddress = _getShortenedAddress(currentAddress);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0), 
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0), 
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Flexible(
              child: Text(
                displayAddress, 
                style: TextStyle(
                  fontSize: 14.0, 
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface, 
                ),
                overflow: TextOverflow.ellipsis, 
                maxLines: 1,
                softWrap: false,
              ),
            ),
            const SizedBox(width: 4.0), 
            Icon(
              Icons.arrow_drop_down, 
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              size: 20
            ), 
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String userName = widget.userData['name']?.toString() ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: _buildLocationDisplayWidget(context, _selectedAddress, _navigateToMapAndGetAddress),
        titleSpacing: 0, 
        automaticallyImplyLeading: false, 
      ),
      body: Padding( 
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, 
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            const SizedBox(height: 16), 
            Text(
              'Welcome, $userName!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'This is your Washio Dashboard.',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Placeholder Screens (ServicesScreen has been moved to its own file) ---

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
        title: const Text('My Orders'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Orders Screen - Coming Soon!', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
