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
  // Constructor for MapScreenBloc
  MapScreenBloc() : super(const MapScreenState()) {
    _onInit();
  }

  _onInit() async {
    // Define event handlers
    on<MapScreenStarted>(_onStarted);
    on<MapScreenMapCreated>(_onMapCreated);
    on<MapScreenOnSearchingStart>(_onSearchStart);
    on<MapScreenOnSearchPlaceSelected>(_onSearchPlaceSelected);
    on<MapScreenOnSearchingCancel>(_onSearchCancel);
  }

  final Location location = Location();

  FutureOr<void> _onStarted(
      MapScreenStarted event, Emitter<MapScreenState> emit) async {
    emit(state.copyWith(
      status: () => MapScreenStatus.loading,
    ));
    await Permission.locationWhenInUse.request();
    if (await Permission.locationWhenInUse.status.isGranted) {
      await _startUserLiveLocation(emit);
    } else {
      openAppSettings();
      emit(state.copyWith(
        status: () => MapScreenStatus.noLocationPermission,
      ));
    }
  }

  FutureOr<void> _onSearchPlaceSelected(MapScreenOnSearchPlaceSelected event,
      Emitter<MapScreenState> emit) async {
    emit(state.copyWith(searchStatus: () => LocationSearchStatus.selected));

    final latlng = await gc.locationFromAddress(event.address);
    if (latlng.isNotEmpty) {
      final desMarker = await _addMarkerForDestination(
          LatLng(latlng.first.latitude, latlng.first.longitude));

      final markers = state.markers.toList();
      markers.add(desMarker);
      final polyLine = await _setPolyLines(
          LatLng(latlng.first.latitude, latlng.first.longitude));
      emit(state.copyWith(
          searchStatus: () => LocationSearchStatus.selected,
          markers: markers.toSet,
          polyline: () => {polyLine!},
          desLocation: () =>
              LatLng(latlng.first.latitude, latlng.first.longitude)));
    }
  }

  FutureOr<void> _onSearchStart(
      MapScreenOnSearchingStart event, Emitter<MapScreenState> emit) async {
    if (event.searchPlace.isEmpty) {
      emit(state.copyWith(
        searchedPlaces: () => [],
        searchStatus: () => LocationSearchStatus.searching,
      ));
      return;
    }
    final places =
        place.FlutterGooglePlacesSdk('AIzaSyBybh7pKrXboD9Ck8F87c717UFifO06SmU');
    final result = await places.findAutocompletePredictions(event.searchPlace,
        origin: place.LatLng(
            lat: state.userLocation.latitude,
            lng: state.userLocation.longitude));

    emit(state.copyWith(
        searchStatus: () => LocationSearchStatus.searching,
        searchedPlaces: result.predictions.toList));
  }

  FutureOr<void> _onSearchCancel(
      MapScreenOnSearchingCancel event, Emitter<MapScreenState> emit) async {
    if (event.clearAll) {
      emit(state.copyWith(
        polyline: () => {},
        markers: () => {},
        desLocation: () => null,
        searchedPlaces: () => [],
        searchStatus: () => LocationSearchStatus.clear,
      ));
    } else {
      emit(state.copyWith(
        searchedPlaces: () => [],
        searchStatus: () => LocationSearchStatus.clear,
      ));
    }
  }

  _startUserLiveLocation(Emitter<MapScreenState> emit) async {
    location.changeSettings(
      interval: 10,
    );
    await emit.forEach(
      location.onLocationChanged,
      onData: (data) {
        _locationEmitter(emit, data);
        return state;
      },
    );
  }

  _onMapCreated(MapScreenMapCreated event, Emitter<MapScreenState> emit) async {
    emit(state.copyWith(
      mapController: () => event.mapController,
    ));
  }

  static Future<Uint8List> _getBytesFromAsset(value) async {
    ByteData data = await rootBundle.load(value['path']);
    Codec codec = await instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: value['width']);
    FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<Marker> _addMarkerForUser(LatLng latLng, double heading) async {
    final markerIcon = BitmapDescriptor.fromBytes(
        // await compute(
        //   _getBytesFromAsset, {'path': "assets/markers/top.png", "width": 150}));
        await _getBytesFromAsset(
            {'path': "assets/markers/top.png", "width": 120}));

    return Marker(
        rotation: heading + 90,
        anchor: const Offset(0.5, 0.5),
        markerId: const MarkerId('user'),
        position: latLng,
        icon: markerIcon);
  }

  Future<Marker> _addMarkerForDestination(
    LatLng latLng,
  ) async {
    final markerIcon = BitmapDescriptor.fromBytes(
        // await compute(
        //   _getBytesFromAsset, {'path': "assets/markers/top.png", "width": 150}));
        await _getBytesFromAsset(
            {'path': "assets/markers/des.png", "width": 100}));

    return Marker(
        anchor: const Offset(0.5, 0.5),
        markerId: const MarkerId('destination'),
        position: latLng,
        icon: markerIcon);
  }

  _locationEmitter(
      Emitter<MapScreenState> emit, LocationData currentLocation) async {
    // Add a marker for the user's location
    final marker = await _addMarkerForUser(
        LatLng(currentLocation.latitude ?? 0, currentLocation.longitude ?? 0),
        currentLocation.heading ?? 0);
    final markers = state.markers.toList();

    final polyline = await _setPolyLines(null);
    num totalDistance = 0;
    for (var i = 0; i < polylineCoordinates.length - 1; i++) {
      totalDistance += calculateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude);
    }

    markers.add(marker);
    emit(state.copyWith(
        status: () => MapScreenStatus.loaded,
        markers: () => markers.toSet(),
        polyline: () =>
            {if (polyline != null && totalDistance > 0.08) polyline},
        userLocation: () => LatLng(
            currentLocation.latitude ?? 0, currentLocation.longitude ?? 0)));
  }

  PolylinePoints polylinePoints = PolylinePoints();
  List<LatLng> polylineCoordinates = [];
  Future<Polyline?> _setPolyLines(LatLng? des) async {
    if (state.desLocation == null && des == null) {
      return null;
    }

    PointLatLng origin =
        PointLatLng(state.userLocation.latitude, state.userLocation.longitude);
    PointLatLng destination = PointLatLng(
        des?.latitude ?? state.desLocation!.latitude,
        des?.longitude ?? state.desLocation!.longitude);
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyBybh7pKrXboD9Ck8F87c717UFifO06SmU',
      origin,
      destination,
      // optimizeWaypoints: true,
    );
    polylineCoordinates.clear();
    polylineCoordinates
        .addAll(result.points.map((e) => LatLng(e.latitude, e.longitude)));
    Polyline polyline = Polyline(
        polylineId: const PolylineId("poly"),
        width: 5,
        color: Colors.black,
        points: polylineCoordinates);

    return polyline;
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
