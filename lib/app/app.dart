import 'package:flutter/material.dart';
import 'package:google_map_app/app/user/map_screen/map_screen.dart';

class MapApp extends StatelessWidget {
  const MapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MapScreenPage());
  }
}
