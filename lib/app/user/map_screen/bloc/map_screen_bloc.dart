import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

part 'map_screen_event.dart';
part 'map_screen_state.dart';

class MapScreenBloc extends Bloc<MapScreenEvent, MapScreenState> {
  MapScreenBloc() : super(const MapScreenState()) {
    on<MapScreenStarted>(_onStarted);
  }

  final Location location = Location();

  FutureOr<void> _onStarted(
      MapScreenStarted event, Emitter<MapScreenState> emit) async {
    emit(state.copyWith(
      status: () => MapScreenStatus.loading,
    ));

    final currentLocation = await location.getLocation();

    final marker = await _addMarkerForUser(
        LatLng(currentLocation.latitude ?? 0, currentLocation.longitude ?? 0),
        currentLocation.heading ?? 0);

    emit(state.copyWith(
        status: () => MapScreenStatus.loaded,
        markers: () => {marker},
        userLocation: () => LatLng(
            currentLocation.latitude ?? 0, currentLocation.longitude ?? 0)));
  }

  static Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    Codec codec = await instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<Marker> _addMarkerForUser(LatLng latLng, double heading) async {
    final markerIcon = BitmapDescriptor.fromBytes(
        await _getBytesFromAsset("assets/markers/front.png", 150));

    return Marker(
        rotation: heading,
        markerId: const MarkerId('user'),
        position: latLng,
        icon: markerIcon);
  }
}
