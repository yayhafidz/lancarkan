import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/navigation_provider.dart';
import '../services/native_location_service.dart';
import '../widgets/control_panel.dart';
import '../widgets/hud_panel.dart';
import '../widgets/saved_sheet.dart';
import '../theme/maps_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  bool _isSearching = false;
  bool _hasCenteredOnUser = false;
  
  // Search Autocomplete state
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _showSuggestions = false;

  // Search result pin
  LatLng? _searchPin;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      try {
        // Nominatim Search API: https://nominatim.org/release-docs/develop/api/Search/
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(query)}'
          '&format=jsonv2'
          '&addressdetails=1'
          '&limit=6'
          '&accept-language=id'
          '&countrycodes=id',
        );
        final response = await http.get(url, headers: {
          'User-Agent': 'LancarkanApp/1.0 (com.android.lancarkan)',
        });

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _searchResults = data.map((item) {
              final addr = item['address'] as Map<String, dynamic>? ?? {};
              return <String, dynamic>{
                'display_name': item['display_name'] ?? '',
                'name': item['name'] ?? addr['amenity'] ?? addr['road'] ?? item['display_name'] ?? 'Lokasi',
                'road': addr['road'],
                'suburb': addr['suburb'],
                'city': addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'],
                'state': addr['state'],
                '_lat': double.tryParse(item['lat'].toString()) ?? 0.0,
                '_lng': double.tryParse(item['lon'].toString()) ?? 0.0,
                'type': item['type'] ?? '',
                'class': item['class'] ?? '',
              };
            }).toList();
            _showSuggestions = true;
          });
        }
      } catch (e) {
        debugPrint('Nominatim search error: $e');
      } finally {
        setState(() => _isSearching = false);
      }
    });
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    _searchFocus.unfocus();
    final lat = result['_lat'] as double;
    final lng = result['_lng'] as double;
    setState(() {
      _showSuggestions = false;
      _searchResults = [];
      _searchController.text = result['name'] ?? '';
      _searchPin = LatLng(lat, lng);
    });
    _mapController.move(LatLng(lat, lng), 16.0);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: context.canvasColor)),
        backgroundColor: context.inkColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSaved(NavigationProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(MapsRadii.sheet)),
        child: SavedSheet(
          provider: provider,
          onSelectLocation: (saved) {
            provider.loadLocation(saved);
            _mapController.move(saved.location, 15.0);
            Navigator.pop(ctx);
          },
          onSelectRoute: (route) {
            provider.loadRoute(route);
            if (route.startLocation != null) {
              _mapController.move(route.startLocation!, 15.0);
            } else if (route.points.isNotEmpty) {
              _mapController.move(route.points.first, 15.0);
            }
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, provider, child) {
        final loc = provider.currentLocation;
        final center = loc ?? const LatLng(-6.2088, 106.8456);

        // Auto-center once when location becomes available
        if (loc != null && !_hasCenteredOnUser) {
          _hasCenteredOnUser = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try { _mapController.move(loc, 15.0); } catch (_) {}
          });
        }

        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            await NativeLocationService.moveToBackground();
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false, // Keyboard won't push UI up
            backgroundColor: context.creamColor,
            body: Stack(
            children: [
              // ─── Map ───────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 15.0,
                  onPositionChanged: (pos, hasGesture) {
                    if (hasGesture && _showSuggestions) {
                      _searchFocus.unfocus();
                      _showSuggestions = false;
                    }
                  },
                  onTap: (tapPosition, point) {
                    _searchFocus.unfocus();
                    setState(() => _showSuggestions = false);
                    provider.addRoutePoint(point);
                  },
                  onLongPress: (tapPosition, point) {
                    _searchFocus.unfocus();
                    setState(() => _showSuggestions = false);
                    if (!provider.isNavigating) {
                      provider.setCurrentLocation(point);
                      provider.setMode(NavMode.static);
                      _showSnackBar('Titik lokasi diatur');
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: context.isDarkMode
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: context.isDarkMode ? const ['a', 'b', 'c', 'd'] : const [],
                    userAgentPackageName: 'com.android.lancarkan',
                  ),
                  if (provider.routePoints.isNotEmpty &&
                      provider.currentLocation != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [
                            provider.currentLocation!,
                            ...provider.routePoints
                          ],
                          color: context.accentBlue.withOpacity(0.85),
                          strokeWidth: 5.0,
                          strokeCap: StrokeCap.round,
                          strokeJoin: StrokeJoin.round,
                        ),
                        if (provider.loopRoute &&
                            provider.routePoints.length > 1)
                          Polyline(
                            points: [
                              provider.routePoints.last,
                              provider.routePoints.first,
                            ],
                            color: context.accentBlue.withOpacity(0.3),
                            strokeWidth: 3.0,
                          ),
                      ],
                    ),
                  if (provider.currentLocation != null)
                    MarkerLayer(
                      markers: [
                        ...provider.routePoints
                            .asMap()
                            .entries
                            .map((entry) => Marker(
                                  point: entry.value,
                                  width: 36,
                                  height: 36,
                                  child: _RoutePin(
                                      label: '${entry.key + 1}'),
                                )),
                        Marker(
                          point: provider.currentLocation!,
                          width: 80,
                          height: 80,
                          child: const _PulsingPuck(),
                        ),
                      ],
                    ),
                  if (_searchPin != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _searchPin!,
                          width: 48,
                          height: 48,
                          alignment: Alignment.topCenter,
                          child: const _SearchPinMarker(),
                        ),
                      ],
                    ),
                ],
              ),

              // ─── Left: Zoom Controls ────────────────────────────
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                left: 16,
                bottom: _controlPanelHeight(provider) + 16,
                child: Column(
                  children: [
                    _MapControlButton(
                      icon: Icons.add,
                      onTap: () => _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1),
                    ),
                    const SizedBox(height: 8),
                    _MapControlButton(
                      icon: Icons.remove,
                      onTap: () => _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1),
                    ),
                    const SizedBox(height: 8),
                    _MapControlButton(
                      icon: context.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: context.isDarkMode
                          ? MapsColors.googleYellow
                          : context.secondaryColor,
                      onTap: () => provider.toggleDarkMode(),
                    ),
                  ],
                ),
              ),

              // ─── Right: Map Controls ────────────────────────────
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                right: 16,
                bottom: _controlPanelHeight(provider) + 16,
                child: Column(
                  children: [
                    _MapControlButton(
                      icon: Icons.refresh_rounded, // Refresh location icon
                      onTap: () async {
                        await provider.fetchRealLocation();
                        if (provider.currentLocation != null) {
                          _mapController.move(provider.currentLocation!, 15.0);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<MapEvent>(
                      stream: _mapController.mapEventStream,
                      builder: (context, snapshot) {
                        final rotation = _mapController.camera.rotation;
                        return _MapControlButton(
                          onTap: () {
                            _mapController.rotate(0);
                          },
                          child: Transform.rotate(
                            angle: rotation * 3.141592653589793 / 180,
                            child: Icon(
                              Icons.navigation_rounded,
                              color: context.secondaryColor,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                      _MapControlButton(
                        icon: Icons.my_location_rounded,
                        color: context.accentBlue,
                      onTap: () {
                        if (provider.currentLocation != null) {
                          _mapController.move(
                              provider.currentLocation!, 15.0);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // ─── Top right HUD (below safe area so it doesn't overlap search) ──
              Positioned(
                top: 70,
                right: 16,
                child: SafeArea(child: const HudPanel()),
              ),

              // ─── Bottom: Control Panel ───────────────────────────
              const Align(
                alignment: Alignment.bottomCenter,
                child: ControlPanel(),
              ),

              // ─── Top: Search Bar ──
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SearchBar(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          isSearching: _isSearching,
                          onChanged: _onSearchChanged,
                          onClear: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _showSuggestions = false;
                              _searchPin = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      _MapControlButton(
                        icon: Icons.bookmark_rounded,
                        color: context.savedGreen,
                        onTap: () => _showSaved(provider),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Search Suggestions (full width overlay) ──
              if (_showSuggestions && _searchResults.isNotEmpty)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 64,
                  left: 16,
                  right: 16,
                  child: _SearchSuggestions(
                    results: _searchResults,
                    onSelect: _selectSearchResult,
                  ),
                ),
            ],
          ),
          ),
        );
      },
    );
  }

  double _controlPanelHeight(NavigationProvider p) {
    return p.isSettingsExpanded ? 370 : 200;
  }
}

// ─── Search Suggestions ─────────────────────────────────────────────────────
class _SearchSuggestions extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final ValueChanged<Map<String, dynamic>> onSelect;

  const _SearchSuggestions({
    required this.results,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(context.isDarkMode ? 0.35 : 0.15),
      borderRadius: BorderRadius.circular(MapsRadii.card),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: context.canvasColor.withOpacity(0.97),
          borderRadius: BorderRadius.circular(MapsRadii.card),
        ),
        constraints: const BoxConstraints(
          maxHeight: 280.0, // Limits height but allows dynamic item sizing
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const ClampingScrollPhysics(),
          itemCount: results.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: context.dividerColor.withOpacity(0.3),
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final res = results[index];
            final title = res['name'] ?? 'Lokasi';

            final parts = <String>[];
            if (res['road'] != null) parts.add(res['road']);
            if (res['suburb'] != null) parts.add(res['suburb']);
            if (res['city'] != null) parts.add(res['city']);
            if (res['state'] != null) parts.add(res['state']);
            final subtitle = parts.join(', ');

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: Icon(Icons.location_on_rounded,
                  color: context.secondaryColor, size: 20),
              title: Text(title,
                  style: MapsTypography.listTitle
                      .copyWith(fontSize: 15, color: context.inkColor)),
              subtitle: subtitle.isNotEmpty
                  ? Text(subtitle,
                      style: MapsTypography.caption.copyWith(
                          color: context.secondaryColor.withOpacity(0.8)))
                  : null,
              onTap: () => onSelect(res),
            );
          },
        ),
      ),
    );
  }
}

// ─── Search Bar ─────────────────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearching;
  final ValueChanged<String>? onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isSearching,
    this.onChanged,
    required this.onClear,
  });

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 48,
      decoration: BoxDecoration(
        color: context.canvasColor,
        borderRadius: BorderRadius.circular(MapsRadii.searchPill),
        border: Border.all(
          color: _focused
              ? context.accentBlue
              : context.dividerColor,
          width: _focused ? 2.0 : 1.0,
        ),
        boxShadow: MapsShadows.searchBar(context.isDarkMode),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        style: MapsTypography.searchHint.copyWith(
          color: context.inkColor,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Cari lokasi…',
          hintStyle: MapsTypography.searchHint.copyWith(
            color: context.secondaryColor,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: widget.isSearching
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.accentBlue,
                    ),
                  ),
                )
              : Icon(Icons.search_rounded,
                  color: _focused ? context.accentBlue : context.secondaryColor,
                  size: 22),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: context.secondaryColor, size: 20),
                  onPressed: widget.onClear,
                )
              : null,
        ),
      ),
    );
  }
}

