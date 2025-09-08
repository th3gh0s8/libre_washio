import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({Key? key}) : super(key: key);

  @override
  _MapSelectionScreenState createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng _lastMapPosition = const LatLng(0, 0);
  final TextEditingController _searchController = TextEditingController();

  bool _locationFeaturesEnabled = false;
  bool _isMapCenteredOnUser = false;
  bool _isProgrammaticMove = false; // To track camera moves initiated by code

  static final CameraPosition _kInitialNeutralView = CameraPosition(
    target: const LatLng(0, 0),
    zoom: 2.0,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentUserLocation() async {
    if (!_locationFeaturesEnabled) {
      if (mounted) {
        setState(() {
          _locationFeaturesEnabled = true;
        });
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    final PermissionStatus permission = await Permission.locationWhenInUse.request();

    if (permission == PermissionStatus.granted) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location services are disabled.')),
            );
          }
          return;
        }

        final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final GoogleMapController controller = await _mapController.future;

        if (mounted) {
          setState(() {
            _isProgrammaticMove = true; // Indicate that the upcoming move is programmatic
            _isMapCenteredOnUser = true; // Set centered state immediately for icon change
            _lastMapPosition = LatLng(position.latitude, position.longitude);
          });
        }
        
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0,
          ),
        ));
        // Note: _isProgrammaticMove will be reset to false in _onCameraIdle

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error getting location: ${e.toString()}')),
          );
        }
      }
    } else if (permission == PermissionStatus.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
      }
    } else if (permission == PermissionStatus.permanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied. Please enable it in app settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_mapController.isCompleted) {
      _mapController.complete(controller);
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _locationFeaturesEnabled = true;
        });
      }
    });
  }

  void _onCameraMove(CameraPosition position) {
    if (mounted) {
      _lastMapPosition = position.target; // Always update the last known position
      // If the move is not programmatic and the map was centered, un-center it.
      if (!_isProgrammaticMove && _isMapCenteredOnUser) {
        setState(() {
          _isMapCenteredOnUser = false;
        });
      }
    }
  }

  void _onCameraIdle() {
    if (mounted && _isProgrammaticMove) {
      setState(() {
        _isProgrammaticMove = false; // Programmatic move has finished
      });
    }
  }

  void _selectLocation() {
    Navigator.pop(context, _lastMapPosition);
  }

  Future<void> _searchAndGoToLocation() async {
    final String query = _searchController.text;
    if (query.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a location to search.')),
        );
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search for "$query" not implemented yet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Select this location',
            onPressed: _selectLocation,
          )
        ],
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kInitialNeutralView,
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle, // Added camera idle callback
            myLocationEnabled: _locationFeaturesEnabled,
            myLocationButtonEnabled: _locationFeaturesEnabled,
            zoomControlsEnabled: true,
          ),
          const Center(
            child: IgnorePointer(
              child: Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 40.0,
              ),
            ),
          ),
          Positioned(
            top: 10.0,
            left: 10.0,
            right: 10.0,
            child: Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search for a location...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) => _searchAndGoToLocation(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchAndGoToLocation,
                      tooltip: 'Search Location',
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_locationFeaturesEnabled)
            Positioned(
              bottom: 95.0,
              right: 10.0,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.blue,
                tooltip: _isMapCenteredOnUser ? 'Location centered' : 'My Location',
                onPressed: _goToCurrentUserLocation,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Icon(
                    _isMapCenteredOnUser ? Icons.gps_fixed : Icons.my_location,
                    key: ValueKey<bool>(_isMapCenteredOnUser),
                    color: _isMapCenteredOnUser ? Colors.white : Colors.red,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectLocation,
        label: const Text('Select Current Center', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.location_on, color: Colors.white),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
