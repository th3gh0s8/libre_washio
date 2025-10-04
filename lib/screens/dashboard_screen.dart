import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../cart_provider.dart';
import '../api.dart'; 
import 'edit_profile_screen.dart'; 
import 'map_selection_screen.dart'; 
import './services_screen.dart';
import './orders_screen.dart';

// --- AppShell Widget (Manages Bottom Navigation) ---
class AppShell extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AppShell({super.key, required this.userData});

  @override
  AppShellState createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
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
      DashboardScreen(userData: _currentActionUserData),
      const ServicesScreen(),
      OrdersScreen(userId: widget.userData['id'] as int),
      EditProfileScreen(
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
    if (_selectedIndex >= _screens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: IndexedStack( 
        index: _selectedIndex,
        children: _screens, 
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.miscellaneous_services), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue, 
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, 
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cart, child) {
          return cart.itemCount > 0
              ? Badge(
                  label: Text(cart.itemCount.toString()),
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/cart', arguments: widget.userData['id'] as int);
                    },
                    child: const Icon(Icons.shopping_cart),
                  ),
                )
              : const SizedBox.shrink(); 
        },
      ),
    );
  }
}

// --- DashboardScreen (Home tab content) ---
class DashboardScreen extends StatefulWidget { 
  final Map<String, dynamic> userData;

  const DashboardScreen({super.key, required this.userData});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> { 
  String? _selectedAddress;
  late Future<List<Map<String, dynamic>>> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.userData['address'] as String?;
    _dashboardDataFuture = _fetchDashboardData();
  }

