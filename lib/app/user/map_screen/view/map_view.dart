part of 'map_page.dart';

class MapScreenView extends StatelessWidget {
  const MapScreenView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<MapScreenBloc, MapScreenState>(
        builder: (context, state) {
          if (state.status == MapScreenStatus.loading) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }
          return GoogleMap(
              onMapCreated: (controller) {
                context
                    .read<MapScreenBloc>()
                    .add(MapScreenMapCreated(controller));
              },
              markers: state.markers,
              initialCameraPosition:
                  CameraPosition(target: state.userLocation, zoom: 15));
        },
      ),
    );
  }
}
