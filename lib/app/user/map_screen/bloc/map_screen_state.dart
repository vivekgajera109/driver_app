part of 'map_screen_bloc.dart';

enum MapScreenStatus {
  loading,
  fetchingUserLocation,
  loaded,
  creatingRoute,
  routeCreated,
}

class MapScreenState extends Equatable {
  const MapScreenState(
      {this.userLocation = const LatLng(0, 0),
      this.status = MapScreenStatus.loading,
      this.markers = const {}});
  final LatLng userLocation;
  final Set<Marker> markers;
  final MapScreenStatus status;

  @override
  List<Object> get props => [userLocation, status, markers];

  MapScreenState copyWith({
    LatLng Function()? userLocation,
    MapScreenStatus Function()? status,
    Set<Marker> Function()? markers,
  }) {
    return MapScreenState(
      userLocation: userLocation != null ? userLocation() : this.userLocation,
      status: status != null ? status() : this.status,
      markers: markers != null ? markers() : this.markers,
    );
  }
}
