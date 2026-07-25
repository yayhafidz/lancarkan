import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/maps_theme.dart';

class HudPanel extends StatelessWidget {
  const HudPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, provider, child) {
        if (provider.currentLocation == null) return const SizedBox.shrink();

        final isMoving =
            provider.isNavigating && provider.mode == NavMode.dynamic;
        final displaySpeed = isMoving ? provider.effectiveSpeed : 0.0;

        return Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.52,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.canvasColor,
            borderRadius: BorderRadius.circular(MapsRadii.card),
            boxShadow: MapsShadows.mapControl(context.isDarkMode),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HudCell(
                    value: displaySpeed.toStringAsFixed(1),
                    unit: 'km/h',
                    color: isMoving ? context.accentBlue : context.inkColor,
                  ),
                  _divider(context),
                  _HudCell(
                    value: provider.currentLocation!.latitude
                        .toStringAsFixed(5),
                    unit: 'lat',
                    color: context.inkColor,
                  ),
                  _divider(context),
                  _HudCell(
                    value: provider.currentLocation!.longitude
                        .toStringAsFixed(5),
                    unit: 'lng',
                    color: context.inkColor,
                  ),
                ],
              ),
              Divider(
                height: 10,
                thickness: 0.5,
                color: context.dividerColor,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HudCell(
                    value: provider.altitude.toStringAsFixed(0),
                    unit: 'alt m',
                    color: context.secondaryColor,
                  ),
                  _divider(context),
                  _HudCell(
                    value: provider.currentBearing.toStringAsFixed(0),
                    unit: 'bear°',
                    color: context.secondaryColor,
                  ),
                  _divider(context),
                  _HudCell(
                    value: provider.accuracy.toStringAsFixed(0),
                    unit: 'acc m',
                    color: context.secondaryColor,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _divider(BuildContext context) => Container(
        width: 1,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: context.dividerColor,
      );
}

class _HudCell extends StatelessWidget {
  final String value;
  final String unit;
  final Color color;

  const _HudCell({
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: MapsTypography.hudValue.copyWith(color: color),
        ),
        Text(
          unit.toUpperCase(),
          style: MapsTypography.hudLabel.copyWith(color: context.mutedColor),
        ),
      ],
    );
  }
}
