import 'package:url_launcher/url_launcher.dart';

/// Opens other apps and the phone dialer.
///
/// Apps are opened through their web links, which Android hands to the
/// installed app when there is one (YouTube, Gmail, Maps, WhatsApp...).
class AppLauncher {
  static const Map<String, String> _targets = {
    'youtube': 'https://www.youtube.com',
    'google': 'https://www.google.com',
    'maps': 'https://maps.google.com',
    'gmail': 'https://mail.google.com',
    'whatsapp': 'https://wa.me/',
    'telegram': 'https://t.me/',
    'facebook': 'https://www.facebook.com',
  };

  bool canHandle(String name) => _targets.containsKey(name);

  Future<bool> open(String name) async {
    final url = _targets[name];
    if (url == null) return false;
    return _launch(Uri.parse(url));
  }

  /// Opens the dialer with [number] filled in (the user presses call).
  Future<bool> dial(String number) {
    return _launch(Uri(scheme: 'tel', path: number));
  }

  Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
