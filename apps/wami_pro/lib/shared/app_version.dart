import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wami_core/wami_core.dart';

/// Résultat de `GET /api/app-config/check-version` (app « DRIVER »).
class VersionCheck {
  const VersionCheck({required this.updateAvailable, required this.forceUpdate, this.latest = '', this.url = '', this.notes = ''});
  final bool updateAvailable;
  final bool forceUpdate;
  final String latest;
  final String url;
  final String notes;
}

/// Interroge le serveur sur la version installée. En cas d'échec, l'app continue (jamais bloquant).
class AppVersionService {
  AppVersionService(this._api);
  final ApiClient _api;

  Future<VersionCheck?> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID';
      final j = await _api.get('/api/app-config/check-version', query: {
        'appType': 'DRIVER',
        'platform': platform,
        'currentVersion': info.version,
      });
      return VersionCheck(
        updateAvailable: j['updateAvailable'] == true,
        forceUpdate: j['forceUpdate'] == true,
        latest: (j['latestVersion'] as String?) ?? '',
        url: (j['downloadUrl'] as String?) ?? '',
        notes: (j['releaseNotes'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}
