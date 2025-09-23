import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../api.dart';

class MapSelectionScreen extends StatefulWidget {
  final String addressType;
  final int userId;

  const MapSelectionScreen({
    super.key, 
    required this.addressType,
    required this.userId,
  });

  @override
  MapSelectionScreenState createState() => MapSelectionScreenState();
}

class MapSelectionScreenState extends State<MapSelectionScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng _lastMapPosition = const LatLng(20.5937, 78.9629); 
  final TextEditingController _searchController = TextEditingController();

  bool _locationFeaturesEnabled = false;
  bool _isMapCenteredOnUser = false;
  bool _isProgrammaticMove = false;
  bool _isProcessingLocation = false;

  static final CameraPosition _kInitialNeutralView = CameraPosition(
    target: const LatLng(20.5937, 78.9629), 
    zoom: 3.0,
  );

  @override
  void initState() {
    super.initState();
    _animateToInitialCountryView(); 
  }

  Future<void> _animateToInitialCountryView() async {
    if (!mounted) return;
    try {
      final PermissionStatus permission = await Permission.locationWhenInUse.request();
      if (permission == PermissionStatus.granted) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          final Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
          );
          _lastMapPosition = LatLng(position.latitude, position.longitude);
          final GoogleMapController controller = await _mapController.future;
          if (mounted) {
            controller.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(target: _lastMapPosition, zoom: 6.0),
            ));
            setState(() {
              _isProgrammaticMove = true;
              _isMapCenteredOnUser = true;
            });
          }
          return; 
        }
      }
    } catch (e) {
      debugPrint('Error animating to initial country view: $e');
    }
    if (mounted && _mapController.isCompleted) {
        final GoogleMapController controller = await _mapController.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(_kInitialNeutralView));
    } else if (mounted) {
        // If controller not ready, _lastMapPosition is already at default
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentUserLocation() async {
    if (!mounted) return;
    if (!_locationFeaturesEnabled) {
      setState(() {
        _locationFeaturesEnabled = true;
      });
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final PermissionStatus permission = await Permission.locationWhenInUse.request();
    if (permission == PermissionStatus.granted) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
          return;
        }
        final Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        final GoogleMapController controller = await _mapController.future;
        if (mounted) {
          _lastMapPosition = LatLng(position.latitude, position.longitude);
          controller.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: _lastMapPosition, zoom: 16.0),
          ));
          setState(() {
            _isProgrammaticMove = true;
            _isMapCenteredOnUser = true;
          });
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error getting location: ${e.toString()}')));
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(permission == PermissionStatus.denied ? 'Location permission denied.' : 'Location permission permanently denied.')));
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_mapController.isCompleted) _mapController.complete(controller);
    if (_lastMapPosition.latitude == _kInitialNeutralView.target.latitude && _lastMapPosition.longitude == _kInitialNeutralView.target.longitude) {
        _animateToInitialCountryView(); 
    }
    if (mounted) setState(() => _locationFeaturesEnabled = true);
  }

  void _onCameraMove(CameraPosition position) {
    if (mounted) {
      _lastMapPosition = position.target;
      if (!_isProgrammaticMove && _isMapCenteredOnUser) {
        setState(() => _isMapCenteredOnUser = false);
      }
    }
  }

  void _onCameraIdle() {
    if (mounted && _isProgrammaticMove) {
      setState(() => _isProgrammaticMove = false);
    }
  }

  Future<void> _sendAddressToApi(Placemark place, LatLng coordinates) async {
    if (!mounted) return;

    String mapAddress = [
      place.name,
      place.street,
      place.subLocality,
      place.locality,
      place.administrativeArea,
      place.postalCode,
      place.country
    ].where((s) => s != null && s.isNotEmpty).toSet().join(', ');
    if (mapAddress.isEmpty) mapAddress = "Selected Location at ${coordinates.latitude.toStringAsFixed(5)}, ${coordinates.longitude.toStringAsFixed(5)}";

    if (widget.addressType == 'DisplayLocation') {
      Navigator.pop(context, mapAddress);
      return;
    }

    if (!_isProcessingLocation && mounted) {
        setState(() => _isProcessingLocation = true);
    }

    String addressLine1 = place.street ?? place.name ?? '';
    String addressLine2 = place.subLocality ?? (place.thoroughfare != place.street ? place.thoroughfare : '') ?? '';
    if (addressLine1.isEmpty) addressLine1 = place.locality ?? 'N/A';

    try {
      final response = await ApiService.saveUserLocation(
        userId: widget.userId,
        addressType: widget.addressType,
        mapAddress: mapAddress,
        latitude: double.parse(coordinates.latitude.toStringAsFixed(7)),
        longitude: double.parse(coordinates.longitude.toStringAsFixed(7)),
        addressLine1: addressLine1,
        addressLine2: addressLine2,
      );

      if (!mounted) return;
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Address saved!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Failed to save address. Server error.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() => _isProcessingLocation = false);
      }
    }
  }

  Future<void> _selectLocation() async {
    if (_isProcessingLocation || !mounted) return;

    setState(() {
      _isProcessingLocation = true;
    });

    if (_mapController.isCompleted ) {
         final GoogleMapController controller = await _mapController.future;
         LatLngBounds visibleRegion = await controller.getVisibleRegion();
        _lastMapPosition = LatLng(
            (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2,
            (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) / 2,
        );
    }
    
    if (!mounted) {
        return; 
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fetching address details...'), duration: Duration(seconds: 2)));

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(_lastMapPosition.latitude, _lastMapPosition.longitude);
      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        await _sendAddressToApi(placemarks.first, _lastMapPosition); 
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not find address for this location.')));
          setState(() {
            _isProcessingLocation = false; 
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching address details: ${e.toString()}')));
        setState(() {
          _isProcessingLocation = false; 
        });
      }
    }
  }

  Future<void> _searchAndGoToLocation() async {
    final String query = _searchController.text;
    if (query.isEmpty || !mounted) return;
    try {
      List<Location> locations = await locationFromAddress(query);
      if (!mounted) return;
      if (locations.isNotEmpty) {
        final GoogleMapController controller = await _mapController.future;
        final targetLocation = LatLng(locations.first.latitude, locations.first.longitude);
        _lastMapPosition = targetLocation; 
        controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: targetLocation, zoom: 15.0)));
        setState(() => _isMapCenteredOnUser = false ); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location "$query" not found.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error searching location: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select ${widget.addressType} Address'),
        actions: [
          if (_isProcessingLocation)
            const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)))
          else
            IconButton(icon: const Icon(Icons.check), tooltip: 'Confirm this location', onPressed: _selectLocation)
        ],
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kInitialNeutralView,
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: _locationFeaturesEnabled,
            myLocationButtonEnabled: false, 
            zoomControlsEnabled: true,
          ),
          const Center(child: IgnorePointer(child: Icon(Icons.location_pin, color: Colors.red, size: 40.0))),
          Positioned(
            top: 10.0, left: 10.0, right: 10.0,
            child: Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(hintText: 'Search location...', border: InputBorder.none),
                        onSubmitted: (_) => _searchAndGoToLocation(),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.search), onPressed: _searchAndGoToLocation, tooltip: 'Search Location'),
                  ],
                ),
              ),
            ),
          ),
          if (_locationFeaturesEnabled)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 80 + 15, 
              right: 15.0,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'myLocationButton',
                backgroundColor: Theme.of(context).colorScheme.secondary,
                tooltip: _isMapCenteredOnUser ? 'Location centered' : 'My Location',
                onPressed: _goToCurrentUserLocation,
                child: Icon(_isMapCenteredOnUser ? Icons.gps_fixed : Icons.my_location, color: Colors.white ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'selectLocationButton',
        onPressed: _isProcessingLocation ? null : _selectLocation,
        label: Text(_isProcessingLocation ? 'PROCESSING...' : 'Confirm ${widget.addressType} Location', style: const TextStyle(color: Colors.white)),
        icon: _isProcessingLocation 
            ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Icon(Icons.check_circle_outline, color: Colors.white),
        backgroundColor: _isProcessingLocation ? Colors.grey : Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
