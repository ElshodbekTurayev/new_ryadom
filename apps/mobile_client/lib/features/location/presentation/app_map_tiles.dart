import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../ui/ui.dart';

/// Standard OpenStreetMap basemap — the one tile source every map in the app
/// uses. Keyless: CARTO's basemaps now require an API key and render an
/// "API KEY REQUIRED" watermark without one.
TileLayer appTileLayer(BuildContext context) => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'uz.ryadom.mobile_client',
      maxNativeZoom: 19,
    );

/// Required attribution for the OSM tiles, as a quiet pill.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text('© OpenStreetMap', style: AppText.micro.copyWith(color: AppColors.ink500)),
    );
  }
}
