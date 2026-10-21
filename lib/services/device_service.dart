import 'package:flutter/services.dart';

import '../models/device_contact.dart';
import '../models/installed_app.dart';

/// Things Vocax can do on the phone.
///
/// This base class does nothing (every action reports failure). The real
/// version, [PlatformDeviceService], talks to Android; tests extend this class
/// and override only what they need.
class DeviceService {
  Future<List<InstalledApp>> listApps() async => const [];

  Future<bool> launchApp(String package) async => false;

  Future<bool> openUrl(String url) async => false;

  /// Opens the dialer with [number] filled in.
  Future<bool> dial(String number) async => false;

  /// Starts a call right away (needs the phone permission).
  Future<bool> call(String number) async => false;

  /// Opens the messages app with a ready-to-send text.
  Future<bool> sms(String number, String body) async => false;

  Future<List<DeviceContact>> listContacts() async => const [];

  /// Asks for `contacts` and/or `phone`. True when all are granted.
  Future<bool> requestPermissions(List<String> names) async => false;

  Future<bool> flashlight(bool on) async => false;

  /// [action]: up, down, mute, unmute, max or set. Returns the volume in
  /// percent, or -1 on failure.
  Future<int> volume(String action, {int? percent}) async => -1;

  /// [action]: play, pause, toggle, next, previous or stop.
  Future<bool> media(String action) async => false;

  /// Opens a system settings page (wifi, bluetooth, airplane, location,
  /// display, sound, battery_saver, data, nfc, accessibility, apps, settings).
  Future<bool> openSettings(String target) async => false;

  Future<bool> setAlarm(int hour, int minute, {String? label}) async => false;

  Future<bool> setTimer(int seconds) async => false;

  Future<bool> openCamera({bool video = false}) async => false;

  /// Battery level in percent, or -1.
  Future<int> batteryLevel() async => -1;
}

/// Android implementation, backed by `MainActivity.kt`.
class PlatformDeviceService extends DeviceService {
  static const MethodChannel _channel = MethodChannel('vocax/device');

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<bool> _flag(String method, [Map<String, Object?>? arguments]) async {
    return (await _invoke<bool>(method, arguments)) ?? false;
  }

  @override
  Future<List<InstalledApp>> listApps() async {
    final raw = await _invoke<List<dynamic>>('listApps');
    if (raw == null) return const [];

    return [
      for (final entry in raw)
        InstalledApp(
          name: (entry as Map)['name'] as String,
          package: entry['package'] as String,
        ),
    ];
  }

  @override
  Future<bool> launchApp(String package) =>
      _flag('launchApp', {'package': package});

  @override
  Future<bool> openUrl(String url) => _flag('openUrl', {'url': url});

  @override
  Future<bool> dial(String number) => _flag('dial', {'number': number});

  @override
  Future<bool> call(String number) => _flag('call', {'number': number});

  @override
  Future<bool> sms(String number, String body) =>
      _flag('sms', {'number': number, 'body': body});

  @override
  Future<List<DeviceContact>> listContacts() async {
    final raw = await _invoke<List<dynamic>>('listContacts');
    if (raw == null) return const [];

    return [
      for (final entry in raw)
        DeviceContact(
          name: (entry as Map)['name'] as String,
          number: entry['number'] as String,
        ),
    ];
  }

  @override
  Future<bool> requestPermissions(List<String> names) =>
      _flag('requestPermissions', {'names': names});

  @override
  Future<bool> flashlight(bool on) => _flag('flashlight', {'on': on});

  @override
  Future<int> volume(String action, {int? percent}) async {
    final value = await _invoke<int>('volume', {
      'action': action,
      'percent': percent,
    });
    return value ?? -1;
  }

  @override
  Future<bool> media(String action) => _flag('media', {'action': action});

  @override
  Future<bool> openSettings(String target) =>
      _flag('openSettings', {'target': target});

  @override
  Future<bool> setAlarm(int hour, int minute, {String? label}) =>
      _flag('alarm', {'hour': hour, 'minute': minute, 'label': label});

  @override
  Future<bool> setTimer(int seconds) => _flag('timer', {'seconds': seconds});

  @override
  Future<bool> openCamera({bool video = false}) =>
      _flag('camera', {'video': video});

  @override
  Future<int> batteryLevel() async {
    final value = await _invoke<int>('battery');
    return value ?? -1;
  }
}
