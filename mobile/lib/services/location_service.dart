import 'package:geolocator/geolocator.dart';

class LocationResult {
  final bool success;
  final Position? position;
  final String? error;

  LocationResult.success(this.position)
      : success = true,
        error = null;

  LocationResult.failure(this.error)
      : success = false,
        position = null;
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastKnownPosition;
  DateTime? _lastFetchTime;

  Position? get lastKnownPosition => _lastKnownPosition;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permission
  Future<LocationPermission> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Get current location
  Future<LocationResult> getCurrentLocation({
    bool forceRefresh = false,
  }) async {
    try {
      // Return cached location if fresh (within 5 minutes)
      if (!forceRefresh &&
          _lastKnownPosition != null &&
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!).inMinutes < 5) {
        return LocationResult.success(_lastKnownPosition);
      }

      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.failure(
            'Location services are disabled. Please enable them in settings.');
      }

      // Check permission
      final permission = await checkPermission();

      if (permission == LocationPermission.denied) {
        return LocationResult.failure(
            'Location permission denied. Please grant permission to discover nearby cafes.');
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult.failure(
            'Location permission permanently denied. Please enable it in app settings.');
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _lastKnownPosition = position;
      _lastFetchTime = DateTime.now();

      return LocationResult.success(position);
    } catch (e) {
      return LocationResult.failure('Failed to get location: $e');
    }
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) /
        1000;
  }

  /// Format distance for display
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for permission)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
