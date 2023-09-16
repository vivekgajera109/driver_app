import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    as place;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart' as gc;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

part 'map_screen_event.dart';
part 'map_screen_state.dart';

class MapScreenBloc extends Bloc<MapScreenEvent, MapScreenState> {
  MapScreenBloc() : super(const MapScreenState()) {
    _onInit();
  }
// Initialize event handlers for various map screen events
  _onInit() async {
    on<MapScreenStarted>(_onStarted); // Handle MapScreenStarted event
    on<MapScreenMapCreated>(_onMapCreated); // Handle MapScreenMapCreated event
    on<MapScreenOnSearchingStart>(
        _onSearchStart); // Handle MapScreenOnSearchingStart event
    on<MapScreenOnSearchPlaceSelected>(
        _onSearchPlaceSelected); // Handle MapScreenOnSearchPlaceSelected event
    on<MapScreenOnSearchingCancel>(
        _onSearchCancel); // Handle MapScreenOnSearchingCancel event
  }

// Initialize location service
  final Location location = Location();

// Handle MapScreenStarted event
  FutureOr<void> _onStarted(
      MapScreenStarted event, Emitter<MapScreenState> emit) async {
    // Emit a new state with loading status
    emit(state.copyWith(
      status: () => MapScreenStatus.loading,
    ));

    // Request location permission
    await Permission.locationWhenInUse.request();

    // Check if location permission is granted
    if (await Permission.locationWhenInUse.status.isGranted) {
      await _startUserLiveLocation(
          emit); // Start receiving user's live location
    } else {
      openAppSettings(); // Open app settings for location permission
      // Emit a new state with no location permission status
      emit(state.copyWith(
        status: () => MapScreenStatus.noLocationPermission,
      ));
    }
  }

// Handle MapScreenOnSearchPlaceSelected event
  FutureOr<void> _onSearchPlaceSelected(MapScreenOnSearchPlaceSelected event,
      Emitter<MapScreenState> emit) async {
    emit(state.copyWith(
        searchStatus: () =>
            LocationSearchStatus.selected)); // Set search status to selected

    final latlng = await gc
        .locationFromAddress(event.address); // Get location from address
    if (latlng.isNotEmpty) {
      final desMarker =
          await _addMarkerForDestination(// Add marker for destination
              LatLng(latlng.first.latitude, latlng.first.longitude));

      final markers = state.markers.toList(); // Get list of markers
      markers.add(desMarker); // Add destination marker to the list
      final polyLine = await _setPolyLines(// Set polyline for the route
          LatLng(latlng.first.latitude, latlng.first.longitude));
      emit(state.copyWith(
          searchStatus: () =>
              LocationSearchStatus.selected, // Set search status to selected
          markers: markers.toSet, // Update markers
          polyline: () => {polyLine!}, // Set polyline
          desLocation: () => LatLng(latlng.first.latitude,
              latlng.first.longitude) // Set destination location
          ));
    }
  }

// Handle MapScreenOnSearchingStart event
  FutureOr<void> _onSearchStart(
      MapScreenOnSearchingStart event, Emitter<MapScreenState> emit) async {
    // If search place is empty
    if (event.searchPlace.isEmpty) {
      // Emit state with empty searched places and set search status to searching
      emit(state.copyWith(
        searchedPlaces: () => [],
        searchStatus: () => LocationSearchStatus.searching,
      ));
      return; // Return to exit function
    }

    final places = place.FlutterGooglePlacesSdk(
        'AIzaSyBybh7pKrXboD9Ck8F87c717UFifO06SmU'); // Initialize Google Places SDK
    final result = await places.findAutocompletePredictions(
      event.searchPlace,
      origin: place.LatLng(
          lat: state.userLocation.latitude, lng: state.userLocation.longitude),
    );

    // Emit state with updated search status and list of search predictions
    emit(state.copyWith(
      searchStatus: () => LocationSearchStatus.searching,
      searchedPlaces: result.predictions.toList,
    ));
  }

// Handle MapScreenOnSearchingCancel event
  FutureOr<void> _onSearchCancel(
      MapScreenOnSearchingCancel event, Emitter<MapScreenState> emit) async {
    if (event.clearAll) {
      // Clear polyline, markers, destination location, searched places, and set search status to clear
      emit(state.copyWith(
        polyline: () => {},
        markers: () => {},
        desLocation: () => null,
        searchedPlaces: () => [],
        searchStatus: () => LocationSearchStatus.clear,
      ));
    } else {
      // Clear only searched places and set search status to clear
      emit(state.copyWith(
        searchedPlaces: () => [],
        searchStatus: () => LocationSearchStatus.clear,
      ));
    }
  }

// Start receiving user's live location
  _startUserLiveLocation(Emitter<MapScreenState> emit) async {
    location.changeSettings(
      interval: 10,
    );
    await emit.forEach(
      location.onLocationChanged,
      onData: (data) {
        _locationEmitter(
            emit, data); // Call _locationEmitter with location data
        return state; // Return current state
      },
    );
  }

// Handle the event when the map is created
  _onMapCreated(MapScreenMapCreated event, Emitter<MapScreenState> emit) async {
    // Emit a new state with updated map controller
    emit(state.copyWith(
      mapController: () => event.mapController,
    ));
  }

// Static utility function to get bytes from an asset
  static Future<Uint8List> _getBytesFromAsset(value) async {
    // Load byte data from the specified asset path
    ByteData data = await rootBundle.load(value['path']);

    // Create a codec and get the first frame
    Codec codec = await instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: value['width']);
    FrameInfo fi = await codec.getNextFrame();

