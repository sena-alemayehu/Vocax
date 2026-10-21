import 'package:flutter_test/flutter_test.dart';
import 'package:vocax/services/command_handler.dart';

void main() {
  final handler = CommandHandler();

  test('normalize strips punctuation, case and extra spaces', () {
    expect(CommandHandler.normalize('  Hello,   VOCAX! '), 'hello vocax');
  });

  test('greets when you say hello', () async {
    expect(await handler.handle('Hello Vocax'), contains('I am Vocax'));
  });

  test('tells its name', () async {
    expect(await handler.handle("What's your name?"), contains('Vocax'));
  });

  test('echoes unknown phrases', () async {
    expect(
      await handler.handle('play some music'),
      'I heard you say: play some music',
    );
  });

  test('refuses to open unknown apps', () async {
    expect(
      await handler.handle('open the moon'),
      contains("don't know how to open"),
    );
  });
}
