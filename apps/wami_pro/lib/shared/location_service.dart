import 'dart:math' as math;

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

  /// Position complète pour le suivi de course (cap, vitesse, précision).
  Future<Position?> currentFix() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 5)),
      );
      _last = (lat: p.latitude, lng: p.longitude);
      return p;
    } catch (_) {
      return null;
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
