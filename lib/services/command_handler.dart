import 'app_launcher.dart';
import 'contact_service.dart';

/// Turns recognized speech into an action and a spoken reply.
class CommandHandler {
  CommandHandler({AppLauncher? launcher, ContactService? contacts})
      : _launcher = launcher ?? AppLauncher(),
        _contacts = contacts ?? ContactService();

  final AppLauncher _launcher;
  final ContactService _contacts;

  static final RegExp _openPattern = RegExp(r'^(?:open|launch|start) (.+)$');
  static final RegExp _callPattern = RegExp(r'^(?:call|phone) (.+)$');

  /// Lower-cases, strips punctuation and collapses whitespace.
  static String normalize(String words) {
    return words
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<String> handle(String words) async {
    final text = normalize(words);

    if (text.contains('hello vocax') ||
        text.contains('hey vocax') ||
        text == 'hi vocax') {
      return 'Hello! I am Vocax. How can I help you?';
    }

    if (text.contains('how are you')) {
      return 'I am ready to help you. What would you like to do?';
    }

    if (text.contains('your name')) {
      return 'My name is Vocax, your personal voice assistant.';
    }

    final open = _openPattern.firstMatch(text);
    if (open != null) {
      final target = open.group(1)!.replaceFirst(RegExp(r'^the '), '');
      if (!_launcher.canHandle(target)) {
        return "I don't know how to open $target yet.";
      }
      final opened = await _launcher.open(target);
      return opened ? 'Opening $target.' : 'Sorry, I could not open $target.';
    }

    final call = _callPattern.firstMatch(text);
    if (call != null) {
      final name = call.group(1)!;
      final number = await _contacts.findNumber(name);
      if (number == null) {
        return 'I cannot look up contacts yet, so I cannot call $name.';
      }
      final dialed = await _launcher.dial(number);
      return dialed ? 'Calling $name.' : 'Sorry, I could not call $name.';
    }

    return 'I heard you say: $words';
  }
}
