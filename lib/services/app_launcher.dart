import '../models/installed_app.dart';
import 'device_service.dart';
import 'fuzzy_match.dart';

/// Finds and opens apps by the name you say.
class AppLauncher {
  AppLauncher(this._device);

  final DeviceService _device;

  List<InstalledApp>? _cache;
  DateTime? _cachedAt;

  /// Names said in Amharic, mapped to the usual app name.
  static const Map<String, String> _aliases = {
    'ዩቲዩብ': 'youtube',
    'ዋትስአፕ': 'whatsapp',
    'ቴሌግራም': 'telegram',
    'ፌስቡክ': 'facebook',
    'ኢንስታግራም': 'instagram',
    'ቲክቶክ': 'tiktok',
    'ካሜራ': 'camera',
    'ጎግል': 'google',
    'ጂሜይል': 'gmail',
  };

  /// Used when the app is not installed.
  static const Map<String, String> _webFallbacks = {
    'youtube': 'https://www.youtube.com',
    'google': 'https://www.google.com',
    'maps': 'https://maps.google.com',
    'gmail': 'https://mail.google.com',
    'whatsapp': 'https://web.whatsapp.com',
    'telegram': 'https://web.telegram.org',
    'facebook': 'https://www.facebook.com',
    'instagram': 'https://www.instagram.com',
    'twitter': 'https://x.com',
    'tiktok': 'https://www.tiktok.com',
  };

  /// All launchable apps (remembered for a few minutes).
  Future<List<InstalledApp>> apps({bool refresh = false}) async {
    final cachedAt = _cachedAt;
    final fresh = cachedAt != null &&
        DateTime.now().difference(cachedAt) < const Duration(minutes: 5);

    if (!refresh && fresh && _cache != null && _cache!.isNotEmpty) {
      return _cache!;
    }

    _cache = await _device.listApps();
    _cachedAt = DateTime.now();
    return _cache!;
  }

  /// The installed app that best matches what was said.
  Future<InstalledApp?> find(String spoken) async {
    final key = matchKey(spoken);
    final query = _aliases[key] ?? spoken;
    return bestMatch<InstalledApp>(query, await apps(), (app) => app.name);
  }

  /// Opens the web version of a well-known service.
  Future<bool> openWebFallback(String spoken) async {
    final url = _webFallbacks[matchKey(_aliases[matchKey(spoken)] ?? spoken)];
    if (url == null) return false;
    return _device.openUrl(url);
  }
}
