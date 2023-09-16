part of 'map_page.dart';

class MapScreenView extends StatefulWidget {
  const MapScreenView({
    super.key,
  });

  @override
  State<MapScreenView> createState() => _MapScreenViewState();
}

class _MapScreenViewState extends State<MapScreenView> {
  FocusNode searchField = FocusNode();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    searchField.addListener(() {
      if (searchField.hasFocus) {
        context
            .read<MapScreenBloc>()
            .add(MapScreenOnSearchingStart(searchController.text));
      } else {
        if (searchController.text.isEmpty) {
          context
              .read<MapScreenBloc>()
              .add(const MapScreenOnSearchingCancel(clearAll: false));
        }
      }
    });
  }

  final searchController = TextEditingController();

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
          if (state.status == MapScreenStatus.noLocationPermission) {
            return Center(
              child: MaterialButton(
                onPressed: () async {
                  if (await Permission.locationWhenInUse.isGranted) {
                    context.read<MapScreenBloc>().add(MapScreenStarted());
                  } else {
                    openAppSettings();
                  }
                },
                child: Text("Allow Location Permission"),
              ),
            );
          }
          return Stack(
            children: [
              GoogleMap(
                  polylines: state.polyline,
                  mapToolbarEnabled: false,
                  onTap: (argument) {
                    primaryFocus?.unfocus();
                  },
                  onMapCreated: (controller) {
                    context
                        .read<MapScreenBloc>()
                        .add(MapScreenMapCreated(controller));
                  },
                  markers: state.markers,
                  initialCameraPosition:
                      CameraPosition(target: state.userLocation, zoom: 15)),
              if (state.searchStatus == LocationSearchStatus.searching)
                Container(
                  color: Colors.white,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 80,
                      ),
                      Expanded(
                          child: SafeArea(
                        child: ListView.builder(
                          // physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final item = state.searchedPlaces[index];

                            return ListTile(
                              onTap: () {
                                searchController.text = item.fullText;
                                context.read<MapScreenBloc>().add(
                                    MapScreenOnSearchPlaceSelected(
                                        address: item.fullText));
                                searchField.unfocus();
                              },
                              leading: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 20,
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    '${((item.distanceMeters ?? 0) / 1000).toStringAsFixed(1)} km',
                                    style: const TextStyle(fontSize: 10),
                                  )
                                ],
                              ),
                              title: Text(
                                item.primaryText,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                item.secondaryText,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w300),
                              ),
                            );
                          },
                          itemCount: state.searchedPlaces.length,
                        ),
                      ))
                    ],
                  ),
                ),
              Positioned(
                  left: 0,
                  right: 0,
                  top: 50,
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: searchController,
                      focusNode: searchField,
                      onChanged: (value) {
                        context
                            .read<MapScreenBloc>()
                            .add(MapScreenOnSearchingStart(value));
                      },
                      decoration: InputDecoration(
                          prefixIcon: state.searchStatus ==
                                  LocationSearchStatus.searching
                              ? IconButton(
                                  onPressed: () {
                                    searchField.unfocus();
                                  },
                                  icon: const Icon(Icons.arrow_back))
                              : const Icon(Icons.search),
                          suffixIcon: state.searchStatus ==
                                  LocationSearchStatus.searching
                              ? IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                  },
                                  icon: const Icon(Icons.close))
                              : searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed: () {
                                        searchController.clear();
                                        context.read<MapScreenBloc>().add(
                                            const MapScreenOnSearchingCancel(
                                                clearAll: true));
                                      },
                                      icon: const Icon(Icons.close)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          constraints: const BoxConstraints(maxHeight: 45),
                          border: const OutlineInputBorder(
                              borderSide: BorderSide.none)),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
