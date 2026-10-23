import 'dart:typed_data';

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

  /// The app icon as PNG bytes.
  Future<Uint8List?> appIcon(String package) async => null;

  Future<bool> openUrl(String url) async => false;

  /// Whether the phone has a working internet connection.
  Future<bool> isOnline() async => true;

  /// Opens the dialer with [number] filled in.
  Future<bool> dial(String number) async => false;

  /// Starts a call right away (needs the phone permission).
  Future<bool> call(String number) async => false;

  /// Opens the messages app with a ready-to-send text.
  Future<bool> sms(String number, String body) async => false;

  Future<List<DeviceContact>> listContacts() async => const [];

  /// Asks for `microphone`, `contacts` and/or `phone`. True when all granted.
  Future<bool> requestPermissions(List<String> names) async => false;

  /// Which of `microphone`, `contacts`, `phone` are allowed.
  Future<Map<String, bool>> permissionStatus() async => const {};

  Future<bool> flashlight(bool on) async => false;

  /// [action]: up, down, mute, unmute, max or set. Returns the volume in
  /// percent, or -1 on failure.
  Future<int> volume(String action, {int? percent}) async => -1;

  /// [action]: play, pause, toggle, next, previous or stop.
  Future<bool> media(String action) async => false;

  /// Opens a system settings page (wifi, bluetooth, airplane, location,
  /// display, sound, battery_saver, data, nfc, accessibility, apps, ...).
  Future<bool> openSettings(String target) async => false;

  /// Opens this app's page in system settings (permissions).
  Future<bool> openAppSettings() async => false;

  /// Opens the phone's voice input settings (offline speech packs).
  Future<bool> openVoiceSettings() async => false;

  /// Opens the screen for installing text-to-speech voices.
  Future<bool> installTtsData() async => false;

  Future<bool> setAlarm(int hour, int minute, {String? label}) async => false;

  Future<bool> setTimer(int seconds) async => false;

  Future<bool> openCamera({bool video = false}) async => false;

  /// Battery level in percent, or -1.
  Future<int> batteryLevel() async => -1;

  // ---- Accessibility service (must be turned on by the user) ----

  Future<bool> a11yEnabled() async => false;

  /// [name]: home, back, recents, notifications, quick_settings, power, lock,
  /// screenshot. With [stepAside] Vocax first moves out of the way.
  Future<bool> a11yAction(String name, {bool stepAside = false}) async => false;

  /// [direction]: up, down, left or right.
  Future<bool> a11yScroll(String direction) async => false;

  /// Taps the item on screen with this text.
  Future<bool> a11yClick(String text) async => false;

  /// Types [text] into the field that has the cursor in another app.
  Future<bool> a11yType(String text) async => false;

  /// Switches a quick-settings tile. Returns done, already, notfound, failed
  /// or noservice.
  Future<String> toggleSystem(List<String> labels, bool on) async =>
      'noservice';
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
  Future<Uint8List?> appIcon(String package) =>
      _invoke<Uint8List>('appIcon', {'package': package});

  @override
  Future<bool> openUrl(String url) => _flag('openUrl', {'url': url});

  @override
  Future<bool> isOnline() async => (await _invoke<bool>('online')) ?? true;

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
  Future<Map<String, bool>> permissionStatus() async {
    final raw = await _invoke<Map<dynamic, dynamic>>('permissionStatus');
    if (raw == null) return const {};

    return {
      for (final entry in raw.entries) entry.key as String: entry.value == true,
    };
  }

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
  Future<bool> openAppSettings() => _flag('openAppSettings');

  @override
  Future<bool> openVoiceSettings() => _flag('openVoiceSettings');

  @override
  Future<bool> installTtsData() => _flag('installTtsData');

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

  @override
  Future<bool> a11yEnabled() => _flag('a11yEnabled');

  @override
  Future<bool> a11yAction(String name, {bool stepAside = false}) =>
      _flag('a11yAction', {'name': name, 'stepAside': stepAside});

  @override
  Future<bool> a11yScroll(String direction) =>
      _flag('a11yScroll', {'direction': direction});

  @override
  Future<bool> a11yClick(String text) => _flag('a11yClick', {'text': text});

  @override
  Future<bool> a11yType(String text) => _flag('a11yType', {'text': text});

  @override
  Future<String> toggleSystem(List<String> labels, bool on) async {
    final outcome = await _invoke<String>('a11yToggle', {
      'labels': labels,
      'on': on,
    });
    return outcome ?? 'failed';
  }
}
