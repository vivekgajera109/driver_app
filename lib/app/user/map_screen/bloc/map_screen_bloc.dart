import 'dart:async';
import 'dart:ui';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

part 'map_screen_event.dart';
part 'map_screen_state.dart';

class MapScreenBloc extends Bloc<MapScreenEvent, MapScreenState> {
  // Constructor for MapScreenBloc
  MapScreenBloc() : super(MapScreenState()) {
    _onInit();
  }

  _onInit() async {
    // Define event handlers
    on<MapScreenStarted>(_onStarted);
    on<MapScreenMapCreated>(_onMapCreated);
  }

  // Initialize Location instance for getting user's location
  final Location location = Location();

  // Event handler for MapScreenStarted event
  FutureOr<void> _onStarted(
      MapScreenStarted event, Emitter<MapScreenState> emit) async {
    // Emit a new state with loading status
    emit(state.copyWith(
      status: () => MapScreenStatus.loading,
    ));

    await _startUserLiveLocation(emit);
  }

  _startUserLiveLocation(Emitter<MapScreenState> emit) async {
    location.changeSettings(interval: 10);
    await emit.forEach(
      location.onLocationChanged,
      onData: (data) {
        _locationEmitter(emit, data);
        return state;
      },
    );
  }

  _onMapCreated(MapScreenMapCreated event, Emitter<MapScreenState> emit) {
    emit(state.copyWith(
      mapController: () => event.mapController,
    ));
  }

  // Utility function to get byte data from an asset
  static Future<Uint8List> _getBytesFromAsset(value) async {
    ByteData data = await rootBundle.load(value['path']);
    Codec codec = await instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: value['width']);
    FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  // Function to add a marker for the user
  Future<Marker> _addMarkerForUser(LatLng latLng, double heading) async {
    final markerIcon = BitmapDescriptor.fromBytes(
        // await compute(
        //   _getBytesFromAsset, {'path': "assets/markers/top.png", "width": 150}));
        await _getBytesFromAsset(
            {'path': "assets/markers/top.png", "width": 150}));

    return Marker(
        rotation: heading + 90,
        anchor: const Offset(0.5, 0.5),
        markerId: const MarkerId('user'),
        position: latLng,
        icon: markerIcon);
  }

  _locationEmitter(
      Emitter<MapScreenState> emit, LocationData currentLocation) async {
    // Add a marker for the user's location
    final marker = await _addMarkerForUser(
        LatLng(currentLocation.latitude ?? 0, currentLocation.longitude ?? 0),
        currentLocation.heading ?? 0);

    // Emit a new state with loaded status, updated markers, and user location
    emit(state.copyWith(
        status: () => MapScreenStatus.loaded,
        markers: () => {marker},
        userLocation: () => LatLng(
            currentLocation.latitude ?? 0, currentLocation.longitude ?? 0)));
  }
}