// ─── Map Control Button ───────────────────────────────────────────────────────
class _MapControlButton extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final Color? color;
  final VoidCallback onTap;

  const _MapControlButton({
    this.icon,
    this.child,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.canvasColor,
          borderRadius: BorderRadius.circular(MapsRadii.card),
          boxShadow: MapsShadows.mapControl(context.isDarkMode),
        ),
        child: child ?? Icon(icon, color: color ?? context.secondaryColor, size: 20),
      ),
    );
  }
}

// ─── Route Pin ───────────────────────────────────────────────────────────────
class _RoutePin extends StatelessWidget {
  final String label;
  const _RoutePin({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: context.pinRed,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: context.pinRed.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Pulsing Location Puck ────────────────────────────────────────────────────
class _PulsingPuck extends StatefulWidget {
  const _PulsingPuck({Key? key}) : super(key: key);

  @override
  State<_PulsingPuck> createState() => _PulsingPuckState();
}

class _PulsingPuckState extends State<_PulsingPuck>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _scale = Tween<double>(begin: 1.0, end: 2.6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.accentBlue.withOpacity(_opacity.value),
              ),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: context.accentBlue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: context.accentBlue.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Pin Marker ────────────────────────────────────────────────────────
class _SearchPinMarker extends StatelessWidget {
  const _SearchPinMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // White outline for visibility on map
        Icon(
          Icons.location_on,
          color: Colors.white,
          size: 48,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // Main colored icon
        Icon(
          Icons.location_on,
          color: context.pinRed,
          size: 40,
        ),
      ],
    );
  }
}
