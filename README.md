# Vocax

A multilingual AI voice assistant for everyday life. *Your voice. Your world.*

Built with Flutter. Listens in English, Amharic, Afaan Oromoo, French or Spanish (when the language is installed in the phone's speech service) and answers by voice. Spoken replies are still English only.

## Features

- Side menu: language, dark mode switch, voice commands list, About.
- Select Language screen (English, Amharic, Afaan Oromoo, Français, Español) and a quick dropdown in the top bar, remembered between launches.
- Light and dark theme, toggled from the top bar or the menu, remembered between launches.
- Vocax app icon (adaptive icon on Android) in `android/app/src/main/res`.
- Voice control of the phone: open any installed app, call and text contacts, search Google/YouTube, navigate, alarms, timers, flashlight, volume, music, settings, battery, time.

## Project structure

```
Vocax/
├── .github/workflows/flutter-build.yml   CI: icon, analyze, test, build the APK
├── android/                              icons + native Kotlin (MainActivity.kt)
├── assets/
│   ├── images/logo.png                   wave logo used in the app
│   └── icons/                            app icon + adaptive icon foreground
├── lib/
│   ├── main.dart                         entry point
│   ├── app.dart                          MaterialApp, light/dark themes
│   ├── theme.dart                        colors, gradient, background
│   ├── screens/
│   │   ├── welcome_screen.dart           "Get Started" screen
│   │   ├── language_screen.dart          Select Language screen
│   │   └── home_screen.dart              top bar + listening / speaking screen
│   ├── services/
│   │   ├── voice_service.dart            speech recognition + text to speech
│   │   ├── command_handler.dart          understands what you say, picks the action
│   │   ├── device_service.dart           bridge to Android (calls, apps, torch, volume...)
│   │   ├── app_launcher.dart             finds installed apps by spoken name
│   │   ├── contact_service.dart          contact lookup
│   │   ├── fuzzy_match.dart              forgiving name matching
│   │   ├── language_service.dart         supported languages
│   │   └── settings_service.dart         saved theme + language
│   ├── models/                           InstalledApp, DeviceContact
│   └── widgets/                          drawer, dialogs, language dropdown, logo...
├── test/
├── pubspec.yaml
└── analysis_options.yaml
```

## Voice commands

| Say | Vocax does |
| --- | --- |
| "Open YouTube", "Open WhatsApp", "Open Camera" | opens any app installed on the phone (spoken name is matched loosely) |
| "Call Mom", "Call 0911223344" | calls the contact or number (asks for permission the first time) |
| "Send a message to Mom saying I am late", "Text Mom see you soon" | opens the message ready to send |
| "Search for weather in Addis Ababa" | Google search |
| "Play Ethiopian music on YouTube" | YouTube search |
| "Navigate to Bole Airport" | directions in Maps |
| "Turn on / off the flashlight" | flashlight |
| "Volume up", "Volume down", "Volume 50", "Mute" | media volume |
| "Pause", "Play", "Next song", "Previous song" | controls the current music app |
| "Set an alarm for 7 30 AM", "Set a timer for 5 minutes" | alarm / timer |
| "Take a photo", "Record a video" | opens the camera |
| "Open Wi-Fi settings" (also Bluetooth, location, display, airplane mode, mobile data) | opens that settings page |
| "What is my battery level", "What time is it", "What is the date" | answers |
| "Hello Vocax", "How are you", "What is your name" | small talk |

The main verbs (open, call, search) also work in French, Spanish, Amharic and Afaan Oromoo. Replies are spoken in English.

### Limits (Android rules)

- Android does not let apps flip Wi-Fi, Bluetooth or airplane mode on or off, so Vocax opens the settings page.
- Text messages open ready to send; you tap Send. This avoids sending a wrongly heard message.
- Controlling other apps' screens ("scroll", "tap like"), taking screenshots or locking the screen needs an Android Accessibility Service, which is a separate feature.

## App icon

The launcher icons are ready-made files in `android/app/src/main/res` (all sizes, plus the adaptive icon). The workflow copies them over the default Flutter icon on every build. The source art is in `assets/icons`.

## Build

Push to `main` (or run the workflow by hand). GitHub Actions builds the APK and uploads it as the `vocax-android-apk` artifact.

To work on a computer: run `flutter create --platforms=android .` once in this folder to generate `android/`, add the permissions and `<queries>` shown in the workflow to `AndroidManifest.xml`, then copy this repo's `android/app/src/main` over the generated one (it holds the icons and `MainActivity.kt`), then `flutter pub get` and `flutter run`.

## Next steps

- Accessibility Service: screenshots, lock screen, tapping and scrolling in other apps.
- Replies and spoken output in Afaan Oromoo, Amharic, French and Spanish.
- Always-listening "Hey Vocax" wake word.
- Smarter answers for open questions (an AI model).
