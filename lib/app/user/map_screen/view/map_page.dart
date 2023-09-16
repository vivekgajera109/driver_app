import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_map_app/app/user/map_screen/bloc/map_screen_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
part 'map_view.dart';

class MapScreenPage extends StatelessWidget {
  const MapScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MapScreenBloc()..add(MapScreenStarted()),
      child: const MapScreenView(),
    );
  }
}
