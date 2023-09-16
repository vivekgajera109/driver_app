part of 'map_screen_bloc.dart';

enum MapScreenStatus {
  loading,
  fetchingUserLocation,
  loaded,
  creatingRoute,
  routeCreated,
}

@immutable
class MapScreenState extends Equatable {
  MapScreenState(
      {this.userLocation = const LatLng(0, 0),
      this.status = MapScreenStatus.loading,
      this.mapController,
      this.markers = const {}});
  final LatLng userLocation;
  final Set<Marker> markers;
  final MapScreenStatus status;
  final GoogleMapController? mapController;

  @override
  List<Object?> get props => [userLocation, status, markers, mapController];

  MapScreenState copyWith({
    LatLng Function()? userLocation,
    MapScreenStatus Function()? status,
    Set<Marker> Function()? markers,
    GoogleMapController Function()? mapController,
  }) {
    return MapScreenState(
      userLocation: userLocation != null ? userLocation() : this.userLocation,
      status: status != null ? status() : this.status,
      markers: markers != null ? markers() : this.markers,
      mapController:
          mapController != null ? mapController() : this.mapController,
    );
  }
}
