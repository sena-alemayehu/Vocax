import '../models/device_contact.dart';
import 'app_launcher.dart';
import 'contact_service.dart';
import 'device_service.dart';

/// Turns what you say into an action on the phone and a spoken reply.
///
/// Commands are matched on the (lower-cased, punctuation-free) text. The main
/// verbs also work in French, Spanish, Amharic and Afaan Oromoo.
class CommandHandler {
  CommandHandler._(this._device, this._launcher, this._contacts, this._clock);

  factory CommandHandler({
    DeviceService? device,
    AppLauncher? launcher,
    ContactService? contacts,
    DateTime Function()? clock,
  }) {
    final service = device ?? PlatformDeviceService();
    return CommandHandler._(
      service,
      launcher ?? AppLauncher(service),
      contacts ?? ContactService(service),
      clock ?? DateTime.now,
    );
  }

  final DeviceService _device;
  final AppLauncher _launcher;
  final ContactService _contacts;
  final DateTime Function() _clock;

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<_SettingsTarget> _settingsTargets = [
    _SettingsTarget(['wifi', 'wi fi', 'wireless'], 'wifi', 'Wi-Fi'),
    _SettingsTarget(['bluetooth', 'blue tooth'], 'bluetooth', 'Bluetooth'),
    _SettingsTarget(
      ['airplane', 'flight mode', 'aeroplane'],
      'airplane',
      'airplane mode',
    ),
    _SettingsTarget(['location', 'gps'], 'location', 'location'),
    _SettingsTarget(
      ['brightness', 'display', 'screen timeout'],
      'display',
      'display',
    ),
    _SettingsTarget(['sound settings'], 'sound', 'sound'),
    _SettingsTarget(
      ['battery saver', 'power saving'],
      'battery_saver',
      'battery saver',
    ),
    _SettingsTarget(['mobile data', 'cellular data'], 'data', 'mobile data'),
    _SettingsTarget(['nfc'], 'nfc', 'NFC'),
    _SettingsTarget(['accessibility'], 'accessibility', 'accessibility'),
  ];

  late final List<Future<String?> Function(String core)> _rules = [
    _smallTalk,
    _alarmOrTimer,
    _timeAndDate,
    _battery,
    _flashlight,
    _volume,
    _media,
    _camera,
    _sms,
    _call,
    _navigate,
    _settings,
    _youtube,
    _openApp,
    _webSearch,
  ];

