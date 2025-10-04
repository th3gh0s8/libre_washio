import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../api.dart';
import '../cart_provider.dart';

class ServicesScreen extends StatefulWidget {
  final Map<String, dynamic>? stationData;

  const ServicesScreen({super.key, this.stationData});

  @override
  State<ServicesScreen> createState() => ServicesScreenState();
}

class ServicesScreenState extends State<ServicesScreen> {
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
    if (widget.stationData != null) {
      _fetchServicesForStation(widget.stationData!); 
    } else {
      _fetchStations();
    }
  }

  Future<void> _fetchStations() async {
    if (!mounted) return;
    setState(() {
      _isLoadingStations = true;
      _stationError = null;
      _selectedStation = null; 
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

  String _formatEstimatedTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) {
      return 'N/A';
    }
    return timeStr; 
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
            leading: Icon(Icons.storefront_outlined, color: Theme.of(context).colorScheme.primary, size: 30),
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
    if (_selectedStation == null) return const SizedBox.shrink();

    final stationName = _selectedStation!['name']?.toString() ?? 'Station';
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\$');

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
        shrinkWrap: true, 
        physics: const NeverScrollableScrollPhysics(), 
        itemCount: _servicesForSelectedStation.length,
        separatorBuilder: (context, index) => Divider(
          height: 1, 
          indent: 16, 
          endIndent: 16,
          color: theme.dividerColor, 
        ),
        itemBuilder: (context, index) {
          final service = _servicesForSelectedStation[index];
          final serviceName = service['service_name']?.toString() ?? 'Unnamed Service';
          final priceValue = (service['service_price'] as num?)?.toDouble() ?? 0.0;
          final formattedServicePrice = currencyFormatter.format(priceValue);
          final estimatedTime = _formatEstimatedTime(service['estimated_time']?.toString());

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, 
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName, 
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2, // Added maxLines
                        overflow: TextOverflow.ellipsis, // Added overflow
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedServicePrice, // Used formatted price
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary, 
                          fontWeight: FontWeight.w600
                        ),
                        maxLines: 1, // Added maxLines
                        overflow: TextOverflow.ellipsis, // Added overflow
                      ),
                      if (estimatedTime != 'N/A') ...[
                        const SizedBox(height: 4),
                        Text(
                          'Time: $estimatedTime',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1, // Added maxLines
                          overflow: TextOverflow.ellipsis, // Added overflow
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16), 
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final cart = Provider.of<CartProvider>(context, listen: false);
                      final itemToAdd = {
                        ...service,
                        'station_id': _selectedStation!['id'],
                      };
                      cart.addItem(itemToAdd);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$serviceName added to cart'),
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'UNDO',
                            onPressed: () => cart.removeItem(itemToAdd),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20), 
                    child: Ink(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                         boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26), // Modern replacement for withAlpha
                              blurRadius: 3,
                              offset: const Offset(1,1),
                            )
                          ]
                      ),
                      child: const SizedBox(
                        width: 40, 
                        height: 40,
                        child: Icon(Icons.add_shopping_cart, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, 
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            color: theme.colorScheme.primaryContainer.withAlpha(77), // Modern replacement for withAlpha
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(Icons.store, size: 40, color: theme.colorScheme.onSecondaryContainer),
                ),
                const SizedBox(height: 12),
                Text(
                  stationName, 
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  "Open", // Placeholder
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Divider(
            indent: 16, 
            endIndent: 16, 
            height: 1,
            color: theme.dividerColor, 
          ), 
          servicesContent,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isViewingStationDetails = _selectedStation != null;
    bool wasNavigatedToWithData = widget.stationData != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isViewingStationDetails ? '' : 'Service Stations'), 
        actions: [
          if (!isViewingStationDetails)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoadingStations ? null : _fetchStations,
              tooltip: 'Refresh Stations',
            ),
          if (isViewingStationDetails && !wasNavigatedToWithData)
            IconButton(
              icon: const Icon(Icons.close), 
              onPressed: _clearSelectedStation,
              tooltip: 'Back to stations list',
            ),
        ],
      ),
      body: isViewingStationDetails ? _buildSelectedStationServices() : _buildStationsList(),
    );
  }
}
