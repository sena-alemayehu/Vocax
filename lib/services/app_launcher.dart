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
    'ዋትሳፕ': 'whatsapp',
    // Chinese
    '油管': 'youtube',
    '微信': 'wechat',
    '谷歌': 'google',
    '相机': 'camera',
    '照相机': 'camera',
    '设置': 'settings',
    '地图': 'maps',
    '抖音': 'tiktok',
    '脸书': 'facebook',
    '电报': 'telegram',
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

  /// The web address of a well-known service, if there is one.
  String? webFallbackUrl(String spoken) {
    return _webFallbacks[matchKey(_aliases[matchKey(spoken)] ?? spoken)];
  }

  /// Opens the web version of a well-known service in the phone's browser.
  Future<bool> openWebFallback(String spoken) async {
    final url = webFallbackUrl(spoken);
    if (url == null) return false;
    return _device.openUrl(url);
  }
}
