part of 'map_screen_bloc.dart';

enum MapScreenStatus {
  loading,
  fetchingUserLocation,
  loaded,
  creatingRoute,
  routeCreated,
  noLocationPermission
}

enum LocationSearchStatus { searching, selected, clear, ideal }

@immutable
class MapScreenState extends Equatable {
  const MapScreenState({
    this.userLocation = const LatLng(0, 0),
    this.desLocation,
    this.status = MapScreenStatus.loading,
    this.searchStatus = LocationSearchStatus.ideal,
    this.searchedPlaces = const [],
    this.mapController,
    this.markers = const {},
    this.polyline = const {},
  });
  final LatLng userLocation;
  final LatLng? desLocation;
  final Set<Marker> markers;
  final Set<Polyline> polyline;
  final List<place.AutocompletePrediction> searchedPlaces;
  final MapScreenStatus status;
  final LocationSearchStatus searchStatus;
  final GoogleMapController? mapController;

  @override
  List<Object?> get props => [
        userLocation,
        status,
        markers,
        mapController,
        searchedPlaces,
        searchStatus,
        desLocation,
        polyline
      ];

  MapScreenState copyWith({
    LatLng Function()? userLocation,
    LatLng? Function()? desLocation,
    MapScreenStatus Function()? status,
    Set<Marker> Function()? markers,
    Set<Polyline> Function()? polyline,
    GoogleMapController Function()? mapController,
    List<place.AutocompletePrediction> Function()? searchedPlaces,
    LocationSearchStatus Function()? searchStatus,
  }) {
    return MapScreenState(
      userLocation: userLocation != null ? userLocation() : this.userLocation,
      desLocation: desLocation != null ? desLocation() : this.desLocation,
      polyline: polyline != null ? polyline() : this.polyline,
      markers: markers != null ? markers() : this.markers,
      status: status != null ? status() : this.status,
      searchStatus: searchStatus != null ? searchStatus() : this.searchStatus,
      mapController:
          mapController != null ? mapController() : this.mapController,
      searchedPlaces:
          searchedPlaces != null ? searchedPlaces() : this.searchedPlaces,
    );
  }
}