  /// Lower-cases, strips punctuation and collapses whitespace. Letters of any
  /// script (for example Amharic) are kept.
  static String normalize(String words) {
    return words
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static final List<RegExp> _fillerPrefixes = [
    RegExp(r'^(?:ok |okay )?(?:hello|hey|hi) vocax\b ?'),
    RegExp(r'^(?:ok |okay )?vocax\b ?'),
    RegExp(
      r'^(?:please|can you|could you|would you|will you|i want you to|i want to|i would like to|i d like to|i need you to) ?',
    ),
  ];

  static String _stripFillers(String text) {
    var result = text;
    var changed = true;
    while (changed) {
      changed = false;
      for (final pattern in _fillerPrefixes) {
        final next = result.replaceFirst(pattern, '');
        if (next != result) {
          result = next;
          changed = true;
        }
      }
    }
    return result
        .replaceFirst(RegExp(r'(?: please| for me)$'), '')
        .trim();
  }

  Future<String> handle(String words) async {
    final text = normalize(words);
    final core = _stripFillers(text);

    if (core.isEmpty) {
      return text.contains('vocax')
          ? 'Hello! I am Vocax. How can I help you?'
          : 'I did not catch that. Please try again.';
    }

    try {
      for (final rule in _rules) {
        final reply = await rule(core);
        if (reply != null) return reply;
      }
    } catch (_) {
      return 'Sorry, something went wrong with that command.';
    }

    return 'I heard you say: $words';
  }

  // ---------------------------------------------------------------------------
  // Small talk
  // ---------------------------------------------------------------------------

  Future<String?> _smallTalk(String core) async {
    if (core.contains('how are you')) {
      return 'I am ready to help you. What would you like to do?';
    }
    if (core.contains('your name') || core == 'who are you') {
      return 'My name is Vocax, your personal voice assistant.';
    }
    if (RegExp(r'^(?:thank you|thanks)').hasMatch(core)) {
      return 'You are welcome.';
    }
    if (core == 'help' || core.contains('what can you do')) {
      return 'I can open apps, call and message your contacts, search Google '
          'or YouTube, set alarms and timers, control the flashlight, volume '
          'and music, and open settings.';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Alarms, timers, time
  // ---------------------------------------------------------------------------

  Future<String?> _alarmOrTimer(String core) async {
    if (RegExp(r'\btimer\b').hasMatch(core)) {
      var seconds = 0;
      final parts = RegExp(
        r'(\d+) ?(hours?|hrs?|minutes?|mins?|seconds?|secs?)',
      );
      for (final match in parts.allMatches(core)) {
        final amount = int.parse(match.group(1)!);
        final unit = match.group(2)!;
        if (unit.startsWith('h')) {
          seconds += amount * 3600;
        } else if (unit.startsWith('m')) {
          seconds += amount * 60;
        } else {
          seconds += amount;
        }
      }
      if (seconds <= 0) {
        return 'For how long? Say, set a timer for 5 minutes.';
      }
      final ok = await _device.setTimer(seconds);
      return ok
          ? 'Timer set for ${_describeDuration(seconds)}.'
          : 'I could not set the timer.';
    }

    if (RegExp(r'\balarm\b|\bwake me up\b').hasMatch(core)) {
      final time = _parseTime(core);
      if (time == null) {
        return 'For what time? Say, set an alarm for 7 30 AM.';
      }
      final ok = await _device.setAlarm(time.hour, time.minute);
      return ok
          ? 'Alarm set for ${_formatTime(time.hour, time.minute)}.'
          : 'I could not set the alarm.';
    }
    return null;
  }

  _Time? _parseTime(String core) {
    var hour = -1;
    var minute = 0;

    final hourMinute = RegExp(r'\b(\d{1,2}) (\d{2})\b').firstMatch(core);
    final compact = RegExp(r'\b(\d{3,4})\b').firstMatch(core);
    final hourOnly = RegExp(r'\b(\d{1,2})\b').firstMatch(core);

    if (hourMinute != null) {
      hour = int.parse(hourMinute.group(1)!);
      minute = int.parse(hourMinute.group(2)!);
    } else if (compact != null) {
      final value = int.parse(compact.group(1)!);
      hour = value ~/ 100;
      minute = value % 100;
    } else if (hourOnly != null) {
      hour = int.parse(hourOnly.group(1)!);
    }

    if (hour < 0) return null;

    final pm = RegExp(r'\bp m\b|\bpm\b|\bevening\b|\bafternoon\b|\bnight\b')
        .hasMatch(core);
    final am = RegExp(r'\ba m\b|\bam\b|\bmorning\b').hasMatch(core);
    if (pm && hour < 12) hour += 12;
    if (am && hour == 12) hour = 0;

    if (hour > 23 || minute > 59) return null;
    return _Time(hour, minute);
  }

  String _formatTime(int hour, int minute) {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final twelve = hour % 12 == 0 ? 12 : hour % 12;
    return '$twelve:${minute.toString().padLeft(2, '0')} $suffix';
  }

  String _describeDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final parts = <String>[
      if (hours > 0) '$hours ${hours == 1 ? 'hour' : 'hours'}',
      if (minutes > 0) '$minutes ${minutes == 1 ? 'minute' : 'minutes'}',
      if (seconds > 0) '$seconds ${seconds == 1 ? 'second' : 'seconds'}',
    ];
    return parts.join(' ');
  }

  Future<String?> _timeAndDate(String core) async {
    if (RegExp(r'\bwhat time\b|^time$|\bthe time\b|\btime is it\b')
        .hasMatch(core)) {
      final now = _clock();
      return 'It is ${_formatTime(now.hour, now.minute)}.';
    }

    if (RegExp(r'\bwhat day\b|\bthe date\b|\btoday s date\b|\bwhat is today\b')
        .hasMatch(core)) {
      final now = _clock();
      final weekday = _weekdays[now.weekday - 1];
      final month = _months[now.month - 1];
      return 'Today is $weekday, $month ${now.day}.';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Phone controls
  // ---------------------------------------------------------------------------

  Future<String?> _battery(String core) async {
    if (!core.contains('battery') || core.contains('saver')) return null;

    final level = await _device.batteryLevel();
    return level >= 0
        ? 'Your battery is at $level percent.'
        : 'I could not read the battery level.';
  }

  Future<String?> _flashlight(String core) async {
    if (!(core.contains('flashlight') ||
        core.contains('flash light') ||
        core.contains('torch'))) {
      return null;
    }

    final off = RegExp(r'\boff\b|\bdisable\b').hasMatch(core);
    final ok = await _device.flashlight(!off);
    if (!ok) return 'I could not control the flashlight.';
    return off ? 'Flashlight off.' : 'Flashlight on.';
  }

  bool _hasWord(String text, List<String> words) {
    return words.any((word) => RegExp('\\b$word\\b').hasMatch(text));
  }

  Future<String?> _volume(String core) async {
    final mentionsVolume = core.contains('volume') ||
        _hasWord(core, ['louder', 'quieter', 'mute', 'unmute']);
    if (!mentionsVolume) return null;

    String action;
    int? percent;
    final number = RegExp(r'\b(\d{1,3})\b').firstMatch(core);

    if (_hasWord(core, ['unmute'])) {
      action = 'unmute';
    } else if (_hasWord(core, ['mute'])) {
      action = 'mute';
    } else if (number != null) {
      action = 'set';
      percent = int.parse(number.group(1)!).clamp(0, 100).toInt();
    } else if (_hasWord(core, ['max', 'maximum', 'full'])) {
      action = 'max';
    } else if (_hasWord(core, ['up', 'louder', 'increase', 'raise', 'higher'])) {
      action = 'up';
    } else if (_hasWord(
      core,
      ['down', 'lower', 'quieter', 'decrease', 'reduce'],
    )) {
      action = 'down';
    } else {
      return 'Say volume up, volume down, mute, or a number from 0 to 100.';
    }

    final level = await _device.volume(action, percent: percent);
    if (level < 0) return 'I could not change the volume.';
    if (action == 'mute') return 'Muted.';
    return 'Volume is now $level percent.';
  }

  Future<String?> _media(String core) async {
    final String action;
    final String reply;

    if (RegExp(r'^(?:pause|pause (?:the )?(?:music|song|video|playback))$')
        .hasMatch(core)) {
      action = 'pause';
      reply = 'Paused.';
    } else if (RegExp(r'^stop (?:the )?(?:music|song|playing|playback)$')
        .hasMatch(core)) {
      action = 'stop';
      reply = 'Stopped.';
    } else if (RegExp(
      r'^(?:play|resume|continue)(?: (?:the |some )?(?:music|song|songs|playback))?$',
    ).hasMatch(core)) {
      action = 'play';
      reply = 'Playing.';
    } else if (RegExp(r'^(?:next|skip|play next)(?: (?:the )?(?:song|track|music))?$')
        .hasMatch(core)) {
      action = 'next';
      reply = 'Next track.';
    } else if (RegExp(
      r'^(?:previous|play previous|last song|previous (?:song|track))$',
    ).hasMatch(core)) {
      action = 'previous';
      reply = 'Previous track.';
    } else {
      return null;
    }

    final ok = await _device.media(action);
    return ok ? reply : 'I could not control the music.';
  }

  Future<String?> _camera(String core) async {
    if (RegExp(r'^(?:take|snap|capture)(?: me)?(?: a| an)? (?:photo|picture|pic|selfie)$')
        .hasMatch(core)) {
      final ok = await _device.openCamera();
      return ok ? 'Opening the camera.' : 'I could not open the camera.';
    }
    if (RegExp(r'^(?:record|take)(?: a)? video$').hasMatch(core)) {
      final ok = await _device.openCamera(video: true);
      return ok ? 'Opening the video camera.' : 'I could not open the camera.';
    }
    return null;
  }

  Future<String?> _settings(String core) async {
    final hasAction = RegExp(
      r'\b(?:turn|switch|enable|disable|toggle|open|show|set|change|adjust|connect)\b',
    ).hasMatch(core);

    for (final target in _settingsTargets) {
      final mentioned = target.keywords.any(core.contains);
      if (!mentioned) continue;
      if (!hasAction && !target.keywords.contains(core)) continue;

      final ok = await _device.openSettings(target.target);
      if (!ok) return 'I could not open ${target.label} settings.';
      return 'Opening ${target.label} settings. Android does not let apps '
          'flip this switch directly, so tap it there.';
    }

    if (RegExp(r'^(?:open |show )?(?:the |my |phone |system )*settings$')
        .hasMatch(core)) {
      final ok = await _device.openSettings('settings');
      return ok ? 'Opening settings.' : 'I could not open settings.';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Calls and messages
  // ---------------------------------------------------------------------------

  Future<String?> _call(String core) async {
    final match = RegExp(
          r'^(?:call|phone|dial|ring|appelle|appeler|llama|llamar) (.+)$',
        ).firstMatch(core) ??
        RegExp(r'^(.+) (?:ደውል|ደውልልኝ|bilbili|bilbilaa)$').firstMatch(core);
    if (match == null) return null;

    final target = match.group(1)!.replaceFirst(RegExp(r'^(?:to |the )'), '');
    final digits = target.replaceAll(' ', '');

    final String number;
    final String label;

    if (RegExp(r'^\d{3,}$').hasMatch(digits)) {
      number = digits;
      label = digits;
    } else {
      if (!await _contacts.ensurePermission()) {
        return 'I need permission to read your contacts. Please allow it and try again.';
      }
      final contact = _contacts.match(target, await _contacts.all());
      if (contact == null) return 'I could not find $target in your contacts.';
      number = contact.number;
      label = contact.name;
    }

    final allowed = await _device.requestPermissions(['phone']);
    if (allowed && await _device.call(number)) return 'Calling $label.';
    if (await _device.dial(number)) return 'Opening the dialer for $label.';
    return 'I could not start the call.';
  }

  Future<String?> _sms(String core) async {
    final match = RegExp(
      r'^(?:send (?:a |an )?(?:text |sms |message )?(?:message )?to|text|sms|message) (.+)$',
    ).firstMatch(core);
    if (match == null) return null;

    var rest = match.group(1)!.trim();
    var body = '';
    var explicitBody = false;

    final split = RegExp(r'^(.+?) (?:saying|that says|say|that) (.+)$')
        .firstMatch(rest);
    if (split != null) {
      rest = split.group(1)!;
      body = split.group(2)!;
      explicitBody = true;
    }

    final String number;
    final String label;

    if (RegExp(r'^\d{3,}$').hasMatch(rest.replaceAll(' ', ''))) {
      number = rest.replaceAll(' ', '');
      label = number;
    } else {
      if (!await _contacts.ensurePermission()) {
        return 'I need permission to read your contacts. Please allow it and try again.';
      }
      final contacts = await _contacts.all();
      DeviceContact? contact;

      if (explicitBody) {
        contact = _contacts.match(rest, contacts);
      } else {
        // "text john hello there": find where the name ends and the message
        // starts by trying the first word, the first two words, and so on.
        final words = rest.split(' ');
        var bestScore = 0;
        for (var count = 1; count <= words.length; count++) {
          final name = words.take(count).join(' ');
          final scored = _contacts.matchScored(name, contacts);
          if (scored != null &&
              scored.score >= 700 &&
              scored.score >= bestScore) {
            bestScore = scored.score;
            contact = scored.item;
            body = words.skip(count).join(' ');
          }
        }
      }

      if (contact == null) return 'I could not find $rest in your contacts.';
      number = contact.number;
      label = contact.name;
    }

    final ok = await _device.sms(number, body);
    if (!ok) return 'I could not open the messages app.';
    return body.isEmpty
        ? 'Opening a message to $label. Tap send when you are ready.'
        : 'Opening a message to $label saying $body. Tap send to deliver it.';
  }

  // ---------------------------------------------------------------------------
  // Maps, search, apps
  // ---------------------------------------------------------------------------

  Future<String?> _navigate(String core) async {
    final match = RegExp(
      r'^(?:navigate to|navigate|directions to|directions|take me to|drive to|route to) (.+)$',
    ).firstMatch(core);
    if (match == null) return null;

    final place = match.group(1)!;
    final query = Uri.encodeQueryComponent(place);

    final ok = await _device.openUrl('google.navigation:q=$query') ||
        await _device.openUrl('geo:0,0?q=$query');
    return ok ? 'Navigating to $place.' : 'I could not open maps.';
  }

  Future<String?> _youtube(String core) async {
    final match = RegExp(
          r'^search (?:on )?(?:youtube|you tube) (?:for )?(.+)$',
        ).firstMatch(core) ??
        RegExp(
          r'^(?:play|watch|search|find|look up) (.+?) on (?:youtube|you tube)$',
        ).firstMatch(core) ??
        RegExp(r'^(?:play|watch) (.+)$').firstMatch(core);
    if (match == null) return null;

    final query = match.group(1)!;
    final url =
        'https://www.youtube.com/results?search_query=${Uri.encodeQueryComponent(query)}';
    final ok = await _device.openUrl(url);
    return ok ? 'Searching YouTube for $query.' : 'I could not open YouTube.';
  }

  Future<String?> _openApp(String core) async {
    final match = RegExp(
          r'^(?:open|launch|start|run|ouvre|ouvrir|abre|abrir|ክፈት|bani) (?:the )?(.+?)(?: app| application)?$',
        ).firstMatch(core) ??
        RegExp(r'^(.+?) (?:ክፈት|bani|baneeti)$').firstMatch(core);
    if (match == null) return null;

    final target = match.group(1)!.replaceFirst(RegExp(r'^the '), '');

    final app = await _launcher.find(target);
    if (app != null) {
      final ok = await _device.launchApp(app.package);
      return ok ? 'Opening ${app.name}.' : 'I could not open ${app.name}.';
    }

    if (await _launcher.openWebFallback(target)) {
      return 'Opening $target in your browser.';
    }
    return 'I could not find an app called $target on your phone.';
  }

  Future<String?> _webSearch(String core) async {
    final match = RegExp(
          r'^(?:search|google|look up|search for|search the web for|search google for|find|cherche|rechercher|busca|buscar) (?:for )?(.+)$',
        ).firstMatch(core) ??
        RegExp(r'^(.+?) (?:ፈልግ|barbaadi)$').firstMatch(core);
    if (match == null) return null;

    final query = match.group(1)!;
    final url = 'https://www.google.com/search?q=${Uri.encodeQueryComponent(query)}';
    final ok = await _device.openUrl(url);
    return ok ? 'Searching Google for $query.' : 'I could not open the browser.';
  }
}

class _Time {
  const _Time(this.hour, this.minute);

  final int hour;
  final int minute;
}

class _SettingsTarget {
  const _SettingsTarget(this.keywords, this.target, this.label);

  final List<String> keywords;
  final String target;
  final String label;
}
