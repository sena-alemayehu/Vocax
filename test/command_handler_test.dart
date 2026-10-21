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

  test('echoes things it does not understand', () async {
    final handler = CommandHandler(device: newDevice());
    expect(
      await handler.handle('tell me a joke'),
      'I heard you say: tell me a joke',
    );
  });
}
