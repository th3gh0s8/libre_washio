import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; 

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

  static final CameraPosition _kInitialNeutralView = CameraPosition(
    target: const LatLng(0, 0),
    zoom: 2.0,
  );

  @override
  void initState() {
    super.initState();
  }

  Future<void> _animateToInitialCountryView() async {
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
                _isMapCenteredOnUser = true; 
                _lastMapPosition = LatLng(position.latitude, position.longitude);
              });
              controller.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(position.latitude, position.longitude),
                  zoom: 6.0, 
                ),
              ));
            }
          }
        }
      } catch (e) {
        print('Error animating to initial country view: $e');
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
    _animateToInitialCountryView();
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

  Future<void> _selectLocation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fetching address...'), duration: Duration(seconds: 1)),
    );

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _lastMapPosition.latitude,
        _lastMapPosition.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String formattedAddress = "";
        if (place.street != null && place.street!.isNotEmpty) formattedAddress += "${place.street}, ";
        if (place.subLocality != null && place.subLocality!.isNotEmpty) formattedAddress += "${place.subLocality}, ";
        if (place.locality != null && place.locality!.isNotEmpty) formattedAddress += "${place.locality}, ";
        if (place.postalCode != null && place.postalCode!.isNotEmpty) formattedAddress += "${place.postalCode}, ";
        if (place.country != null && place.country!.isNotEmpty) formattedAddress += "${place.country}";
        
        if (formattedAddress.endsWith(", ")) {
            formattedAddress = formattedAddress.substring(0, formattedAddress.length - 2);
        }

        if (mounted) Navigator.pop(context, formattedAddress);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not find address for this location.')),
          );
          Navigator.pop(context, null); 
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching address: ${e.toString()}')),
        );
        Navigator.pop(context, null); 
      }
    }
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
        title: const Text('Select Location'), // Title restored
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