  Future<List<Map<String, dynamic>>> _fetchDashboardData() async {
    try {
      final List<Map<String, dynamic>> stations = await ApiService.getStations();
      if (stations.isEmpty) return [];

      List<Map<String, dynamic>> stationsWithServices = [];
      for (var stationData in stations) {
        try {
          final List<Map<String, dynamic>> services = await ApiService.getServicesForStation(stationData['id'] as int);
          stationsWithServices.add({
            'station_data': stationData,
            'station_services': services,
          });
        } catch (e) {
          stationsWithServices.add({
            'station_data': stationData,
            'station_services': [],
            'error_loading_services': e.toString(),
          });
        }
      }
      return stationsWithServices;
    } catch (e) {
      throw Exception("Failed to load station data: ${e.toString()}");
    }
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userData['address'] != oldWidget.userData['address']) {
      setState(() {
        _selectedAddress = widget.userData['address'] as String?;
      });
    }
  }

  Future<void> _navigateToMapAndGetAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(
          userId: widget.userData['id'] as int,
          addressType: 'DisplayLocation',
        ),
      ),
    );
    if (result is String && result.isNotEmpty && mounted) {
      setState(() {
        _selectedAddress = result;
      });
    }
  }

  void _showLocationSelectionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: ApiService.getUserAddresses(widget.userData['id'] as int),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snapshot.error}')));
            }
            final addresses = snapshot.data ?? [];
            return ListView(
              children: [
                ...addresses.map((addr) {
                  // Corrected keys to lowercase to match the API response.
                  final addressType = addr['address_type'] ?? 'Address';
                  final mapAddress = addr['map_address'] ?? '';
                  final icon = addressType == 'Home' ? Icons.home : (addressType == 'Work' ? Icons.work : Icons.location_on);

                  return ListTile(
                    leading: Icon(icon),
                    title: Text(addressType),
                    subtitle: Text(mapAddress, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      setState(() {
                        _selectedAddress = mapAddress;
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
                ListTile(
                  leading: const Icon(Icons.add_location_alt_outlined),
                  title: const Text('Select new location on map'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToMapAndGetAddress();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToStationServices(Map<String, dynamic> stationData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServicesScreen(stationData: stationData),
      ),
    );
  }

  String _getShortenedAddress(String? fullAddress) {
    if (fullAddress == null || fullAddress.isEmpty) return "Set your location";
    const int maxLengthPreferred = 35;
    if (fullAddress.length <= maxLengthPreferred) return fullAddress;
    List<String> parts = fullAddress.split(',');
    if (parts.length >= 2) return '${parts[0].trim()}, ${parts[1].trim()}';
    if (parts.isNotEmpty) return parts[0].trim();
    return fullAddress;
  }

  Widget _buildLocationDisplayWidget(BuildContext context, String? currentAddress, VoidCallback onTap) {
    final theme = Theme.of(context);
    String displayAddress = _getShortenedAddress(currentAddress);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0)),
        child: Row(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Flexible(
              child: Text(displayAddress, style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface), overflow: TextOverflow.ellipsis, maxLines: 1, softWrap: false)),
            const SizedBox(width: 4.0), 
            Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface.withAlpha(179), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesDisplay(BuildContext context, List<Map<String, dynamic>> availableServices, Map<String, dynamic> servicesStation, {String? errorLoadingServices}) {
    final theme = Theme.of(context);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    String stationName = servicesStation['name']?.toString() ?? 'Nearby Station';

    if (errorLoadingServices != null) {
      return Padding(padding: const EdgeInsets.all(8.0), child: Text("Could not load services for $stationName: $errorLoadingServices", style: TextStyle(color: theme.colorScheme.error, fontSize: 14)));
    }

    if (availableServices.isEmpty) {
      return Padding(padding: const EdgeInsets.all(16.0), child: Center(child: Text("No services available from $stationName at the moment.", style: const TextStyle(fontSize: 16), textAlign: TextAlign.center)));
    }
    
    int displayedItemCountLimit = 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(stationName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        ...availableServices.take(displayedItemCountLimit).map((service) {
          final serviceName = service['service_name']?.toString() ?? 'Unnamed Service';
          final priceValue = (service['service_price'] as num?)?.toDouble() ?? 0.0;
          final formattedServicePrice = currencyFormatter.format(priceValue);
          
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              dense: true,
              title: Text(serviceName, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis, maxLines: 1),
              subtitle: Text(formattedServicePrice, style: TextStyle(color: theme.colorScheme.primary), overflow: TextOverflow.ellipsis, maxLines: 1),
              trailing: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final itemToAdd = { ...service, 'station_id': servicesStation['id'] };
                    cart.addItem(itemToAdd);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$serviceName added to cart'), duration: const Duration(seconds: 2), action: SnackBarAction(label: 'UNDO', onPressed: () => cart.removeItem(itemToAdd))),
                    );
                  },
                  borderRadius: BorderRadius.circular(20), 
                  child: Ink(
                    decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, offset: const Offset(1,1))]),
                    child: const SizedBox(width: 40, height: 40, child: Icon(Icons.add_shopping_cart, color: Colors.white, size: 22)),
                  ),
                ),
              ),
            ),
          );
        }),
        if (availableServices.length > displayedItemCountLimit) 
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton(onPressed: () => _navigateToStationServices(servicesStation), child: const Text("View All Services...")),
          ),
         const SizedBox(height: 16), 
         const Divider(), 
         const SizedBox(height: 16), 
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _buildLocationDisplayWidget(context, _selectedAddress, _showLocationSelectionSheet),
        titleSpacing: 0, 
        automaticallyImplyLeading: false, 
        centerTitle: false, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _dashboardDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 50.0), child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Padding(padding: const EdgeInsets.all(16.0), child: Text("Error fetching dashboard content: ${snapshot.error}", style: TextStyle(color: theme.colorScheme.error, fontSize: 16), textAlign: TextAlign.center));
                }
                if (snapshot.hasData) {
                  final List<Map<String, dynamic>> stationsWithData = snapshot.data!;

                  if (stationsWithData.isEmpty) {
                     return const Padding(padding: const EdgeInsets.all(16.0), child: Center(child: Text("No service stations found.", style: TextStyle(fontSize: 16), textAlign: TextAlign.center)));
                  }

                  List<Widget> stationWidgets = [];
                  for (var stationEntry in stationsWithData) {
                    final stationData = stationEntry['station_data'] as Map<String, dynamic>; 
                    final stationServices = stationEntry['station_services'] as List<Map<String, dynamic>>;
                    final String? serviceLoadError = stationEntry['error_loading_services'] as String?;

                    stationWidgets.add(_buildServicesDisplay(context, stationServices, stationData, errorLoadingServices: serviceLoadError));
                  }
                  
                  return Column(children: stationWidgets);

                } else {
                  return const Padding(padding: const EdgeInsets.all(16.0), child: Center(child: Text("No data loaded for stations.", style: TextStyle(fontSize: 16))));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