    // Convert image frame to byte data and return as Uint8List
    return (await fi.image.toByteData(format: ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

// Add a marker for the user's location
  Future<Marker> _addMarkerForUser(LatLng latLng, double heading) async {
    // Load marker icon bytes from asset if not already loaded
    userMarkerBytes ??= await _getBytesFromAsset(
        {'path': "assets/markers/top.png", "width": 120});

    // Create marker icon from loaded bytes
    final markerIcon = BitmapDescriptor.fromBytes(userMarkerBytes ??
        await _getBytesFromAsset(
            {'path': "assets/markers/top.png", "width": 120}));

    // Return a new marker instance
    return Marker(
        rotation: heading + 90,
        anchor: const Offset(0.5, 0.5),
        markerId: const MarkerId('user'),
        position: latLng,
        icon: markerIcon);
  }

  // Add a marker for the destination location
  Future<Marker> _addMarkerForDestination(LatLng latLng) async {
    // Load destination marker bytes from asset if not already loaded
    destinationMarkerBytes ??= await _getBytesFromAsset(
        {'path': "assets/markers/des.png", "width": 120});

    // Create marker icon from loaded bytes
    final markerIcon = BitmapDescriptor.fromBytes(destinationMarkerBytes ??
        await _getBytesFromAsset(
            {'path': "assets/markers/des.png", "width": 100}));

    // Return a new marker instance
    return Marker(
        anchor: const Offset(0.5, 0.5),
        markerId: const MarkerId('destination'),
        position: latLng,
        icon: markerIcon);
  }

// Handle location data and emit state updates
  _locationEmitter(
      Emitter<MapScreenState> emit, LocationData currentLocation) async {
    // Add a marker for the user's location
    final marker = await _addMarkerForUser(
        LatLng(currentLocation.latitude ?? 0, currentLocation.longitude ?? 0),
        currentLocation.heading ?? 0);
    final markers = state.markers.toList();

    // Set up polyline and calculate total distance
    final polyline = await _setPolyLines(null);
    num totalDistance = 0;
    for (var i = 0; i < polylineCoordinates.length - 1; i++) {
      totalDistance += calculateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude);
    }

    // Add the user's marker and emit a new state
    markers.add(marker);
    emit(state.copyWith(
        status: () => MapScreenStatus.loaded,
        markers: () => markers.toSet(),
        polyline: () =>
            {if (polyline != null && totalDistance > 0.08) polyline},
        userLocation: () => LatLng(
            currentLocation.latitude ?? 0, currentLocation.longitude ?? 0)));
  }

// Initialize polyline points and coordinates list, and fetch route between coordinates
  PolylinePoints polylinePoints = PolylinePoints();
  List<LatLng> polylineCoordinates = [];
  Future<Polyline?> _setPolyLines(LatLng? des) async {
    if (state.desLocation == null && des == null) {
      return null; // Return null if destination location is not available
    }

    // Set up origin and destination points for polyline
    PointLatLng origin =
        PointLatLng(state.userLocation.latitude, state.userLocation.longitude);
    PointLatLng destination = PointLatLng(
        des?.latitude ?? state.desLocation!.latitude,
        des?.longitude ?? state.desLocation!.longitude);

    // Fetch polyline result between coordinates
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyBybh7pKrXboD9Ck8F87c717UFifO06SmU',
      origin,
      destination,
    );

    // Clear and update polyline coordinates list, and create a new Polyline instance
    polylineCoordinates.clear();
    polylineCoordinates
        .addAll(result.points.map((e) => LatLng(e.latitude, e.longitude)));
    Polyline polyline = Polyline(
        polylineId: const PolylineId("poly"),
        width: 5,
        color: Colors.black,
        points: polylineCoordinates);

    return polyline; // Return the generated polyline
  }
}

double calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}

final mapStyle = [
  {
    "elementType": "geometry",
    "stylers": [
      {"color": "#f5f5f5"}
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {"color": "#ffffff"}
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {"color": "#c9c9c9"}
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#9e9e9e"}
    ]
  }
];

Uint8List? destinationMarkerBytes;
Uint8List? userMarkerBytes;
