import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../api.dart'; // Import ApiService

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({Key? key}) : super(key: key);

  @override
  _ServicesScreenState createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  // State for stations list
  List<Map<String, dynamic>> _stations = [];
  bool _isLoadingStations = true;
  String? _stationError;

  // State for selected station and its services
  Map<String, dynamic>? _selectedStation;
  List<Map<String, dynamic>> _servicesForSelectedStation = [];
  bool _isLoadingServices = false;
  String? _serviceError;

  @override
  void initState() {
    super.initState();
    _fetchStations();
  }

  Future<void> _fetchStations() async {
    if (!mounted) return;
    setState(() {
      _isLoadingStations = true;
      _stationError = null;
      _selectedStation = null; // Clear selected station on refresh
      _servicesForSelectedStation = [];
    });

    try {
      final stations = await ApiService.getStations();
      if (mounted) {
        setState(() {
          _stations = stations;
          _isLoadingStations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStations = false;
          _stationError = "Failed to load stations: ${e.toString()}";
        });
      }
    }
  }

  Future<void> _fetchServicesForStation(Map<String, dynamic> stationData) async {
    if (!mounted || stationData['id'] == null) return;
    final int stationId = stationData['id'] as int;

    setState(() {
      _selectedStation = stationData;
      _isLoadingServices = true;
      _servicesForSelectedStation = [];
      _serviceError = null;
    });

    try {
      final services = await ApiService.getServicesForStation(stationId);
      if (mounted) {
        setState(() {
          _servicesForSelectedStation = services;
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingServices = false;
          _serviceError = "Failed to load services for ${stationData['name']}: ${e.toString()}";
        });
      }
    }
  }

  void _clearSelectedStation() {
    setState(() {
      _selectedStation = null;
      _servicesForSelectedStation = [];
      _isLoadingServices = false;
      _serviceError = null;
    });
  }

  // Helper to format estimated time if it's a DATETIME string
  String _formatEstimatedTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      // Assuming estimated_time in station_services is just a TIME type or an interval stored as string HH:MM:SS
      // If it's a full DATETIME string from which you only want time:
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat.jm().format(dateTime); // Example: 5:30 PM
      // If it's already a duration string like '00:30:00' for 30 minutes, you might parse and format differently or use as is.
      // For simplicity, if it's just a time like "00:30:00", let's try to show HH:MM
      // if (dateTimeStr.length == 8 && dateTimeStr[2] == ':' && dateTimeStr[5] == ':') {
      //   return dateTimeStr.substring(0, 5); // Returns HH:MM
      // }
    } catch (e) {
      // If parsing fails, return the original string or a placeholder
      return dateTimeStr; // Or 'Invalid time format'
    }
    return dateTimeStr; // Fallback
  }

  Widget _buildStationsList() {
    if (_isLoadingStations) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_stationError != null) {
      return Center(
          child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_stationError!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center)));
    }
    if (_stations.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No service stations found.', style: TextStyle(fontSize: 16), textAlign: TextAlign.center)));
    }
    return ListView.builder(
      itemCount: _stations.length,
      itemBuilder: (context, index) {
        final station = _stations[index];
        final stationName = station['name']?.toString() ?? 'Unnamed Station';
        final stationAddress = station['address']?.toString() ?? 'No address provided';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          elevation: 3,
          child: ListTile(
            leading: Icon(Icons.storefront_outlined, color: Theme.of(context).primaryColor, size: 30),
            title: Text(stationName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(stationAddress, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _fetchServicesForStation(station),
          ),
        );
      },
    );
  }

  Widget _buildSelectedStationServices() {
    if (_selectedStation == null) return const SizedBox.shrink(); // Should not happen if this widget is built

    final stationName = _selectedStation!['name']?.toString() ?? 'Station';
    final stationAddress = _selectedStation!['address']?.toString() ?? 'N/A';

    Widget servicesContent;
    if (_isLoadingServices) {
      servicesContent = const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()));
    } else if (_serviceError != null) {
      servicesContent = Center(
          child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_serviceError!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center)));
    } else if (_servicesForSelectedStation.isEmpty) {
      servicesContent = const Center(
          child: Padding(padding: EdgeInsets.all(16.0), child: Text('No services listed for this station.', style: TextStyle(fontSize: 16), textAlign: TextAlign.center)));
    } else {
      servicesContent = ListView.separated(
        shrinkWrap: true, // Important for ListView inside Column
        physics: const NeverScrollableScrollPhysics(), // If inside another scrollable
        itemCount: _servicesForSelectedStation.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final service = _servicesForSelectedStation[index];
          final serviceName = service['service_name']?.toString() ?? 'Unnamed Service';
          final servicePrice = service['service_price'] != null ? '\u20B9${(service['service_price'] as num).toStringAsFixed(2)}' : 'Price not available';
          final estimatedTime = _formatEstimatedTime(service['estimated_time']?.toString());

          return ListTile(
            title: Text(serviceName, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text('Time: $estimatedTime'),
            trailing: Text(servicePrice, style: TextStyle(color: Theme.of(context).primaryColorDark, fontWeight: FontWeight.bold)),
            // onTap: () { /* TODO: Maybe navigate to service booking or details */ }
          );
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Services at:', style: Theme.of(context).textTheme.labelLarge),
          Text(stationName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(stationAddress, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text('Available Services', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          servicesContent,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isViewingStationDetails = _selectedStation != null;

    return Scaffold(
      appBar: AppBar(
        leading: isViewingStationDetails 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _clearSelectedStation,
                tooltip: 'Back to stations list',
              )
            : null, // No leading when showing stations list (handled by bottom nav back behavior)
        title: Text(isViewingStationDetails ? (_selectedStation!['name']?.toString() ?? 'Station Services') : 'Service Stations'),
        automaticallyImplyLeading: !isViewingStationDetails, // Show default back if not viewing details (e.g. from bottom nav)
        actions: [
          if (!isViewingStationDetails) // Only show refresh for stations list
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoadingStations ? null : _fetchStations,
              tooltip: 'Refresh Stations',
            ),
        ],
      ),
      body: isViewingStationDetails ? _buildSelectedStationServices() : _buildStationsList(),
    );
  }
}
