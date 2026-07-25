import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/maps_theme.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({Key? key}) : super(key: key);

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.only(
            top: 10,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: context.canvasColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(MapsRadii.sheet),
            ),
            boxShadow: MapsShadows.bottomSheet(context.isDarkMode),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.12),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  );
                },
                child: provider.isSettingsExpanded
                    ? _SettingsContent(
                        key: const ValueKey('settings'),
                        provider: provider,
                        onSave: () => _saveDialog(context, provider),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
              Row(
                children: [
                  _AturChip(provider: provider),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: provider.currentLocation == null
                          ? null
                          : provider.toggleNavigation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: provider.isNavigating
                            ? MapsColors.error
                            : MapsColors.googleBlue,
                        disabledBackgroundColor: context.surfaceColor,
                        disabledForegroundColor: context.mutedColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(MapsRadii.buttonPill),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            provider.isNavigating
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            provider.isNavigating
                                ? 'Hentikan'
                                : 'Mulai Perjalanan',
                            style: MapsTypography.buttonPrimary
                                .copyWith(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (!provider.isNavigating && provider.currentLocation == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Tekan lama di peta untuk menentukan titik awal',
                    textAlign: TextAlign.center,
                    style: MapsTypography.meta.copyWith(
                      color: context.mutedColor,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveDialog(
      BuildContext context, NavigationProvider provider) async {
    if (!provider.canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.isSavingRoute
                ? 'Tidak ada perubahan pada rute yang dimuat'
                : 'Tidak ada perubahan pada lokasi yang dimuat',
          ),
        ),
      );
      return;
    }

    final isRoute = provider.isSavingRoute;
    final defaultName = isRoute
        ? (provider.loadedRouteName ??
            'Rute ${provider.savedRoutes.length + 1}')
        : (provider.loadedLocationName ??
            'Lokasi ${provider.savedLocations.length + 1}');
    final ctrl = TextEditingController(text: defaultName);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRoute ? 'Simpan Rute' : 'Simpan Lokasi'),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: context.inkColor),
          decoration: InputDecoration(
            labelText: isRoute ? 'Nama rute' : 'Nama lokasi',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              if (isRoute) {
                await provider.saveCurrentRoute(name);
              } else {
                await provider.saveCurrentLocation(name);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isRoute
                          ? 'Rute "$name" disimpan'
                          : 'Lokasi "$name" disimpan',
                    ),
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _AturChip extends StatelessWidget {
  final NavigationProvider provider;
  const _AturChip({required this.provider});

  @override
  Widget build(BuildContext context) {
    final active = provider.isSettingsExpanded;
    return GestureDetector(
      onTap: () => provider.toggleSettingsExpanded(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? context.chipActiveBg : context.canvasColor,
          borderRadius: BorderRadius.circular(MapsRadii.chip),
          border: Border.all(
            color: active ? context.chipActiveBorder : context.dividerColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.tune_rounded,
              size: 18,
              color: active ? context.chipActiveText : context.secondaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              'Atur',
              style: MapsTypography.chip.copyWith(
                fontSize: 12,
                color: active ? context.chipActiveText : context.secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  final NavigationProvider provider;
  final VoidCallback onSave;

  const _SettingsContent({
    super.key,
    required this.provider,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Vehicle Type (icon + underline tab style) ───────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: VehicleType.values.asMap().entries.map((entry) {
                final idx = entry.key;
                final type = entry.value;
                final selected = provider.vehicleType == type;
                final isLast = idx == VehicleType.values.length - 1;
                final icon = type == VehicleType.pedestrian
                    ? Icons.directions_walk_rounded
                    : type == VehicleType.motorcycle
                        ? Icons.two_wheeler_rounded
                        : Icons.directions_car_rounded;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => provider.setVehicleType(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.only(right: isLast ? 0 : 12),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected
                                ? context.accentBlue
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: selected
                            ? context.accentBlue
                            : context.secondaryColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          // ─── Speed label + badge ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text(
                  'KECEPATAN',
                  style: MapsTypography.sectionHdr.copyWith(
                    color: context.mutedColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${provider.useRandomSpeed ? provider.effectiveSpeed.toStringAsFixed(1) : provider.speed.toStringAsFixed(0)} km/h',
                    style: MapsTypography.meta.copyWith(
                      color: context.accentBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              activeTrackColor: context.accentBlue,
              inactiveTrackColor: context.accentBlue.withOpacity(0.12),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 12,
                elevation: 4,
              ),
              overlayColor: context.accentBlue.withOpacity(0.1),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Slider(
                value: provider.speed.clamp(1.0, provider.vehicleType.maxSpeed),
                min: 1.0,
                max: provider.vehicleType.maxSpeed,
                onChanged: provider.setSpeed,
              ),
            ),
          ),
          // ─── Divider: kecepatan ↔ fitur ──────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Divider(height: 1, color: context.dividerColor.withOpacity(0.5)),
          ),
          const SizedBox(height: 4),
          // ─── Toggles & Actions ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ToggleChip(
                  label: 'Ulangi',
                  icon: Icons.loop_rounded,
                  value: provider.loopRoute,
                  onChanged: provider.toggleLoop,
                ),
                _ToggleChip(
                  label: 'Kec. Acak',
                  icon: Icons.shuffle_rounded,
                  value: provider.useRandomSpeed,
                  onChanged: provider.toggleRandomSpeed,
                ),
                if (provider.routePoints.isNotEmpty)
                  _ActionChip(
                    label: 'Undo',
                    icon: Icons.undo_rounded,
                    color: context.accentBlue,
                    onTap: provider.undoLastRoutePoint,
                  ),
                if (provider.canSave || provider.currentLocation != null)
                  _ActionChip(
                    label: 'Simpan',
                    icon: Icons.bookmark_add_rounded,
                    color: context.savedGreen,
                    enabled: provider.canSave,
                    onTap: onSave,
                  ),
                if (provider.routePoints.isNotEmpty)
                  _ActionChip(
                    label: 'Hapus (${provider.routePoints.length})',
                    icon: Icons.clear_rounded,
                    color: MapsColors.error,
                    onTap: provider.clearRoute,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Divider(
              height: 1,
              color: context.dividerColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: value ? context.chipActiveBg : context.canvasColor,
          borderRadius: BorderRadius.circular(MapsRadii.chip),
          border: Border.all(
            color: value ? context.chipActiveBorder : context.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: value ? context.chipActiveText : context.secondaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: MapsTypography.chip.copyWith(
                fontSize: 13,
                color: value ? context.chipActiveText : context.inkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = enabled ? color : context.mutedColor;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: chipColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(MapsRadii.chip),
            border: Border.all(color: chipColor.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: chipColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: MapsTypography.chip.copyWith(
                  fontSize: 13,
                  color: chipColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
