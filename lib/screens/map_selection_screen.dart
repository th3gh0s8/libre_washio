import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({Key? key}) : super(key: key);

  @override
  _MapSelectionScreenState createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng _lastMapPosition = const LatLng(37.42796133580664, -122.085749655962); // Default to GooglePlex

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: const LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  void _onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }
  }

  void _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }

  void _selectLocation() {
    // In a real app, you might want to do reverse geocoding here
    // to get an address from _lastMapPosition before returning.
    // For now, we just return the LatLng.
    Navigator.pop(context, _lastMapPosition);
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
            initialCameraPosition: _kGooglePlex,
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            myLocationEnabled: true, // Shows current location blue dot if permissions are granted
            myLocationButtonEnabled: true, // Button to center on user's location
          ),
          // You could add a marker in the center of the map if desired
          // const Center(
          //   child: Icon(Icons.location_pin, size: 40.0, color: Colors.red),
          // ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectLocation,
        label: const Text('Select Current Center'),
        icon: const Icon(Icons.location_on),
      ),
    );
  }
}

// You might want to define a class to return more structured location data
// class SelectedLocationData {
//   final LatLng coordinates;
//   final String? address; // For future use with geocoding

//   SelectedLocationData({required this.coordinates, this.address});
// }
