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
  bool _isProgrammaticMove = false;

  // No longer using _effectiveInitialCameraPosition or _isInitializingMap for initial load handling by spinner

  static final CameraPosition _kInitialNeutralView = CameraPosition(
    target: const LatLng(0, 0),
    zoom: 2.0,
  );

  @override
  void initState() {
    super.initState();
    // No initial setup here that would cause a loading screen before map display
  }

  Future<void> _animateToInitialCountryView() async {
    // This function is called once the map is created.
    // It attempts to get current location and animate to a country-level view.
    if (mounted) {
      try {
        final PermissionStatus permission = await Permission.locationWhenInUse.request();
        if (permission == PermissionStatus.granted) {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (serviceEnabled) {
            final Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
            );
            final GoogleMapController controller = await _mapController.future;
            if (mounted) {
              setState(() {
                _isProgrammaticMove = true;
                _isMapCenteredOnUser = true; // Reflecting that we are centering on a version of user location
                _lastMapPosition = LatLng(position.latitude, position.longitude);
              });
              controller.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(position.latitude, position.longitude),
                  zoom: 6.0, // Country-level zoom
                ),
              ));
            }
          }
        }
      } catch (e) {
        print('Error animating to initial country view: $e');
        // If error, map stays at _kInitialNeutralView. _isMapCenteredOnUser remains false.
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentUserLocation() async { 
    if (!_locationFeaturesEnabled && mounted) {
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
            _isProgrammaticMove = true;
            _isMapCenteredOnUser = true;
            _lastMapPosition = LatLng(position.latitude, position.longitude);
          });
        }
        
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0, 
          ),
        ));

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error getting location: ${e.toString()}')),
          );
          if (mounted && _isMapCenteredOnUser) {
            setState((){
              _isMapCenteredOnUser = false;
            });
          }
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(permission == PermissionStatus.denied 
              ? 'Location permission denied.'
              : 'Location permission permanently denied. Please enable it in app settings.')),
        );
        if (mounted && _isMapCenteredOnUser) {
          setState((){
            _isMapCenteredOnUser = false;
          });
        }
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_mapController.isCompleted) {
      _mapController.complete(controller);
    }
    // Animate to country view after map is created and controller is available.
    _animateToInitialCountryView();

    // Enable other location features like blue dot and FAB after a slight delay
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
      _lastMapPosition = position.target;
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
        _isProgrammaticMove = false;
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
    // No more _isInitializingMap check; Scaffold is built immediately.
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
            initialCameraPosition: _kInitialNeutralView, // Always start with neutral view
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
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
