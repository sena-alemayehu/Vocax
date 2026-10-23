import 'package:flutter_test/flutter_test.dart';
import 'package:vocax/models/device_contact.dart';
import 'package:vocax/models/installed_app.dart';
import 'package:vocax/services/command_handler.dart';
import 'package:vocax/services/device_service.dart';

/// A phone that records what Vocax asked it to do.
class FakeDevice extends DeviceService {
  FakeDevice({this.apps = const [], this.contacts = const []});

  final List<InstalledApp> apps;
  final List<DeviceContact> contacts;

  final List<String> launched = [];
  final List<String> urls = [];
  final List<String> calls = [];
  final List<String> messages = [];
  final List<String> volumeActions = [];
  final List<String> mediaActions = [];
  final List<bool> torch = [];
  final List<String> alarms = [];
  final List<int> timers = [];

  bool online = true;
  bool accessibilityOn = false;
  final List<String> screenActions = [];
  final List<String> settingsOpened = [];
  final List<String> toggled = [];

  @override
  Future<List<InstalledApp>> listApps() async => apps;

  @override
  Future<bool> launchApp(String package) async {
    launched.add(package);
    return true;
  }

  @override
  Future<bool> openUrl(String url) async {
    urls.add(url);
    return true;
  }

  @override
  Future<bool> call(String number) async {
    calls.add(number);
    return true;
  }

  @override
  Future<bool> sms(String number, String body) async {
    messages.add('$number|$body');
    return true;
  }

  @override
  Future<List<DeviceContact>> listContacts() async => contacts;

  @override
  Future<bool> requestPermissions(List<String> names) async => true;

  @override
  Future<bool> flashlight(bool on) async {
    torch.add(on);
    return true;
  }

  @override
  Future<int> volume(String action, {int? percent}) async {
    volumeActions.add(action);
    return percent ?? 40;
  }

  @override
  Future<bool> media(String action) async {
    mediaActions.add(action);
    return true;
  }

  @override
  Future<bool> setAlarm(int hour, int minute, {String? label}) async {
    alarms.add('$hour:$minute');
    return true;
  }

  @override
  Future<bool> setTimer(int seconds) async {
    timers.add(seconds);
    return true;
  }

  @override
  Future<int> batteryLevel() async => 82;

  @override
  Future<bool> isOnline() async => online;

  @override
  Future<bool> openSettings(String target) async {
    settingsOpened.add(target);
    return true;
  }

  @override
  Future<bool> a11yEnabled() async => accessibilityOn;

  @override
  Future<bool> a11yAction(String name, {bool stepAside = false}) async {
    screenActions.add(name);
    return true;
  }

  @override
  Future<bool> a11yScroll(String direction) async {
    screenActions.add('scroll_$direction');
    return true;
  }

  @override
  Future<bool> a11yClick(String text) async {
    screenActions.add('click_$text');
    return true;
  }

  @override
  Future<String> toggleSystem(List<String> labels, bool on) async {
    toggled.add('${labels.first}:$on');
    return 'done';
  }
}

