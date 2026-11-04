import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

typedef LatLng = ({double lat, double lng});

/// Position du téléphone. Les permissions de localisation sont déclarées
/// uniquement dans l'app Pro (voir README). Le suivi écran éteint demandera
/// un service de premier plan : à ajouter avant la publication.
class LocationService {
  LatLng? _last;

  /// Dernière position connue (sans nouvelle demande).
  LatLng? get last => _last;

  /// Position actuelle, ou `null` si le service ou la permission manque.
  Future<LatLng?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return _last;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return _last;
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)),
      );
      return _last = (lat: p.latitude, lng: p.longitude);
    } catch (_) {
      return _last;
    }
  }

  /// Flux de positions qui continue écran éteint : service de premier plan avec notification
  /// permanente sur Android, indicateur de localisation en arrière-plan sur iOS.
  Stream<Position> track() {
    return Geolocator.getPositionStream(locationSettings: _trackingSettings()).map((p) {
      _last = (lat: p.latitude, lng: p.longitude);
      return p;
    });
  }

  LocationSettings _trackingSettings() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
          intervalDuration: const Duration(seconds: 3),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'WAMI Pro',
            notificationText: 'Position utilisée pour vos missions',
            enableWakeLock: true,
            setOngoing: true,
          ),
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.automotiveNavigation,
          distanceFilter: 5,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
          allowBackgroundLocationUpdates: true,
        );
      default:
        return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);
    }
  }

  /// `true` si la localisation « toujours » est déjà accordée.
  Future<bool> hasBackgroundPermission() async => (await Geolocator.checkPermission()) == LocationPermission.always;

  /// Demande la localisation en arrière-plan, en deux temps comme l'exigent Android et iOS
  /// (d'abord « pendant l'utilisation », puis « toujours »). Ne bloque jamais : sans « toujours »,
  /// le suivi continue tant que l'app reste ouverte ou que son service de premier plan tourne.
  Future<bool> requestBackgroundPermission() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.whileInUse) perm = await Geolocator.requestPermission();
      return perm == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }
}

/// Distance à vol d'oiseau, en mètres.
double haversineMeters(LatLng a, LatLng b) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.lat - a.lat);
  final dLng = rad(b.lng - a.lng);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.lat)) * math.cos(rad(b.lat)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}
