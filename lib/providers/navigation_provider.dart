import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../services/native_location_service.dart';

enum NavMode { static, dynamic }

enum VehicleType { pedestrian, motorcycle, car }

extension VehicleTypeExt on VehicleType {
  String get label {
    switch (this) {
      case VehicleType.pedestrian: return 'Jalan Kaki';
      case VehicleType.motorcycle: return 'Motor';
      case VehicleType.car: return 'Mobil';
    }
  }

  double get maxSpeed {
    switch (this) {
      case VehicleType.pedestrian: return 5.0;
      case VehicleType.motorcycle: return 80.0;
      case VehicleType.car: return 120.0;
    }
  }

  double get defaultSpeed {
    switch (this) {
      case VehicleType.pedestrian: return 4.0;
      case VehicleType.motorcycle: return 40.0;
      case VehicleType.car: return 60.0;
    }
  }
}

class SavedRoute {
  final String name;
  final List<LatLng> points;
  final LatLng? startLocation;
  SavedRoute({required this.name, required this.points, this.startLocation});
}

class SavedLocation {
  final String name;
  final LatLng location;
  SavedLocation({required this.name, required this.location});
}

class NavigationProvider with ChangeNotifier {
  // Core state
  bool _isNavigating = false;
  NavMode _mode = NavMode.static;

  // Location states
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  bool _loopRoute = false;
  bool _useRandomSpeed = false;
  VehicleType _vehicleType = VehicleType.motorcycle;
  int _currentRouteIndex = 0;

  // Simulation parameters
  double _speed = 1.0;
  double _altitude = 10.0;
  double _accuracy = 5.0;
  double _currentBearing = 0.0;
  double _effectiveSpeed = 1.0; // actual speed after jitter, shown on HUD

  // Timer for dynamic simulation
  Timer? _simulationTimer;

  // Bookmarks & Saved Routes
  List<SavedLocation> _savedLocations = [];
  List<SavedRoute> _savedRoutes = [];
  bool _isDarkMode = false;
  bool _isSettingsExpanded = false;

  // Tracks loaded saved route for "save only if changed"
  String? _loadedRouteName;
  List<LatLng> _loadedRoutePoints = [];
  LatLng? _loadedRouteStart;

  // Tracks loaded saved location
  String? _loadedLocationName;
  LatLng? _loadedLocationSnapshot;

  // Getters
  bool get isNavigating => _isNavigating;
  NavMode get mode => _mode;
  LatLng? get currentLocation => _currentLocation;
  List<LatLng> get routePoints => _routePoints;
  bool get loopRoute => _loopRoute;
  bool get useRandomSpeed => _useRandomSpeed;
  VehicleType get vehicleType => _vehicleType;
  bool get isDarkMode => _isDarkMode;
  bool get isSettingsExpanded => _isSettingsExpanded;
  int get currentRouteIndex => _currentRouteIndex;
  double get speed => _speed;
  double get effectiveSpeed => _effectiveSpeed; // real-time speed for HUD
  double get altitude => _altitude;
  double get accuracy => _accuracy;
  double get currentBearing => _currentBearing;
  List<SavedLocation> get savedLocations => _savedLocations;
  List<SavedRoute> get savedRoutes => _savedRoutes;
  String? get loadedRouteName => _loadedRouteName;
  String? get loadedLocationName => _loadedLocationName;

  /// True when route has points and differs from the last loaded snapshot.
  bool get canSaveRoute {
    if (_routePoints.isEmpty) return false;
    if (_loadedRouteName == null) return true;
    return !_routeMatchesLoaded();
  }

  /// True when a start/current location can be saved (no active route).
  bool get canSaveLocation {
    if (_currentLocation == null) return false;
    if (_routePoints.isNotEmpty) return false;
    if (_loadedLocationName == null) return true;
    return !_sameLatLng(_currentLocation, _loadedLocationSnapshot);
  }

  bool get canSave => canSaveRoute || canSaveLocation;

  bool get isSavingRoute => _routePoints.isNotEmpty;

  NavigationProvider() {
    _loadPreferences();
  }

