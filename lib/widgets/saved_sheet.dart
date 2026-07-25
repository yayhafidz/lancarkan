import 'package:flutter/material.dart';
import '../providers/navigation_provider.dart';
import '../theme/maps_theme.dart';

/// Bottom sheet for saved routes and locations (Google Maps Saved style).
class SavedSheet extends StatelessWidget {
  final NavigationProvider provider;
  final ValueChanged<SavedLocation> onSelectLocation;
  final ValueChanged<SavedRoute> onSelectRoute;

  const SavedSheet({
    super.key,
    required this.provider,
    required this.onSelectLocation,
    required this.onSelectRoute,
  });

  @override
  Widget build(BuildContext context) {
    final routes = provider.savedRoutes;
    final locations = provider.savedLocations;
    final isEmpty = routes.isEmpty && locations.isEmpty;

    return Container(
      decoration: BoxDecoration(
        color: context.canvasColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MapsRadii.sheet),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: context.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Center(
              child: Text(
                'Tersimpan',
                style: MapsTypography.screenTitle.copyWith(
                  fontSize: 18,
                  color: context.inkColor,
                ),
              ),
            ),
          ),
          Expanded(
            child: isEmpty
                ? const _EmptyState()
                : ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      if (locations.isNotEmpty) ...[
                        _SectionHeader(label: 'Lokasi'),
                        ...locations.map(
                          (loc) => _SavedLocationTile(
                            saved: loc,
                            onTap: () => onSelectLocation(loc),
                            onDelete: () =>
                                provider.deleteSavedLocation(loc.name),
                          ),
                        ),
                      ],
                      if (locations.isNotEmpty && routes.isNotEmpty)
                        Divider(
                          height: 16,
                          indent: 20,
                          endIndent: 20,
                          color: context.dividerColor,
                        ),
                      if (routes.isNotEmpty) ...[
                        _SectionHeader(label: 'Rute'),
                        ...routes.map(
                          (route) => _SavedRouteTile(
                            route: route,
                            onTap: () => onSelectRoute(route),
                            onDelete: () =>
                                provider.deleteSavedRoute(route.name),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 48,
              color: context.mutedColor.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada yang tersimpan',
              style: MapsTypography.body.copyWith(color: context.mutedColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Tekan Atur → Simpan untuk lokasi atau rute',
              textAlign: TextAlign.center,
              style: MapsTypography.meta.copyWith(
                color: context.mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: MapsTypography.sectionHdr.copyWith(
          color: context.mutedColor,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SavedLocationTile extends StatelessWidget {
  final SavedLocation saved;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedLocationTile({
    required this.saved,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      minVerticalPadding: 8,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.savedGreen.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.bookmark_rounded,
            color: context.savedGreen, size: 18),
      ),
      title: Text(
        saved.name,
        style: MapsTypography.rowTitle.copyWith(color: context.inkColor),
      ),
      subtitle: Text(
        '${saved.location.latitude.toStringAsFixed(5)}, '
        '${saved.location.longitude.toStringAsFixed(5)}',
        style: MapsTypography.meta.copyWith(color: context.secondaryColor),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline,
            color: MapsColors.error, size: 20),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}

class _SavedRouteTile extends StatelessWidget {
  final SavedRoute route;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedRouteTile({
    required this.route,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      minVerticalPadding: 8,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.accentBlue.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child:
            Icon(Icons.route_rounded, color: context.accentBlue, size: 18),
      ),
      title: Text(
        route.name,
        style: MapsTypography.rowTitle.copyWith(color: context.inkColor),
      ),
      subtitle: Text(
        '${route.points.length} titik',
        style: MapsTypography.meta.copyWith(color: context.secondaryColor),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline,
            color: MapsColors.error, size: 20),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}