void main() {
  const youtube = InstalledApp(
    name: 'YouTube',
    package: 'com.google.android.youtube',
  );
  const whatsapp = InstalledApp(
    name: 'WhatsApp',
    package: 'com.whatsapp',
  );
  const mom = DeviceContact(name: 'Mom', number: '0912345678');

  FakeDevice newDevice() => FakeDevice(
        apps: const [youtube, whatsapp],
        contacts: const [mom],
      );

  test('normalize strips punctuation and case but keeps other scripts', () {
    expect(CommandHandler.normalize('  Hello,   VOCAX! '), 'hello vocax');
    expect(CommandHandler.normalize('ዩቲዩብ ክፈት!'), 'ዩቲዩብ ክፈት');
  });

  test('greets when you say hello', () async {
    final handler = CommandHandler(device: newDevice());
    expect(await handler.handle('Hello Vocax'), contains('I am Vocax'));
  });

  test('tells its name', () async {
    final handler = CommandHandler(device: newDevice());
    expect(await handler.handle("What's your name?"), contains('Vocax'));
  });

  test('opens an installed app', () async {
    final device = newDevice();
    final handler = CommandHandler(device: device);

    expect(await handler.handle('Open YouTube'), 'Opening YouTube.');
    expect(device.launched, ['com.google.android.youtube']);
  });

  test('opens an app even when speech splits its name', () async {
    final device = newDevice();
    final handler = CommandHandler(device: device);

    await handler.handle('hey vocax please open what s app');
    expect(device.launched, ['com.whatsapp']);
  });

  test('says when an app is missing', () async {
    final handler = CommandHandler(device: newDevice());
    expect(
      await handler.handle('open the moon'),
      contains('could not find an app called moon'),
    );
  });

  test('calls a number', () async {
    final device = newDevice();
    final handler = CommandHandler(device: device);

    await handler.handle('call 0911 22 33 44');
    expect(device.calls, ['0911223344']);
  });

  test('calls a contact by name', () async {
    final device = newDevice();
    final handler = CommandHandler(device: device);

    expect(await handler.handle('call mom'), 'Calling Mom.');
    expect(device.calls, ['0912345678']);
  });

  test('prepares a text message', () async {
    final device = newDevice();
    final handler = CommandHandler(device: device);

    final reply = await handler.handle('send a message to mom saying I am late');
    expect(reply, contains('Mom'));
    expect(device.messages, ['0912345678|i am late']);
  });

  test('splits name and message without the word saying', () async {
    final device = newDevice();
    final handler = CommandHandler(device: device);

    await handler.handle('text mom see you soon');
    expect(device.messages, ['0912345678|see you soon']);
  });

  test('sets an alarm', () async {
    final device = newDevice();
    final handler = CommandHandler(device: device);

    expect(
      await handler.handle('Set an alarm for 7:30 AM'),
      'Alarm set for 7:30 AM.',
    );
    await handler.handle('set alarm for 6 pm');
    expect(device.alarms, ['7:30', '18:0']);
  });

  test('sets a timer', () async {
    final device = newDevice();
    final handler = CommandHandler(device: device);

    await handler.handle('set a timer for 5 minutes');
    expect(device.timers, [300]);
  });

  test('controls the flashlight', () async {
    final device = newDevice();
    final handler = CommandHandler(device: device);

    await handler.handle('turn on the flashlight');
    await handler.handle('turn off the flashlight');
    expect(device.torch, [true, false]);
  });

  test('changes the volume', () async {
    final device = newDevice();
    final handler = CommandHandler(device: device);

    await handler.handle('volume up');
    await handler.handle('mute');
    expect(device.volumeActions, ['up', 'mute']);
  });

  test('controls music', () async {
    final device = newDevice();
    final handler = CommandHandler(device: device);

    await handler.handle('pause');
    await handler.handle('next song');
    expect(device.mediaActions, ['pause', 'next']);
  });

  test('searches YouTube and Google', () async {
    final device = newDevice();
    final handler = CommandHandler(device: device);

    await handler.handle('play despacito on youtube');
    await handler.handle('search for flutter');
    expect(device.urls[0], contains('youtube.com/results?search_query=despacito'));
    expect(device.urls[1], contains('google.com/search?q=flutter'));
  });

  test('reports battery and time', () async {
    final handler = CommandHandler(
      device: newDevice(),
      clock: () => DateTime(2026, 10, 21, 14, 48),
    );

    expect(
      await handler.handle('what is my battery level'),
      'Your battery is at 82 percent.',
    );
    expect(await handler.handle('what time is it'), 'It is 2:48 PM.');
    expect(
      await handler.handle('what is the date'),
      'Today is Wednesday, October 21.',
    );
  });

  test('says who built it, in several languages', () async {
    final handler = CommandHandler(device: newDevice());
    const questions = [
      'Who built you?',
      'who developed you',
      'Who made you',
      'hey vocax who is your developer',
      'qui t a créé',
      'quién te creó',
      '谁开发了你',
    ];
    for (final question in questions) {
      expect(
        await handler.handle(question),
        CommandHandler.builderReply,
        reason: question,
      );
    }
    expect(CommandHandler.builderReply, contains('Sena Alemayehu'));
    expect(CommandHandler.builderReply, contains('professional software engineer'));
  });

  test('opening an app returns a card and waits for the screen to launch it', () async {
    final device = newDevice();
    final handler = CommandHandler(device: device);

    final result = await handler.handleFull('open youtube');
    expect(result.reply, 'Opening YouTube.');
    expect(result.app?.package, 'com.google.android.youtube');
    expect(device.launched, isEmpty);

    expect(await result.launch!(), isTrue);
    expect(device.launched, ['com.google.android.youtube']);
  });

  test('web searches are shown inside the app', () async {
    final device = newDevice();
    final handler = CommandHandler(device: device);

    final result = await handler.handleFull('search for flutter');
    expect(result.webUrl, contains('google.com/search?q=flutter'));
    expect(device.urls, isEmpty);
  });

  test('works offline without web actions', () async {
    final device = newDevice()..online = false;
    final handler = CommandHandler(device: device);

    expect(await handler.handle('search for flutter'), contains('offline'));
    expect(await handler.handle('open youtube'), 'Opening YouTube.');
    expect(await handler.handle('turn on the flashlight'), 'Flashlight on.');
    expect(device.launched, ['com.google.android.youtube']);
    expect(device.urls, isEmpty);
  });

  test('Wi-Fi switch uses accessibility, or opens settings without it', () async {
    final device = newDevice();
    final handler = CommandHandler(device: device);

    final without = await handler.handle('turn on wifi');
    expect(without, contains('tap the switch'));
    expect(device.settingsOpened, ['wifi']);

    device.accessibilityOn = true;
    expect(await handler.handle('turn off bluetooth'), 'Bluetooth turned off.');
    expect(device.toggled, ['bluetooth:false']);
  });

  test('screen control needs the accessibility service', () async {
    final device = newDevice();
    final handler = CommandHandler(device: device);

    expect(await handler.handle('take a screenshot'), contains('Accessibility'));
    expect(device.settingsOpened, ['accessibility']);

    device.accessibilityOn = true;
    await handler.handle('take a screenshot');
    await handler.handle('go home');
    await handler.handle('swipe up');
    await handler.handle('tap search');
    expect(
      device.screenActions,
      ['screenshot', 'home', 'scroll_down', 'click_search'],
    );
  });

  test('understands Chinese commands', () async {
    final device = newDevice();
    final handler = CommandHandler(device: device);

    await handler.handle('打开YouTube');
    expect(device.launched, ['com.google.android.youtube']);
  });

  test('echoes things it does not understand', () async {
    final handler = CommandHandler(device: newDevice());
    expect(
      await handler.handle('tell me a joke'),
      'I heard you say: tell me a joke',
    );
  });
}