  // ─── Init ─────────────────────────────────────────────────────────────────

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('loop_route')) {
      _loopRoute = prefs.getBool('loop_route') ?? false;
    }
    if (prefs.containsKey('dark_mode')) {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
    }

    // If there was an active session (app killed while navigating), restore mock state
    final wasNavigating = prefs.getBool('was_navigating') ?? false;
    if (wasNavigating) {
      final lat = prefs.getDouble('last_lat');
      final lng = prefs.getDouble('last_lng');
      if (lat != null && lng != null && lat.isFinite && lng.isFinite) {
        _currentLocation = LatLng(lat, lng);
        _isNavigating = true;
        // Restore route from saved state if any
        final savedRouteStr = prefs.getStringList('session_route');
        if (savedRouteStr != null) {
          _routePoints = savedRouteStr.map((s) {
            final p = s.split(',');
            return LatLng(double.parse(p[0]), double.parse(p[1]));
          }).toList();
          if (_routePoints.isNotEmpty) {
            _mode = NavMode.dynamic;
          }
        }
        notifyListeners();
        // Restart the native service
        await NativeLocationService.startNavigation(
          lat: lat,
          lng: lng,
          alt: _altitude,
          accuracy: _accuracy,
          speed: 0.0,
          bearing: _currentBearing,
        );
        if (_mode == NavMode.dynamic) _startSimulation();
      } else {
        await fetchRealLocation();
      }
    } else {
      await fetchRealLocation();
    }

    // Load saved locations (migrate legacy bookmarks)
    final savedLocNames = prefs.getStringList('saved_location_names');
    if (savedLocNames != null) {
      for (final name in savedLocNames) {
        final raw = prefs.getString('location_$name');
        if (raw != null) {
          final p = raw.split(',');
          _savedLocations.add(SavedLocation(
            name: name,
            location: LatLng(double.parse(p[0]), double.parse(p[1])),
          ));
        }
      }
    } else {
      final bookmarksStr = prefs.getStringList('bookmarks');
      if (bookmarksStr != null) {
        for (var i = 0; i < bookmarksStr.length; i++) {
          final parts = bookmarksStr[i].split(',');
          _savedLocations.add(SavedLocation(
            name: 'Lokasi ${i + 1}',
            location: LatLng(double.parse(parts[0]), double.parse(parts[1])),
          ));
        }
        await _persistSavedLocations();
        await prefs.remove('bookmarks');
      }
    }

    // Load saved routes
    final savedRoutesStr = prefs.getStringList('saved_routes_names');
    if (savedRoutesStr != null) {
      for (final name in savedRoutesStr) {
        final pointsRaw = prefs.getStringList('route_$name');
        final startRaw = prefs.getString('route_start_$name');
        if (pointsRaw != null) {
          final points = pointsRaw.map((s) {
            final p = s.split(',');
            return LatLng(double.parse(p[0]), double.parse(p[1]));
          }).toList();
          LatLng? start;
          if (startRaw != null) {
            final sp = startRaw.split(',');
            start = LatLng(double.parse(sp[0]), double.parse(sp[1]));
          }
          _savedRoutes.add(SavedRoute(name: name, points: points, startLocation: start));
        }
      }
    }

    notifyListeners();
  }

  Future<void> fetchRealLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (position.latitude.isFinite && position.longitude.isFinite) {
        _currentLocation = LatLng(position.latitude, position.longitude);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to get real location: $e');
    }
  }

  // ─── Persistence ──────────────────────────────────────────────────────────

  Future<void> _saveSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('was_navigating', _isNavigating);
    if (_currentLocation != null) {
      await prefs.setDouble('last_lat', _currentLocation!.latitude);
      await prefs.setDouble('last_lng', _currentLocation!.longitude);
    }
    // Save current route for session restore
    await prefs.setStringList('session_route',
        _routePoints.map((p) => '${p.latitude},${p.longitude}').toList());
  }

  void toggleRandomSpeed(bool value) {
    _useRandomSpeed = value;
    if (!_useRandomSpeed || !_isNavigating || _mode == NavMode.static) {
      _effectiveSpeed = _speed;
    }
    notifyListeners();
  }

  void toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    notifyListeners();
  }

  Future<void> _clearSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('was_navigating', false);
    await prefs.remove('session_route');
  }

  Future<void> _persistSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final names = _savedLocations.map((l) => l.name).toList();
    await prefs.setStringList('saved_location_names', names);
    for (final loc in _savedLocations) {
      await prefs.setString(
        'location_${loc.name}',
        '${loc.location.latitude},${loc.location.longitude}',
      );
    }
  }

  Future<void> _persistSavedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final names = _savedRoutes.map((r) => r.name).toList();
    await prefs.setStringList('saved_routes_names', names);
    for (final route in _savedRoutes) {
      await prefs.setStringList('route_${route.name}',
          route.points.map((p) => '${p.latitude},${p.longitude}').toList());
      if (route.startLocation != null) {
        await prefs.setString('route_start_${route.name}',
            '${route.startLocation!.latitude},${route.startLocation!.longitude}');
      }
    }
  }

  // ─── Location ─────────────────────────────────────────────────────────────

  void setCurrentLocation(LatLng loc) {
    _currentLocation = loc;
    if (_loadedLocationSnapshot != null &&
        !_sameLatLng(loc, _loadedLocationSnapshot)) {
      _loadedLocationName = null;
      _loadedLocationSnapshot = null;
    }
    if (_isNavigating && _mode == NavMode.static) {
      NativeLocationService.updateNavigation(
        lat: loc.latitude, lng: loc.longitude,
        alt: _altitude, accuracy: _accuracy, speed: 0.0, bearing: 0.0,
      );
    }
    notifyListeners();
  }

  // ─── Route ────────────────────────────────────────────────────────────────

  void toggleSettingsExpanded() {
    _isSettingsExpanded = !_isSettingsExpanded;
    notifyListeners();
  }

  // ─── Location Engine ────────────────────────────────────────────────────────────────

  void addRoutePoint(LatLng loc) {
    _routePoints.add(loc);
    if (_mode != NavMode.dynamic) {
      setMode(NavMode.dynamic);
    } else {
      notifyListeners();
    }
  }

  void undoLastRoutePoint() {
    if (_routePoints.isEmpty) return;
    _routePoints.removeLast();
    if (_routePoints.isEmpty && _mode == NavMode.dynamic) {
      setMode(NavMode.static);
    } else {
      notifyListeners();
    }
  }

  void setVehicleType(VehicleType type) {
    _vehicleType = type;
    _speed = 1.0;
    if (!_isNavigating || _mode == NavMode.static) {
      _effectiveSpeed = 1.0;
    }
    notifyListeners();
  }

  void clearRoute() {
    _routePoints.clear();
    _currentRouteIndex = 0;
    _loadedRouteName = null;
    _loadedRoutePoints = [];
    _loadedRouteStart = null;
    if (_mode == NavMode.dynamic) setMode(NavMode.static);
    notifyListeners();
  }

  void loadRoute(SavedRoute route) {
    _routePoints = List.from(route.points);
    if (route.startLocation != null) {
      _currentLocation = route.startLocation;
    }
    if (_routePoints.isNotEmpty) {
      _mode = NavMode.dynamic;
    }
    _loadedRouteName = route.name;
    _loadedRoutePoints = List.from(route.points);
    _loadedRouteStart = route.startLocation;
    _loadedLocationName = null;
    _loadedLocationSnapshot = null;
    notifyListeners();
  }

  void loadLocation(SavedLocation saved) {
    _currentLocation = saved.location;
    _loadedLocationName = saved.name;
    _loadedLocationSnapshot = saved.location;
    _loadedRouteName = null;
    _loadedRoutePoints = [];
    _loadedRouteStart = null;
    notifyListeners();
  }

  Future<void> saveCurrentRoute(String name) async {
    _savedRoutes.removeWhere((r) => r.name == name);
    _savedRoutes.add(SavedRoute(
      name: name,
      points: List.from(_routePoints),
      startLocation: _currentLocation,
    ));
    _loadedRouteName = name;
    _loadedRoutePoints = List.from(_routePoints);
    _loadedRouteStart = _currentLocation;
    await _persistSavedRoutes();
    notifyListeners();
  }

  Future<void> deleteSavedRoute(String name) async {
    _savedRoutes.removeWhere((r) => r.name == name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('route_$name');
    await prefs.remove('route_start_$name');
    await _persistSavedRoutes();
    notifyListeners();
  }

  Future<void> saveCurrentLocation(String name) async {
    if (_currentLocation == null) return;
    _savedLocations.removeWhere((l) => l.name == name);
    _savedLocations.add(SavedLocation(name: name, location: _currentLocation!));
    _loadedLocationName = name;
    _loadedLocationSnapshot = _currentLocation;
    await _persistSavedLocations();
    notifyListeners();
  }

  Future<void> deleteSavedLocation(String name) async {
    _savedLocations.removeWhere((l) => l.name == name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('location_$name');
    if (_loadedLocationName == name) {
      _loadedLocationName = null;
      _loadedLocationSnapshot = null;
    }
    await _persistSavedLocations();
    notifyListeners();
  }

  // ─── Settings ─────────────────────────────────────────────────────────────

  void toggleLoop(bool val) { _loopRoute = val; notifyListeners(); }
  void setSpeed(double v) { 
    _speed = v.clamp(1.0, _vehicleType.maxSpeed); 
    if (!_isNavigating || _mode == NavMode.static) {
      _effectiveSpeed = _speed;
    }
    notifyListeners(); 
  }

  void setMode(NavMode mode) {
    _mode = mode;
    if (mode == NavMode.static) {
      _stopSimulation();
      if (_isNavigating && _currentLocation != null) {
        NativeLocationService.updateNavigation(
          lat: _currentLocation!.latitude, lng: _currentLocation!.longitude,
          alt: _altitude, accuracy: _accuracy, speed: 0.0, bearing: 0.0,
        );
      }
    } else if (mode == NavMode.dynamic && _isNavigating) {
      _startSimulation();
    }
    notifyListeners();
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  /// Called when mock navigation is stopped from the Android notification.
  Future<void> stopFromNotification() async {
    if (!_isNavigating) return;
    _stopSimulation();
    _isNavigating = false;
    _effectiveSpeed = 0.0;
    notifyListeners();
    await _clearSessionState();
    await Future.delayed(const Duration(milliseconds: 600));
    await fetchRealLocation();
    notifyListeners();
  }

  Future<void> toggleNavigation() async {
    if (_currentLocation == null) return;

    if (_isNavigating) {
      // Stop: clear mock, fetch real location
      await NativeLocationService.stopNavigation();
      _stopSimulation();
      _isNavigating = false;
      _effectiveSpeed = 0.0;
      notifyListeners();
      await _clearSessionState();
      
      // Wait for Android's LocationManager to drop the mock provider
      await Future.delayed(const Duration(milliseconds: 600));
      await fetchRealLocation(); // snap to real GPS immediately
    } else {
      final success = await NativeLocationService.startNavigation(
        lat: _currentLocation!.latitude,
        lng: _currentLocation!.longitude,
        alt: _altitude,
        accuracy: _accuracy,
        speed: _mode == NavMode.dynamic ? (_speed * 1000 / 3600) : 0.0,
        bearing: _currentBearing,
      );
      if (success) {
        _isNavigating = true;
        await _saveSessionState();
        if (_mode == NavMode.dynamic) _startSimulation();
      }
    }
    notifyListeners();
  }

  // ─── Simulation ───────────────────────────────────────────────────────────

  void _startSimulation() {
    _stopSimulation();
    if (_currentLocation == null || _routePoints.isEmpty) return;

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (_currentLocation == null || _routePoints.isEmpty ||
          _currentRouteIndex >= _routePoints.length) {
        _finishSimulation();
        return;
      }

      final target = _routePoints[_currentRouteIndex];
      final distance = const Distance();
      final distToTarget = distance.as(LengthUnit.Meter, _currentLocation!, target);

      // Random jitter
      if (_useRandomSpeed) {
        final jitter = 0.85 + (math.Random().nextDouble() * 0.30);
        _effectiveSpeed = math.max(1.0, _speed * jitter);
      } else {
        _effectiveSpeed = _speed;
      }

      final speedMs = _effectiveSpeed * 1000 / 3600;

      if (distToTarget <= speedMs) {
        _currentLocation = target;
        _currentRouteIndex++;
        if (_currentRouteIndex >= _routePoints.length) {
          if (_loopRoute) {
            _currentRouteIndex = 0;
          } else {
            _finishSimulation();
            return;
          }
        }
      } else {
        _currentBearing = distance.bearing(_currentLocation!, target);
        _currentLocation = distance.offset(_currentLocation!, speedMs, _currentBearing);
      }

      _saveSessionState();
      NativeLocationService.updateNavigation(
        lat: _currentLocation!.latitude,
        lng: _currentLocation!.longitude,
        alt: _altitude,
        accuracy: _accuracy,
        speed: speedMs,
        bearing: _currentBearing,
      );
      notifyListeners();
    });
  }

  void _finishSimulation() {
    _stopSimulation();
    _currentRouteIndex = 0;
    _mode = NavMode.static;
    _effectiveSpeed = 0.0;
    if (_isNavigating && _currentLocation != null) {
      NativeLocationService.updateNavigation(
        lat: _currentLocation!.latitude, lng: _currentLocation!.longitude,
        alt: _altitude, accuracy: _accuracy, speed: 0.0, bearing: 0.0,
      );
    }
    notifyListeners();
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  bool _routeMatchesLoaded() {
    if (!_samePoints(_routePoints, _loadedRoutePoints)) return false;
    return _sameLatLng(_currentLocation, _loadedRouteStart);
  }

  bool _samePoints(List<LatLng> a, List<LatLng> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameLatLng(a[i], b[i])) return false;
    }
    return true;
  }

  bool _sameLatLng(LatLng? a, LatLng? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.latitude.toStringAsFixed(5) == b.latitude.toStringAsFixed(5) &&
        a.longitude.toStringAsFixed(5) == b.longitude.toStringAsFixed(5);
  }

  @override
  void dispose() {
    _stopSimulation();
    // Save session state when provider is disposed (app goes to background)
    if (_isNavigating) {
      _saveSessionState();
    }
    super.dispose();
  }
}
