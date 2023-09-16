part of 'map_screen_bloc.dart';

class MapScreenEvent extends Equatable {
  const MapScreenEvent();

  @override
  List<Object> get props => [];
}

class MapScreenStarted extends MapScreenEvent {}

class MapScreenStartUserLocation extends MapScreenEvent {}

class MapScreenOnSearchingStart extends MapScreenEvent {
  final String searchPlace;

  const MapScreenOnSearchingStart(this.searchPlace);
}

class MapScreenOnSearchingCancel extends MapScreenEvent {
  final bool clearAll;

  const MapScreenOnSearchingCancel({required this.clearAll});
}

class MapScreenOnSearchPlaceSelected extends MapScreenEvent {
  final String address;

  const MapScreenOnSearchPlaceSelected({required this.address});
}

class MapScreenMapCreated extends MapScreenEvent {
  final GoogleMapController mapController;

  const MapScreenMapCreated(this.mapController);
}
