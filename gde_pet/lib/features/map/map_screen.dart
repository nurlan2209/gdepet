import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  static final LatLng _astanaCenter = LatLng(51.169392, 71.449074);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.favorite_border,
            color: Colors.black,
            size: 28,
          ),
          onPressed: () {},
        ),
        title: const Text(
          'Карта',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(initialCenter: _astanaCenter, initialZoom: 12.0),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName:
                'com.zharkynismagulov.gde_pet', 
          ),
        ],
      ),
    );
  }
}
